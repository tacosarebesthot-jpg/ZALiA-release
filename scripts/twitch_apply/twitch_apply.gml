/// @description  twitch_apply(verb, arg, who, dur) -- dispatch a chat command to an EXISTING game lever
/// @param verb  command name (case-insensitive)
/// @param arg   command argument (amount / spell name / music name)
/// @param who   chatter name (for the toast + flame tag)
/// @param dur   duration in frames for timed effects (0/garbage -> default 300)
// ============================================================================
// TWITCH integration -- PHASE A dispatcher.
//
// Every verb drives a lever that already exists in the game. Effects are
// NON-PERSISTENT, REVERSIBLE and RUNTIME-ONLY -- nothing here ever touches the
// save file. Timed effects that don't self-revert push a {frames,restore[,reapply]}
// struct onto global.tw_active; twitch_tick() counts them down, re-asserts
// reapply-type effects each frame, and runs restore() on expiry.
//
// Whole thing is GATED on global.tw_enabled (defaults false in g_Create) so a
// stray drop file can never do anything until the system is explicitly enabled.
//
// Adding a verb = add one case below. That is the whole extension surface.
// Reversible (delete the 3 twitch_* scripts + their .yyp entries + the wiring).
// ============================================================================
function twitch_apply(_verb, _arg, _who, _dur) {

	// Master gate: OFF by default. Ignore everything unless explicitly enabled.
	if (!variable_global_exists("tw_enabled") || !global.tw_enabled) return;

	var _v     = string_lower(string(_verb));
	var _who_s = string(_who);
	if (_who_s == "") _who_s = "chat";

	// ---- VS CHAT MODE (2026-07-27) -----------------------------------------
	// Chat's goal is to kill the runner. Blocks every verb that HELPS -- healing,
	// mana, extra lives, shields, invulnerability, the summonable allies -- so
	// nobody can undo the damage their chat is doing.
	//
	// Deliberately a DENY list, not an allow list: there are ~50 verbs and more
	// get added, and a new hostile verb should work in vs mode the day it lands.
	// The failure mode of a missed entry is "one helpful verb slips through",
	// not "every new effect is silently dead".
	if (variable_global_exists("tw_vs_mode") && global.tw_vs_mode)
	{
	    switch (_v)
	    {
	        case "heal": case "mp": case "refill": case "1up": case "life":
	        case "fairy": case "fary": case "invuln": case "protect": case "prtc":
	        case "shield": case "reflect": case "rflc": case "arise":
	        case "cucco": case "cuco": case "chicken":
	            global.tw_toast       = _who_s + " -> " + _v + " BLOCKED (VS CHAT)";
	            global.tw_toast_timer = 180;
	            return;
	    }
	}

	// Bare spell names chat expects as verbs: StreamElements advertises
	// !protect !shield !reflect in its !cmds list, but only "!spell protect"
	// existed -- the bare forms fell through to "unknown" (dead advertised
	// commands, 2026-08-14/08-28 streams). Translate them into the spell case.
	// (The VS-mode deny list above already blocks these as helpful verbs.)
	if (_v == "protect" || _v == "prtc" || _v == "shield"
	||  _v == "reflect" || _v == "rflc")
	{
		_arg = _v;
		_v   = "spell";
	}

	// Duration (FRAMES) for timed effects. An explicit dur from the drop-file/bot
	// API still wins; when it is absent -- which is EVERY plain chat "!confuse" --
	// fall back to the owner's EFFECT LENGTH setting instead of a hardcoded 5s.
	//
	// This was the gap behind Lane's 2026-07-11 note: "some of the effects like
	// !confuse and !party didn't last long enough to do much to me". The options
	// menu let you set 5-60s, twitch_config.txt stored it, OptionsMenu_Twitch_update
	// even claimed "twitch_apply reads global.tw_effect_secs" -- but nothing here
	// ever read it, so the slider did nothing and every effect was always 5s.
	// (twitch_irc_handle_line ALSO used to hardcode a 300-frame dur, which kept
	// the IRC path pinned at 5s even after this read existed -- fixed there.)
	var _frames = tw_num(_dur, 0);
	if (_frames <= 0)
	{
	    var _secs = variable_global_exists("tw_effect_secs") ? global.tw_effect_secs : 5;
	    if (_secs <= 0) _secs = 5;
	    _frames = _secs * game_get_speed(gamespeed_fps);
	}

	// "!verb N" -> N SECONDS explicit duration on the pure timed verbs (Lane,
	// 2026-08-14: "only speed has that ability"). Parsed once here; verbs whose
	// arg means something else (spawn/swarm counts, music titles, spell names)
	// never read _arg_frames, so they are unaffected. Capped at 60s like speed.
	var _arg_secs   = tw_num(_arg, 0);
	if (_arg_secs > 60) _arg_secs = 60;
	var _arg_frames = (_arg_secs > 0) ? floor(_arg_secs * 60) : 0;
	if (_arg_frames > 0) _frames = _arg_frames;

	// numeric amount for stat verbs (defensive: tw_num never throws on a bad string)
	var _amt = tw_num(_arg, 0);

	// 69/420: his chat types these numbers unprompted (real mined quotes:
	// "!speed 69", then "!speed 67" to correct it). A numeric arg landing on
	// one of them gets a small nod on the toast. Nothing else changes.
	var _nice = (_amt == 69 || _amt == 420 || _arg_secs == 69 || _arg_secs == 420);

	// recognized-verb flag: the default/unknown case flips this false so the messenger
	// fairy below only heralds REAL commands, never a typo or stray drop file.
	var _known = true;

	// feedback toast (plain ASCII arrow for default-font glyph safety; the
	// default case overrides it). Timer counted down in twitch_tick().
	global.tw_toast       = _who_s + " -> " + _v;
	global.tw_toast_timer = 180;

	switch (_v)
	{
		// ---- instant stat pokes (self-clamping via adjust_stat -> get_stat_max) ----
		// Bare "!heal"/"!mp" (no number) -> FULL restore of that meter (9999 clamps to
		// get_stat_max, like !refill); "!heal N" adds N. Bare "!hurt"/"!drain" -> a modest
		// 16-pt chip. Previously a bare verb gave _amt=0 -> adjust_stat(0,0) -> no-op.
		case "heal":  if (instance_exists(f)) adjust_stat( (_amt > 0 ? _amt : 9999), 0); break;
		case "hurt":  if (instance_exists(f)) adjust_stat(-(_amt > 0 ? _amt : 16),   0); break;
		case "mp":    if (instance_exists(f)) adjust_stat(0,  (_amt > 0 ? _amt : 9999)); break;
		case "drain": if (instance_exists(f)) adjust_stat(0, -(_amt > 0 ? _amt : 16));   break;

		case "1up":
			if (instance_exists(f) && variable_global_exists("pc_lives"))
			{   global.pc_lives = min(global.pc_lives + 1, f.LIVES_MAX);  }
			// MOD: on-screen confirmation toast — the life COUNT only draws on the pause/death
			// screen, so chat-driven 1ups looked like nothing happened mid-game.
			global.tw_toast       = _who_s + " -> 1UP";
			global.tw_toast_timer = 180;
			break;

		// ---- self-reverting timers (decremented by existing game code) -------------
		case "invuln":
			// update_game_timers.gml:18 ticks iframes_timer down to 0 on its own.
			if (instance_exists(global.pc)) global.pc.iframes_timer = _frames;
			break;

		case "shake":
			// Surface_Step.gml:90 decrements ScreenShake_timer + clears strength on its own.
			if (instance_exists(g))
			{
				g.ScreenShake_timer      = _frames;
				g.ScreenShake_strength_x = 3;
				g.ScreenShake_strength_y = 3;
			}
			break;

		// ---- timed effects that need a revert entry on global.tw_active ------------
		case "dark":
			// update_rm_brightness() recomputes brightness from items/objects every
			// frame, so we re-force 0 each tick while active, then let it recompute
			// the real value once on restore. The tw_dark flag additionally makes
			// update_rm_brightness itself hold 0 (skip candle/object brightening) --
			// update_Pallete_1a runs AFTER twitch_tick in the frame and its recompute
			// otherwise stomped the forced 0 before anything drew, so !dark never
			// visibly darkened anything (Lane's 08-14 stream).
			if (instance_exists(g))
			{
				global.tw_dark = true;
				set_rm_brightness(0);
				array_push(global.tw_active, {
					frames  : _frames,
					reapply : function() { global.tw_dark = true; if (instance_exists(g)) set_rm_brightness(0);   },
					// update_rm_brightness reads bare instance vars (pal_rm_dark_idx) that live on
					// the palette instance `p`; called from this struct method, self == the struct,
					// so it must run in p's scope or it throws "struct.pal_rm_dark_idx not set".
					restore : function() {
						global.tw_dark = false; // cleared BEFORE the recompute so the room returns to natural brightness
						if (instance_exists(g) && instance_exists(p)) with (p) update_rm_brightness();
					}
				});
			}
			break;

		case "flip":
			// FUN: mirror the screen HORIZONTALLY for the duration. Pure draw-time
			// transform -- Surface_Draw_End presents the application surface with a
			// negative x-scale while the flag is set, touching NO game state, so the
			// revert just clears the flag (reapply re-asserts it against overlaps).
			global.tw_flip = true;
			array_push(global.tw_active, {
				frames  : _frames,
				reapply : function() { global.tw_flip = true;  },
				restore : function() { global.tw_flip = false; }
			});
			break;

		case "steal": case "rob": case "thief": case "pickpocket":
			// HOSTILE: chat temporarily TAKES one of your items.
			//
			// Picks from what you ACTUALLY HOLD, so early-game chat cannot steal a
			// candle you never found and produce a no-op that looks broken. Bits are
			// the real, obtainable set -- deliberately not a range, because TABLET,
			// MELODY and FEATHER are registered but never spawn (see the tracker's
			// ITEMS table), and "stealing" one would be invisible and confusing.
			//
			// Restores by OR-ing the bit back rather than reassigning f.items, so
			// anything picked up DURING the theft survives. Two overlapping steals of
			// different items also both restore correctly; two of the SAME item are
			// prevented below, since the second would capture an already-stolen bit
			// and give it back early.
			var _steal_pool = [
			    ITM_CAND, ITM_GLOV, ITM_RAFT, ITM_BOOT, ITM_FLUT, ITM_CROS,
			    ITM_HAMM, ITM_BRAC, ITM_FRY1, ITM_MASK, ITM_BOOK, ITM_MEAT,
			    ITM_SHLD, ITM_RING, ITM_NKLC, ITM_SWRD, ITM_NOTE, ITM_MIRR,
			    ITM_TRPH, ITM_MEDI, ITM_CHLD, ITM_BTL1, ITM_SKEY
			];
			var _held = [];
			for (var _si = 0; _si < array_length(_steal_pool); _si++)
			{
			    var _sb = _steal_pool[_si];
			    // skip anything a still-running steal already took
			    if (!(f.items & _sb)) continue;
			    if (variable_global_exists("tw_stolen") && (global.tw_stolen & _sb)) continue;
			    array_push(_held, _sb);
			}

			if (array_length(_held) == 0)
			{
			    global.tw_toast       = _who_s + " -> NOTHING TO STEAL";
			    global.tw_toast_timer = 180;
			    break;
			}

			if (!variable_global_exists("tw_stolen")) global.tw_stolen = 0;

			var _bit  = _held[irandom(array_length(_held) - 1)];

			// Readable name for the toast. There is NO bit->name key in dm_ITEM, so go
			// bit -> object -> object name -> item TYPE, which is the display word
			// ("_CANDLE"). Checked against g_Create's registration block rather than
			// guessed; a wrong key here would silently read "AN ITEM" forever.
			var _sobj = val(g.dm_ITEM[? hex_str(_bit) + STR_Object], -1);
			var _name = "AN ITEM";
			if (_sobj != -1)
			{
			    var _stype = g.dm_ITEM[? object_get_name(_sobj) + STR_Item + STR_Type];
			    if (!is_undefined(_stype)) _name = _stype;
			}
			if (string_length(_name) > 0 && string_char_at(_name, 1) == "_")
			    _name = string_delete(_name, 1, 1);
			f.items       &= ~_bit;
			global.tw_stolen |= _bit;

			array_push(global.tw_active, {
			    frames  : _frames,
			    bit     : _bit,
			    // No reapply: taking it once is enough, and re-clearing every tick
			    // would fight a legitimate re-pickup during the theft.
			    restore : function() {
			        f.items          |=  self.bit;
			        global.tw_stolen &= ~self.bit;
			    }
			});

			global.tw_toast       = _who_s + " STOLE YOUR " + _name;
			global.tw_toast_timer = 180;
			break;

		case "confuse":
			// FUN: "drunk" controls -- swap LEFT<->RIGHT player input for the duration.
			// Input_update2a mirrors Right/Left held+pressed+released while the flag is
			// set (before the derived bitfields are built). Reversible: clear the flag.
			// Lane (08-14 [4:52:06]): a fixed duration is gameable -- "I can literally
			// hold the other direction and then wait." So a BARE !confuse now rolls
			// 10-30s RNG; an explicit "!confuse N" (or drop-file dur) still sets N.
			if (_arg_frames > 0)           _frames = _arg_frames;        // explicit seconds
			else if (tw_num(_dur, 0) <= 0) _frames = 600 + irandom(1200); // bare -> 10-30s
			global.tw_confuse = true;
			array_push(global.tw_active, {
				frames  : _frames,
				reapply : function() { global.tw_confuse = true;  },
				restore : function() { global.tw_confuse = false; }
			});
			break;

		case "disco":
			// FUN: brief HSV-cycling translucent colour overlay over the view. Draw-time
			// ONLY (Surface_Draw_End) -- deliberately does NOT touch the scene palette
			// (pal_swap_set fights update_scene_palette), so it cannot corrupt palette
			// state; the overlay simply stops drawing once the revert clears the flag.
			global.tw_disco = true;
			array_push(global.tw_active, {
				frames  : _frames,
				reapply : function() { global.tw_disco = true;  },
				restore : function() { global.tw_disco = false; }
			});
			break;

		case "music":
			if (variable_global_exists("jukebox_names") && is_array(global.jukebox_names))
			{
				// rebuild the live playlist (matches the F-toggle path; resets idx to 0)
				if (variable_global_exists("jukebox_count") && global.jukebox_count > 0)
				{   jukebox_build_playlist();  }

				// Match on a normalised form (letters+digits only). The display names come
				// from the asset names, so they carry UNDERSCORES -- a raw substring test
				// meant chat had to type "bloodytears" and "!music bloody tears" never
				// matched anything. Normalising BOTH sides lets chat type it naturally:
				// "bloody tears", "BloodyTears" and "bloodytears" are now equivalent.
				var _names = global.jukebox_names;
				var _q     = tw_slug(_arg);
				var _hit   = -1;
				if (_q != "")
				{
					// exact normalised name wins over a substring hit, so a short track
					// title can still be requested even when it is contained in a longer one
					for (var _ti = 0; _ti < array_length(_names); _ti++)
					{
						if (tw_slug(_names[_ti]) == _q) { _hit = _ti; break; }
					}
					if (_hit < 0)
					{
						for (var _ti = 0; _ti < array_length(_names); _ti++)
						{
							if (string_pos(_q, tw_slug(_names[_ti])) > 0) { _hit = _ti; break; }
						}
					}
				}

				// no arg / "random" / "shuffle" -> pick a random REAL track so Smoken's
				// dead-chat "change the music" actually shuffles SONGS (not a fixed jingle/FX).
				if (_hit < 0 && array_length(_names) > 0
				&& (_q == "" || _q == "random" || _q == "shuffle"))
				{   _hit = irandom(array_length(_names) - 1);  }

				if (_hit >= 0)
				{
					global.jukebox_idx = _hit;
					global.jukebox_on  = true;
					jukebox_play();
					array_push(global.tw_active, {
						frames  : _frames,
						restore : function() {
							// mirror the jukebox toggle-OFF path: stop our track so
							// Audio_update_2 re-plays the normal room music next frame.
							global.jukebox_on = false;
							if (variable_global_exists("jukebox_inst")
							&&  global.jukebox_inst
							&&  audio_exists(global.jukebox_inst)
							&&  audio_is_playing(global.jukebox_inst))
							{   audio_stop_sound(global.jukebox_inst);  }
							global.jukebox_inst = 0;
						}
					});
				}
			}
			break;

		case "shrink":
		case "grow":
			// PC may reset its own scale, so re-assert each tick; restore 1 on revert.
			if (instance_exists(global.pc))
			{
				var _sc = (_v == "grow") ? 1.5 : 0.6;
				global.pc.tw_scale_mul = _sc;
				global.pc.tw_scale_mul = _sc;
				array_push(global.tw_active, {
					frames  : _frames,
					sc      : _sc,
					reapply : function() { if (instance_exists(global.pc)) { global.pc.tw_scale_mul = self.sc; global.pc.tw_scale_mul = self.sc; } },
					restore : function() { if (instance_exists(global.pc)) { global.pc.tw_scale_mul = 1;       global.pc.tw_scale_mul = 1;       } }
				});
			}
			break;

		case "slow":
			// control_MOVE1 = the "slow walk" control bit (PC_init.gml:710). Re-assert
			// each tick (PC rebuilds control during movement); clear the bit on revert.
			//
			// OVERWORLD FIX: control_MOVE1 is inert on the overworld -- Link is driven there
			// by OVERWORLD.move_spd / move_speed, which Overworld_Step RECOMPUTES every step
			// from the tile underfoot (swamp -> MOVE_SPD_2, else MOVE_SPD_1). So the bit alone
			// did nothing outside side-scroll rooms. Force swamp speed in the reapply closure
			// too: because it re-runs each tick it also survives a screen/room change, which is
			// the other half of the reported bug. No restore needed for the overworld half --
			// Overworld_Step writes the correct value again on the next frame by itself.
			if (instance_exists(global.pc))
			{
				var _bit = global.pc.control_MOVE1;
				global.pc.control |= _bit;

				var _ow_slow = function() {
					if (instance_exists(global.OVERWORLD) && instance_exists(g) && g.room_type == "C")
					{
						global.OVERWORLD.move_spd   = global.OVERWORLD.MOVE_SPD_2;
						global.OVERWORLD.move_speed = global.OVERWORLD.move_SPEED2;
					}
				};
				_ow_slow();

				array_push(global.tw_active, {
					frames  : _frames,
					bit     : _bit,
					ow_slow : _ow_slow,
					reapply : function() {
						if (instance_exists(global.pc)) global.pc.control |=  self.bit;
						self.ow_slow();
					},
					restore : function() { if (instance_exists(global.pc)) global.pc.control &= ~self.bit;  }
				});
			}
			break;

		case "speed":
			// hspd_max is recomputed during movement, so re-assert the bumped value
			// each tick; restore the prior cap on revert.
			// DURATION: "!speed N" -> N SECONDS (arg parsed here, x60 -> frames). No/blank/bad
			// arg -> 10s default. Capped at 60s so chat can't lock a permanent buff. This
			// overrides the generic _dur (IRC always passes 300); the drop-folder path can
			// still pass its own dur, but the arg wins when present.
			if (instance_exists(global.pc))
			{
				var _spd_secs   = tw_num(_arg, 0);
				var _spd_frames  = (_spd_secs > 0) ? floor(_spd_secs * 60) : 600; // default 10s
				if (_spd_frames > 3600) _spd_frames = 3600;                       // cap 60s

				// _prev normalized: hspd_max is base*current multiplier (PC_update_1 folds
				// tw_speed_mul in every frame), so a re-fire while !speed is already live
				// must NOT read the already-boosted value or each re-fire compounds 1.5x
				// again (1.5 -> 2.25 -> ...).
				var _prev = global.pc.hspd_max / max(global.pc.tw_speed_mul, 0.1);
				var _fast = _prev * 1.5;
				global.pc.tw_speed_mul = 1.5;
				array_push(global.tw_active, {
					frames  : _spd_frames,
					fast    : _fast,
					prev    : _prev,
					reapply : function() { if (instance_exists(global.pc)) global.pc.hspd_max = self.fast; },
					restore : function() { if (instance_exists(global.pc)) global.pc.tw_speed_mul = 1; }
				});
				global.tw_toast       = _who_s + " -> speed " + string(_spd_frames div 60) + "s";
				global.tw_toast_timer = 180;
			}
			break;

		case "spell":
			// CAST the named spell for real via the game's own cast_spell() lever, so its
			// VISUAL / active effect actually shows (PROTECT shield, REFLECT, FAIRY->cucco,
			// FIRE bolt, THUNDER, ENIGMA, etc.) -- the old version only swapped the queued
			// icon and nothing happened. No ownership gate (chat chaos): casting drives the
			// effect directly. Persistent spells (PROTECT/REFLECT/JUMP/FAIRY) stay in
			// g.spells_active = visible for the duration; we clear that bit on revert UNLESS
			// it was already active (never strip a form/shield the player set). Instant
			// spells self-clear in update_spell_effects, so the revert entry is a harmless
			// no-op for them.
			if (instance_exists(g) && instance_exists(global.pc))
			{
				var _spellbit = tw_spell_bit(string_lower(string(_arg)));
				if (_spellbit != 0)
				{
					var _was_active = (g.spells_active & _spellbit) != 0;
					cast_spell(_spellbit);
					array_push(global.tw_active, {
						frames  : _frames,
						bit     : _spellbit,
						was_act : _was_active,
						restore : function() { if (instance_exists(g) && !self.was_act) g.spells_active &= ~self.bit; }
					});

					// ENIGMA (SPL_SPEL) -- turn mobs into Bots. The stock update_spell_effects
					// loop BREAKS on the first non-reacting entry in go_mgr.dl_gob1, so with a
					// twitch-spawned mob / the herald fairy in the list it can bail before it
					// reaches the real enemies -> "nothing changed". Do it robustly here over
					// ALL on-screen reacting NON-boss enemies (continue, not break), then consume
					// the bit so the stock loop doesn't re-run. Mirrors the stock react_spell
					// switch (1->Bot, 2->Ache, 3->RestoreFairy).
					if (_spellbit == SPL_SPEL)
					{
						g.spells_active &= ~SPL_SPEL;
						with (Enemy)
						{
							if (is_ancestor(object_index, Boss)) continue;
							if (!state) continue;
							if (!variable_instance_exists(id, "react_spell") || !react_spell) continue;
							GO_update_cam_vars();
							if (!ocsHV3(id)) continue;

							timer = 0;
							state = 0;

							var _eo, _ev;
							switch (react_spell)
							{
								case 2:  _eo = Ache01; _ev = 1; break;
								case 3:  _eo = ReFaA;  _ev = 1; break;
								default: _eo = Bot_A;  _ev = 1; break;
							}

							var _eobjver = object_get_name(_eo) + hex_str(_ev);
							var _ePI     = val(g.dm_go_prop[?_eobjver + STR_pal_idx], palidx_def);
							g.go_mgr.uIdxSwap_gob = update_idx;
							with (GameObject_create(xl, yt, _eo, _ev, -1, _ePI))
							{
								if (is_ver(id, Bot_A, 1)) hp = 0;
							}
						}
					}

					global.tw_toast       = _who_s + " -> spell " + string(_arg);
					global.tw_toast_timer = 180;
				}
			}
			break;

		case "flame":
		case "heckler":
			// spawn a jumping flame next to the PC, tagged with the chatter's name.
			// Same hostile-spawn window guard as !spawn/!swarm -- a Blaze loosed during
			// the boss-defeat tally/cutscene can hit the player exactly like a pack can.
			if (!tw_spawn_window_ok(_v, _who_s)) break;
			if (instance_exists(global.pc))
			{
				var _fe = GameObject_create(global.pc.xl + 24, global.pc.yt, Blaze01, 2);
				if (_fe != noone) with (_fe) chatter_name = _who_s;
			}
			break;

		// ---- GAME-MASTER / dungeon-master verbs: chat spawns enemies to harass --------
		case "spawn":
			// spawn N of a NAMED enemy next to the PC, toward its facing. Arg accepts an
			// optional COUNT: "!spawn moblin", "!spawn moblin 3", "!spawn 3 moblin", or
			// "!spawn 3" (count only -> default enemy). Count defaults to 1, capped at 6 so
			// chat can't flood a room. reuses the flame lever: GameObject_create(x,y,obj,1).
			if (!tw_spawn_window_ok(_v, _who_s)) break; // no hostile packs mid-cutscene/tally (see tw_spawn_window_ok)
			if (instance_exists(global.pc))
			{
				// parse name + optional numeric count out of the arg (order-independent)
				var _sp_name  = "";
				var _sp_cnt   = 1;
				var _sp_parts = string_split(string(_arg), " ");
				for (var _pi = 0; _pi < array_length(_sp_parts); _pi++)
				{
					var _tok = tw_trim(_sp_parts[_pi]);
					if (_tok == "") continue;
					if (string_digits(_tok) == _tok) _sp_cnt = floor(tw_num(_tok, 1)); // pure number -> count
					else if (_sp_name == "")         _sp_name = _tok;                  // first word -> name
				}
				if (_sp_cnt < 1) _sp_cnt = 1;
				if (_sp_cnt > 6) _sp_cnt = 6;

				var _obj  = tw_spawn_obj(string_lower(_sp_name));
				var _face = (global.pc.xScale < 0) ? -1 : 1;
				for (var _sc = 0; _sc < _sp_cnt; _sc++)
				{   GameObject_create(global.pc.xl + (24 + 16 * _sc) * _face, global.pc.yt, _obj, 1);  }
				// MOD: brief i-frames so mobs spawned on top of the PC can't hit him before he reacts.
				// NOT frames -- this field only decrements when timer_b wraps (~21 frames, see
				// update_game_timers:18), so 48 was ~16 SECONDS of invulnerability, which is what
				// made !spawn read as a free pass on stream. A real hit grants 4 (~1.4s,
				// PC_take_damage:85); match that.
				global.pc.iframes_timer = max(global.pc.iframes_timer, 4);

				global.tw_toast       = _who_s + " -> spawn " + string(_sp_cnt) + " " + (_sp_name == "" ? "daira" : _sp_name);
				global.tw_toast_timer = 180;
			}
			break;

		case "swarm":
			// spawn a small pack of RANDOM enemies spread around the PC. count via tw_num
			// (default 3), CAPPED at 6 so chat can't flood the room. Each spawn rolls a
			// random type from a land-safe pool (was: all Myu).
			if (!tw_spawn_window_ok(_v, _who_s)) break; // no hostile packs mid-cutscene/tally (see tw_spawn_window_ok)
			if (instance_exists(global.pc))
			{
				var _n = floor(tw_num(_arg, 3));
				if (_n < 1) _n = 3;
				if (_n > 6) _n = 6;
				// land-safe mix (skip Zora, which wants shoreline). all exist w/ ver-1 data.
				var _pool = [DairA, MoblA, GoriA, StalA, Myu_A, Ache01, Atta01];
				for (var _si = 0; _si < _n; _si++)
				{
					// alternate L/R of the PC, widening slightly each step
					var _ox   = (((_si & 1) == 0) ? -1 : 1) * (16 + 8 * _si);
					var _sobj = _pool[irandom(array_length(_pool) - 1)];
					GameObject_create(global.pc.xl + _ox, global.pc.yt, _sobj, 1);
				}
				// MOD: brief i-frames so the pack can't gang-hit the PC the instant it spawns on him.
				// Same timer_b units as the spawn case above -- 4 ticks ~= 1.4s, not 48 (~16s).
				global.pc.iframes_timer = max(global.pc.iframes_timer, 4);
				global.tw_toast       = _who_s + " -> swarm " + string(_n);
				global.tw_toast_timer = 180;
			}
			break;

		// ---- crowd-control verbs: operate DIRECTLY on the live Enemy instances ---------
		// `Enemy` is the GOB parent of every fightable mob (DairA/MoblA/Myu_A/... all have
		// parentObjectId=Enemy), so with(Enemy) walks them all. Boss descends from Enemy
		// too, so every verb here EXCLUDES bosses (is_ancestor(object_index,Boss)) to keep
		// bespoke boss HP/cutscene state safe and the whole thing contained.
		case "freeze":
		case "stun":
			// HELP/FUN: freeze every on-screen NON-BOSS enemy in place for the duration.
			// Enemy AI short-circuits on a nonzero stun_timer (e.g. Daira_update:
			// "if (stun_timer) { GOB_update_2(); exit; }"), and update_EF11 ticks stun_timer
			// down 1/frame -- so we just re-assert a high value each tick (reapply; this also
			// catches enemies spawned mid-freeze) and clear it to 0 on restore. Pure stun:
			// deals NO damage, fully reversible.
			with (Enemy)
			{   if (state == state_NORMAL && !is_ancestor(object_index, Boss)) stun_timer = 30;  }
			array_push(global.tw_active, {
				frames  : _frames,
				reapply : function() {
					with (Enemy)
					{   if (state == state_NORMAL && !is_ancestor(object_index, Boss)) stun_timer = 30;  }
				},
				restore : function() {
					with (Enemy)
					{   if (!is_ancestor(object_index, Boss)) stun_timer = 0;  }
				}
			});
			break;

		case "smite":
		case "clearscreen":
			// HELP: clear the screen -- deal lethal damage to every on-screen NON-BOSS enemy
			// ONCE, through the existing damage_gob() lever (it handles death, kill count,
			// drops, SFX and the explode state for us). argument2=1 marks it a projectile hit
			// so it won't shove the PC around. Instant -> no tw_active entry needed. Guards on
			// global.pc + g because damage_gob() reads both.
			if (instance_exists(global.pc) && instance_exists(g))
			{
				with (Enemy)
				{
					if (state == state_NORMAL && hp > 0 && !is_ancestor(object_index, Boss))
					{   damage_gob(id, 9999, 1);  }
				}
			}
			break;

		case "curse":
			// FUN: a mild, NON-LETHAL HP drain-over-time for the duration. Ticks one HP off
			// roughly once a second via adjust_stat (which clamps to [0,max]), but ONLY while
			// f.hp > 1 -- so it can sap the player but can NEVER kill. No restore: the lost HP
			// is the cost (just like the instant `hurt` verb), and stays in normal bounds.
			if (instance_exists(f))
			{
				array_push(global.tw_active, {
					frames  : _frames,
					tick    : 60,
					reapply : function() {
						self.tick--;
						if (self.tick <= 0)
						{
							self.tick = 60;
							if (instance_exists(f) && f.hp > 1) adjust_stat(-1, 0);
						}
					}
				});
			}
			break;

		case "party":
			// FUN: pure-flair combo -- the disco HSV overlay AND the horizontal screen flip
			// together for the duration. Both are draw-time-ONLY flags (Surface_Draw_End),
			// touch no game/palette state, and are re-asserted each tick + cleared on restore,
			// exactly like the standalone `disco`/`flip` verbs (so nesting is safe).
			global.tw_disco = true;
			global.tw_flip  = true;
			array_push(global.tw_active, {
				frames  : _frames,
				reapply : function() { global.tw_disco = true;  global.tw_flip = true;  },
				restore : function() { global.tw_disco = false; global.tw_flip = false; }
			});
			break;

		case "refill":
		case "fairy":
		case "fary":
			// HELP: top off BOTH meters at once -- full HP + full MP. adjust_stat clamps each
			// stat to its own get_stat_max(), so a huge positive delta just pins them full.
			// !fairy: StreamElements advertises it, but no case existed (dead advertised
			// command) -- a fairy that heals you is the natural reading, and VS mode
			// already blocks it in the deny list above.
			if (instance_exists(f)) adjust_stat(9999, 9999);
			break;

		case "arise":
		case "chicken":
		case "cucco":
			// FUN: turn Link into a CUCCO (chicken) for the duration. The cucco form is
			// driven entirely by (g.mod_PC_CUCCO_1 && g.spells_active & SPL_FARY) -- and
			// PC_update_1 recomputes global.pc.is_cucco from those every frame -- so we
			// just raise the FAIRY spell bit (the game's own transform lever) and clear it
			// on revert. Re-assert each tick so a room change / spell clear can't drop the
			// form early. Gated on mod_PC_CUCCO_1 (default ON); if that mod is off, casting
			// FAIRY makes a normal fairy instead, so we no-op rather than mis-transform.
			if (instance_exists(g) && instance_exists(global.pc) && g.mod_PC_CUCCO_1)
			{
				var _had_fary = (g.spells_active & SPL_FARY) != 0;
				g.spells_active |= SPL_FARY;
				array_push(global.tw_active, {
					frames   : _frames,
					had_fary : _had_fary,
					reapply  : function() { if (instance_exists(g)) g.spells_active |= SPL_FARY; },
					// only clear the bit if the player wasn't already fairy/cucco before us,
					// so we never strip a form the player set themselves.
					restore  : function() { if (instance_exists(g) && !self.had_fary) g.spells_active &= ~SPL_FARY; }
				});
				global.tw_toast       = _who_s + " -> arise (CHICKEN!)";
				global.tw_toast_timer = 180;
			}
			break;

		case "ice":
		case "icefloor":
			// FUN (ported from the Z3 mod's !ice): the floor is ice for the duration --
			// ground friction drops to 1/4 (PC_update_horizontal applies its -1/frame
			// decel only every 4th frame while the flag is set), so momentum carries
			// and you keep sliding after releasing the d-pad. Pure flag, fully
			// reversible, nothing persistent.
			global.tw_ice = true;
			array_push(global.tw_active, {
				frames  : _frames,
				reapply : function() { global.tw_ice = true;  },
				restore : function() { global.tw_ice = false; }
			});
			break;

		case "moon":
			// FUN: quarter gravity for the duration -- big floaty jumps. Zelda 2 is a
			// PLATFORMER, so the gravity verb the Z3 (ALTTP) brainstorm dropped for
			// having nothing to push against lands perfectly here. PC_update_vertical
			// folds the flag into _grav_add -- the same accumulator the OG variable
			// jump (jump-held = lighter gravity) already uses, so the feel is native.
			global.tw_moon = true;
			array_push(global.tw_active, {
				frames  : _frames,
				reapply : function() { global.tw_moon = true;  },
				restore : function() { global.tw_moon = false; }
			});
			break;

		case "root":
			// HOSTILE (Z3-family port): immobilize -- can't walk or jump, but CAN still
			// attack. Flailing at enemies you can't reach is the joke. Uses the game's
			// own pc_lock bits (PC_LOCK_HSPD is the exact bit elevators/cutscenes use),
			// so it is reversible and cannot corrupt state. Re-assert each tick (some
			// systems ASSIGN pc_lock, e.g. the Ganon fight); restore clears only OUR
			// bits so it never un-locks a cutscene mid-hold.
			if (instance_exists(g))
			{
				g.pc_lock |= (PC_LOCK_HSPD | PC_LOCK_JUMP);
				array_push(global.tw_active, {
					frames  : _frames,
					bits    : (PC_LOCK_HSPD | PC_LOCK_JUMP),
					reapply : function() { if (instance_exists(g)) g.pc_lock |= self.bits;  },
					restore : function() { if (instance_exists(g)) g.pc_lock &= ~self.bits; }
				});
			}
			break;

		case "deny":
			// HOSTILE (Z3 port, adapted): temporarily block a control family via the
			// same pc_lock levers. "!deny spell", "!deny jump", "!deny upstab",
			// "!deny downstab", "!deny upthrust", "!deny downthrust", "!deny all"
			// (every control except walking -- !root is the full stop). No arg -> help.
			// Engine truth: the PLAIN forward stab has no lock bit in the OG engine
			// (can't deny it), and boots have no control lock, so unlike the Z3
			// request there is nothing to deny there.
			if (instance_exists(g))
			{
				var _dwhat = tw_slug(_arg);
				var _dbits = 0;
				switch (_dwhat)
				{
					case "spell":                                _dbits = PC_LOCK_SPEL; break;
					case "magic":                                _dbits = PC_LOCK_SPEL; break;
					case "jump":                                 _dbits = PC_LOCK_JUMP; break;
					case "upstab":                               _dbits = PC_LOCK_ATK1; break;
					case "downstab":                             _dbits = PC_LOCK_ATK2; break;
					case "downthrust": case "thrust":            _dbits = PC_LOCK_ATK3; break;
					case "upthrust":                             _dbits = PC_LOCK_ATK4; break;
					case "all":      case "everything":          _dbits = PC_LOCK_JUMP | PC_LOCK_ATK1 | PC_LOCK_ATK2 | PC_LOCK_ATK3 | PC_LOCK_ATK4 | PC_LOCK_SPEL; break;
					default:
						global.tw_toast       = "deny: spell/jump/upstab/downstab/upthrust/downthrust/all";
						global.tw_toast_timer = 300;
						break;
				}
				if (_dbits != 0)
				{
					g.pc_lock |= _dbits;
					array_push(global.tw_active, {
						frames  : _frames,
						bits    : _dbits,
						reapply : function() { if (instance_exists(g)) g.pc_lock |= self.bits;  },
						restore : function() { if (instance_exists(g)) g.pc_lock &= ~self.bits; }
					});
					global.tw_toast       = _who_s + " -> deny " + string(_arg);
					global.tw_toast_timer = 180;
				}
			}
			break;

		default:
			_known                = false;
			global.tw_toast       = "unknown: " + _v;
			global.tw_toast_timer = 180;
			break;
	}

	// ── TWITCH MESSENGER FAIRY (Navi herald) ───────────────────────────────────────
	// A recognized command fired (not the unknown/default case): summon the Navi-blue
	// herald that pops in, hovers while the toast shows, then flies back off-screen.
	// One messenger at a time: if it's already on screen, just RE-ARM its hover (and
	// pull it back in if it was already leaving) so it rides out the new command rather
	// than stacking a second fairy. Gated on tw_enabled (already true past the top gate).
	if (_known && global.tw_enabled)
	{
		// 69/420 nod -- appended after whatever the verb's own toast says.
		if (_nice && global.tw_toast_timer > 0) global.tw_toast += "  (NICE)";
		if (!instance_exists(obj_twitch_fairy))
		{
			// spawn coords are cosmetic -- Create repositions to just off the screen edge.
			if (instance_exists(global.pc)) instance_create(global.pc.x, global.pc.y, obj_twitch_fairy);
			else                            instance_create(0, 0, obj_twitch_fairy);
		}
		else
		{
			with (obj_twitch_fairy)
			{
				hover_timer = 180;                               // re-arm the hover
				if (phase == 2) { phase = 0; phase_timer = 0; }  // was leaving -> come back
			}
		}

		// RARE Navi "HEY LISTEN" easter egg: 1 in 10,000 commands. GUARDED asset lookup
		// so it stays a harmless no-op until the user imports a clip named
		// snd_navi_heylisten -- then it just starts working, no code change needed.
		if (irandom(9999) == 0)
		{
			var _s = asset_get_index("snd_navi_heylisten");
			if (_s != -1 && audio_exists(_s)) aud_play_sound(_s);
		}
	}
}


/// @description  tw_slug(value) -- lowercase, letters+digits only. Used to compare a chat
/// request against a track name without caring about spaces, underscores, case or punctuation.
/// Chat types "Bloody Tears"; the jukebox display name is "CASTLEVANIA2_BLOODYTEARS_BODY".
/// Both slug to a form where a substring test actually does what a human expects.
function tw_slug(_s) {

	var _str = string_lower(string(_s));
	var _out = "";
	var _len = string_length(_str);
	for (var _i = 1; _i <= _len; _i++)
	{
		var _c = string_char_at(_str, _i);
		var _o = ord(_c);
		if ((_o >= 48 && _o <= 57) || (_o >= 97 && _o <= 122)) _out += _c; // 0-9, a-z
	}
	return _out;
}


/// @description  tw_num(value, default) -- parse a number out of a queue field WITHOUT ever throwing.
/// real() raises on a non-numeric string, which would crash the step; this hand-rolls a
/// guaranteed-valid numeric string (optional leading '-', at most one '.') before calling real().
function tw_num(_s, _def) {

	if (is_real(_s)) return _s;

	var _str = string(_s);
	var _out = "";
	var _dot = false;
	var _len = string_length(_str);
	for (var _i = 1; _i <= _len; _i++)
	{
		var _c = string_char_at(_str, _i);
		var _o = ord(_c);
		if      (_o >= 48 && _o <= 57)          { _out += _c;             } // 0-9
		else if (_c == "-" && _out == "")        { _out += _c;             } // minus only as first char
		else if (_c == "." && !_dot)             { _out += _c; _dot = true; } // at most one dot
	}

	if (_out == "" || _out == "-" || _out == "." || _out == "-.") return _def;
	return real(_out);
}


/// @description  tw_spell_bit(name) -- map a spell name to its SPL_* bit (0 if unknown).
function tw_spell_bit(_name) {

	switch (_name)
	{
		case "protect": case "prtc": case "shield": return SPL_PRTC;
		case "jump":                                return SPL_JUMP;
		case "life":    case "heal":                return SPL_LIFE;
		case "fairy":   case "fary":                return SPL_FARY;
		case "fire":                                return SPL_FIRE;
		case "reflect": case "rflc":                return SPL_RFLC;
		case "spell":   case "enigma": case "spel": return SPL_SPEL;
		case "thunder": case "thun":                return SPL_THUN;
		case "summon":  case "summ":                return SPL_SUMM;
		case "cucco":   case "cuco":                return SPL_CUCO;
		default:                                    return 0;
	}
}


/// @description  tw_spawn_obj(name) -- map a GAME-MASTER enemy name to its object index.
/// All of these are normal, fightable enemies that already exist in this project and have
/// valid version-1 ("01") objver property data. Unknown name -> a sensible default (Daira).
function tw_spawn_obj(_name) {

	switch (_name)
	{
		case "daira":   case "dair":               return DairA;   // ground mob
		case "moblin":  case "mobl":  case "mob":  return MoblA;   // walker (spear)
		case "goriya":  case "gori":               return GoriA;   // walker (boomerang)
		case "zora":                               return ZoraA;   // shoreline shooter
		case "stalfos": case "stal":               return StalA;   // sword skeleton
		case "bat":     case "ache":               return Ache01;  // flyer (bat)
		case "atta":                               return Atta01;  // flyer (bat)
		case "myu":                                return Myu_A;   // weak crawler
		default:                                   return DairA;   // sensible default
	}
}


/// @description  tw_spawn_window_ok(verb, who) -- gate for the hostile spawn verbs
/// (!spawn / !swarm). REPRO-WINDOW GUARD for Lane's 2026-08-28 "crashed it on a boss"
/// report: twitch verbs execute from twitch_poll()/twitch_irc_step() near the TOP of
/// g_Step, BEFORE the gui/cutscene gates lower in the frame -- so a pack spawned inside
/// the boss-defeat tally/jar cutscene stayed hostile while the player was locked out of
/// acting, until the segment transition cleared the room ~20s later ("I'm stuck, dude!
/// I can't do regular things now"). Refuse those windows with a visible toast instead.
/// Normal gameplay -- including live boss FIGHTS -- is gui_state NONE with no cutscene
/// or fall transition running, so it is unaffected.
function tw_spawn_window_ok(_v, _who_s) {

	if (instance_exists(g)
	&&  (g.gui_state != g.gui_state_NONE
	||  g.cutscene
	||  g.FallScene_timer))
	{
		global.tw_toast       = _who_s + " -> " + string(_v) + " fizzled (busy)";
		global.tw_toast_timer = 180;
		return false;
	}
	return true;
}
