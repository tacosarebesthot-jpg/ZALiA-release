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
	var _inst = 0;
	if (instance_exists(Audio))
	{
	    _inst = aud_play_sound(_asset, -1, true, -1, "JUKEBOX");
	}
	global.jukebox_inst = _inst;

	if (DEV) show_debug_message("[JUKEBOX] play #" + string(_i + 1) + " (" + audio_get_name(_asset) + ") inst=" + string(_inst));

}
