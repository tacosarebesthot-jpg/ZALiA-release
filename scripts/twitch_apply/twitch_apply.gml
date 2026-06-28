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

	// duration (frames) for timed effects; default 5s @60fps when unspecified/garbage
	var _frames = tw_num(_dur, 0);
	if (_frames <= 0) _frames = 300;

	// numeric amount for stat verbs (defensive: tw_num never throws on a bad string)
	var _amt = tw_num(_arg, 0);

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
		case "heal":  if (instance_exists(f)) adjust_stat( _amt, 0); break;
		case "hurt":  if (instance_exists(f)) adjust_stat(-_amt, 0); break;
		case "mp":    if (instance_exists(f)) adjust_stat(0,  _amt); break;
		case "drain": if (instance_exists(f)) adjust_stat(0, -_amt); break;

		case "1up":
			if (instance_exists(f) && variable_global_exists("pc_lives"))
			{   global.pc_lives = min(global.pc_lives + 1, f.LIVES_MAX);  }
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
			// the real value once on restore.
			if (instance_exists(g))
			{
				set_rm_brightness(0);
				array_push(global.tw_active, {
					frames  : _frames,
					reapply : function() { if (instance_exists(g)) set_rm_brightness(0);   },
					restore : function() { if (instance_exists(g)) update_rm_brightness(); }
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

		case "confuse":
			// FUN: "drunk" controls -- swap LEFT<->RIGHT player input for the duration.
			// Input_update2a mirrors Right/Left held+pressed+released while the flag is
			// set (before the derived bitfields are built). Reversible: clear the flag.
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

				var _names = global.jukebox_names;
				var _q     = string_lower(string(_arg));
				var _hit   = -1;
				for (var _ti = 0; _ti < array_length(_names); _ti++)
				{
					if (_q != "" && string_pos(_q, string_lower(string(_names[_ti]))) > 0)
					{   _hit = _ti; break;  }
				}

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
				global.pc.image_xscale = _sc;
				global.pc.image_yscale = _sc;
				array_push(global.tw_active, {
					frames  : _frames,
					sc      : _sc,
					reapply : function() { if (instance_exists(global.pc)) { global.pc.image_xscale = self.sc; global.pc.image_yscale = self.sc; } },
					restore : function() { if (instance_exists(global.pc)) { global.pc.image_xscale = 1;       global.pc.image_yscale = 1;       } }
				});
			}
			break;

		case "slow":
			// control_MOVE1 = the "slow walk" control bit (PC_init.gml:710). Re-assert
			// each tick (PC rebuilds control during movement); clear the bit on revert.
			if (instance_exists(global.pc))
			{
				var _bit = global.pc.control_MOVE1;
				global.pc.control |= _bit;
				array_push(global.tw_active, {
					frames  : _frames,
					bit     : _bit,
					reapply : function() { if (instance_exists(global.pc)) global.pc.control |=  self.bit;  },
					restore : function() { if (instance_exists(global.pc)) global.pc.control &= ~self.bit;  }
				});
			}
			break;

		case "speed":
			// hspd_max is recomputed during movement, so re-assert the bumped value
			// each tick; restore the prior cap on revert.
			if (instance_exists(global.pc))
			{
				var _prev = global.pc.hspd_max;
				var _fast = _prev * 1.5;
				global.pc.hspd_max = _fast;
				array_push(global.tw_active, {
					frames  : _frames,
					fast    : _fast,
					prev    : _prev,
					reapply : function() { if (instance_exists(global.pc)) global.pc.hspd_max = self.fast; },
					restore : function() { if (instance_exists(global.pc)) global.pc.hspd_max = self.prev; }
				});
			}
			break;

		case "spell":
			// force-select a spell the player already owns; restore the prior pick.
			if (instance_exists(f) && instance_exists(g))
			{
				var _spellbit = tw_spell_bit(string_lower(string(_arg)));
				if (_spellbit != 0 && (f.spells & _spellbit))
				{
					var _prev_spell = g.spell_selected;
					g.spell_selected = _spellbit;
					g.spell_ready    = _spellbit;
					array_push(global.tw_active, {
						frames  : _frames,
						prev    : _prev_spell,
						restore : function() { if (instance_exists(g)) { g.spell_selected = self.prev; g.spell_ready = self.prev; } }
					});
				}
			}
			break;

		case "flame":
		case "heckler":
			// spawn a jumping flame next to the PC, tagged with the chatter's name.
			if (instance_exists(global.pc))
			{
				var _fe = GameObject_create(global.pc.xl + 24, global.pc.yt, Blaze01, 2);
				if (_fe != noone) with (_fe) chatter_name = _who_s;
			}
			break;

		// ---- GAME-MASTER / dungeon-master verbs: chat spawns enemies to harass --------
		case "spawn":
			// spawn ONE normal enemy (named by arg) next to the PC, toward its facing.
			// reuses the flame lever exactly: GameObject_create(x, y, <obj>, <ver=1>).
			if (instance_exists(global.pc))
			{
				var _obj  = tw_spawn_obj(string_lower(string(_arg)));
				var _face = (global.pc.xScale < 0) ? -1 : 1;
				GameObject_create(global.pc.xl + 24 * _face, global.pc.yt, _obj, 1);
			}
			global.tw_toast       = _who_s + " -> spawn " + string(_arg);
			global.tw_toast_timer = 180;
			break;

		case "swarm":
			// spawn a small pack of a single WEAK enemy (Myu) spread around the PC.
			// count via tw_num (default 3), CAPPED at 6 so chat can't flood the room.
			if (instance_exists(global.pc))
			{
				var _n = floor(tw_num(_arg, 3));
				if (_n < 1) _n = 3;
				if (_n > 6) _n = 6;
				for (var _si = 0; _si < _n; _si++)
				{
					// alternate L/R of the PC, widening slightly each step
					var _ox = (((_si & 1) == 0) ? -1 : 1) * (16 + 8 * _si);
					GameObject_create(global.pc.xl + _ox, global.pc.yt, Myu_A, 1);
				}
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
			// HELP: top off BOTH meters at once -- full HP + full MP. adjust_stat clamps each
			// stat to its own get_stat_max(), so a huge positive delta just pins them full.
			if (instance_exists(f)) adjust_stat(9999, 9999);
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
