/// @description  jukebox_play()
// ============================================================================
// NES-MUSIC JUKEBOX: play the currently-selected track, looping, through the
// game's existing music path (aud_play_sound). That routine stops all
// audiogroup_mus sounds first, plays on audiogroup_mus, and the audiogroup_mus
// master gain (Audio.mus_vol/10, set in Audio_Create) is what enforces the
// user's music volume -- so playback here automatically respects mus_vol.
//
// We pass loop=true and a JUKEBOX theme string so the normal area-music
// state machine (Audio_update_2) does NOT treat this as a room track and
// fight us for the channel.
//
// Play-safe + fully guarded. Reversible (delete script + yyp/.yy entry).
// ============================================================================
function jukebox_play() {

	// guard: model must be initialised
	if (!variable_global_exists("jukebox_assets")) return;
	if (!variable_global_exists("jukebox_idx"))    return;
	if (!variable_global_exists("jukebox_count"))  return;

	// clamp/wrap index defensively
	var _n = global.jukebox_count;
	if (_n <= 0) return;
	var _i = global.jukebox_idx;
	_i = ((_i mod _n) + _n) mod _n; // safe wrap for negatives too
	global.jukebox_idx = _i;

	var _asset = global.jukebox_assets[_i];
	if (_asset == -1) // asset wasn't imported -- bail quietly, keep whatever is playing
	{
	    if (variable_global_exists("jukebox_msg"))
	    {
	        global.jukebox_msg       = "TRACK MISSING #" + string(_i + 1);
	        global.jukebox_msg_timer = 120;
	    }
	    return;
	}

	// stop our previous jukebox instance explicitly (aud_play_sound also stops
	// the whole music group, but this keeps our own bookkeeping clean).
	if (variable_global_exists("jukebox_inst")
	&&  global.jukebox_inst
	&&  audio_exists(global.jukebox_inst)
	&&  audio_is_playing(global.jukebox_inst))
	{
	    audio_stop_sound(global.jukebox_inst);
	}

	// play looping via the existing music system. Signature:
	//   aud_play_sound(sound, *priority, *loop, *volume, *theme)
	// theme "JUKEBOX" is a sentinel so the room-music logic leaves it alone.
	// PLAY MODE (2026-07-27): only JB_REPEAT loops the instance. ADVANCE and SHUFFLE
	// need the track to actually END so the poll in Surface_Draw_GUI_End can see it
	// stop and pick the next one.
	var _mode = variable_global_exists("jukebox_mode") ? global.jukebox_mode : JB_ADVANCE;
	var _loop = (_mode == JB_REPEAT);

	var _inst = 0;

	// EXTERNAL playlist tracks are runtime streams (audio_create_stream), which belong
	// to NO audiogroup. aud_play_sound() branches on audiogroup membership, so it would
	// treat these as SFX: it would skip the audiogroup_mus stop AND the audiogroup_mus
	// master gain would never apply, leaving the player's music volume slider dead.
	// So play them directly and apply Audio.mus_vol by hand, matching what the master
	// gain does for asset tracks (Audio_Create sets it to mus_vol/10).
	if (variable_global_exists("jukebox_playlist")
	&&  global.jukebox_playlist == JukeboxPL.EXTERNAL)
	{
	    audio_group_stop_all(audiogroup_mus); // silence area music ourselves
	    if (instance_exists(Audio)) Audio.mus_rm_inst = 0;

	    _inst = audio_play_sound(_asset, 100, _loop);
	    if (_inst && instance_exists(Audio))
	    {
	        audio_sound_gain(_inst, Audio.mus_vol / 10, 0);
	    }
	}
	else if (instance_exists(Audio))
	{
	    _inst = aud_play_sound(_asset, -1, _loop, -1, "JUKEBOX");
	}

	global.jukebox_inst = _inst;

	// TELL THE COMPANION WINDOW what is actually playing. Without this the Jukebox
	// window only knows about tracks IT asked for -- press next in game, or let
	// auto-advance move on, and its highlight goes stale. One tiny file, written
	// only on a track change, so it costs nothing per frame.
	var _nf = file_text_open_write("jukebox_now.txt");
	if (_nf != -1)
	{
	    file_text_write_string(_nf, string(_i));
	    file_text_close(_nf);
	}

	if (DEV) show_debug_message("[JUKEBOX] play #" + string(_i + 1) + " (" + audio_get_name(_asset) + ") inst=" + string(_inst));

}
