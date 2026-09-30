/// @description  zalia_file_util -- small file helpers shared by the save, prefs and twitch config code.
//
// Two problems these fix (2026-09-30 review):
//   * json_decode() hands back -1 for a missing / corrupt sub-string, and the loaders
//     stored that -1 straight into f.dm_* / Input.dm_UserInputConfig, so the next ds_map
//     access crashed -- on EVERY boot for prefs, since the file only rewrites on a change.
//   * every writer did open_write (truncate) -> write -> close on the live file, so a crash
//     or power loss mid-write left an empty file and the loader silently gave up on it.

/// @description  json_decode_map(encoded, existing) -- json_decode() for a ds_map slot; ALWAYS returns a live ds_map.
/// Decoded object -> that map (and `existing`, if a live map, is destroyed so a reload never leaks it).
/// Anything else (undefined, 0 from val(), "", corrupt JSON, a JSON array) -> `existing` emptied,
/// or a fresh empty map when `existing` is not a live map.
function json_decode_map(_encoded, _existing = undefined) {
	var _have = (is_real(_existing) && _existing >= 0 && ds_exists(_existing, ds_type_map));
	if (is_string(_encoded) && _encoded != "")
	{
		var _dec = -1;
		try { _dec = json_decode(_encoded); } catch (_e) { _dec = -1; }
		if (is_real(_dec) && _dec >= 0)
		{
			if (ds_exists(_dec, ds_type_map))
			{
				if (_have) ds_map_destroy(_existing);
				return _dec;
			}
			if (ds_exists(_dec, ds_type_list)) ds_list_destroy(_dec); // a JSON array: not what a map slot wants
		}
	}
	if (_have) { ds_map_clear(_existing); return _existing; }
	return ds_map_create();
}

/// @description  file_text_write_atomic(path, text) -- write `text` to `path` without ever leaving it half-written.
/// Writes path + ".tmp" first, then swaps it in (delete old, rename). A crash before the swap
/// leaves the previous file intact; a crash after the delete leaves a COMPLETE .tmp that the
/// loaders promote with file_text_recover_tmp(). Returns true when `path` exists afterwards.
function file_text_write_atomic(_path, _text) {
	var _tmp = _path + ".tmp";
	var _fh = file_text_open_write(_tmp);
	if (_fh == -1) return false;
	file_text_write_string(_fh, string(_text));
	file_text_close(_fh);
	if (!file_exists(_tmp)) return false;
	if (file_exists(_path)) file_delete(_path);
	file_rename(_tmp, _path);
	return file_exists(_path);
}

/// @description  file_text_recover_tmp(path) -- if `path` is missing but a finished path + ".tmp" exists, promote it.
/// Call before file_exists(path) in a loader. Returns true when a recovery happened.
function file_text_recover_tmp(_path) {
	if (file_exists(_path)) return false;
	var _tmp = _path + ".tmp";
	if (!file_exists(_tmp)) return false;
	file_rename(_tmp, _path);
	if (DEV) show_debug_message("[FILE] recovered " + string(_path) + " from its .tmp");
	return file_exists(_path);
}
