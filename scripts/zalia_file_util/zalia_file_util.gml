/// @description  zalia_file_util -- small file helpers shared by the save, prefs and twitch config code.
//
// Two problems these fix (2026-09-30 review):
//   * json_decode() hands back -1 for a missing / corrupt sub-string, and the loaders
//     stored that -1 straight into f.dm_* / Input.dm_UserInputConfig, so the next ds_map
//     access crashed -- on EVERY boot for prefs, since the file only rewrites on a change.
//   * every writer did open_write (truncate) -> write -> close on the live file, so a crash
//     or power loss mid-write left an empty file and the loader silently gave up on it.

/// @description  ds_map_is_live(m) -- true when `m` is a ds_map that exists right now.
/// On this runtime (LTS 2026) a ds id is a `ref` handle: typeof() says "ref" and is_real() is
/// FALSE. The first cut of json_decode_map tested is_real(), so it threw away every good
/// decode and handed back an empty map -- a loaded save lost its keys, locks, quests and
/// explored rooms (caught by a boot probe 2026-10-01, before any save was loaded). Never
/// test a ds id with is_real / >= 0; ask ds_exists. -1 and non-handles are screened first
/// because ds_exists itself rejects undefined and strings.
function ds_map_is_live(_m) {
	if (is_undefined(_m) || is_string(_m) || is_array(_m) || is_struct(_m)) return false;
	if (is_real(_m) && _m < 0) return false;
	return ds_exists(_m, ds_type_map);
}

/// @description  json_decode_map(encoded, existing) -- json_decode() for a ds_map slot; ALWAYS returns a live ds_map.
/// Decoded -> that map (and `existing`, if a live map, is destroyed so a reload never leaks it).
/// Anything else (undefined, 0 from val(), "", a failed decode) -> `existing` emptied, or a
/// fresh empty map when `existing` is not a live map. (Measured on this runtime: json_decode
/// of garbage text does NOT return -1, it returns a live 1-entry map, so garbage lands in the
/// "decoded" branch exactly as it did before this helper existed.)
function json_decode_map(_encoded, _existing = undefined) {
	var _have = ds_map_is_live(_existing);
	if (is_string(_encoded) && _encoded != "")
	{
		var _dec = -1;
		try { _dec = json_decode(_encoded); } catch (_e) { _dec = -1; }
		if (ds_map_is_live(_dec))
		{
			if (_have && _existing != _dec) ds_map_destroy(_existing);
			return _dec;
		}
	}
	if (_have) { ds_map_clear(_existing); return _existing; }
	return ds_map_create();
}

/// @description  file_text_write_atomic(path, text) -- write `text` to `path` without ever leaving it half-written.
/// Writes path + ".tmp" first, then swaps it in (delete old, rename). A crash before the swap
/// leaves the previous file intact; a crash after the delete leaves a COMPLETE .tmp that the
/// loaders promote with file_text_recover_tmp(). Returns true when the NEW text is in `path`.
/// If the swap does not happen (the live file is held open by antivirus / cloud sync, so the
/// delete and the rename both fail) the old file is still there and the new text sits only in
/// the .tmp, which the next write would overwrite: fall back to writing `path` directly, and
/// then READ IT BACK. On this runtime file_text_open_write hands back a good-looking handle for
/// a file it cannot write, and the write and the close report nothing (measured 2026-10-01
/// against a file another process held open: handle 1, text unchanged). The first cut trusted
/// that handle, deleted the .tmp -- the only copy of the new text -- and returned true.
function file_text_write_atomic(_path, _text) {
	var _tmp = _path + ".tmp";
	var _fh = file_text_open_write(_tmp);
	if (_fh == -1) return false;
	file_text_write_string(_fh, string(_text));
	file_text_close(_fh);
	if (!file_exists(_tmp)) return false;
	// The same silence applies to the .tmp itself: an old .tmp that cannot be written would
	// still be there, and swapping it in would put OLDER text in the live file. Swap only a
	// .tmp that reads back as the new text; otherwise leave the live file alone and try the
	// direct write below.
	if (file_text_holds(_tmp, _text))
	{
		if (file_exists(_path)) file_delete(_path);
		file_rename(_tmp, _path);
		if (!file_exists(_tmp)) return file_exists(_path); // swapped
	}

	var _fh2 = file_text_open_write(_path);
	if (_fh2 != -1)
	{
		file_text_write_string(_fh2, string(_text));
		file_text_close(_fh2);
	}
	if (!file_text_holds(_path, _text)) return false; // .tmp is kept: it is the only copy of the new text
	file_delete(_tmp);
	return true;
}

/// @description  file_text_holds(path, text) -- true when the file at `path` reads back as `text` (line breaks ignored).
function file_text_holds(_path, _text) {
	if (!file_exists(_path)) return false;
	var _fh = file_text_open_read(_path);
	if (_fh == -1) return false;
	var _got = "";
	while (!file_text_eof(_fh))
	{
		_got += file_text_read_string(_fh);
		file_text_readln(_fh);
	}
	file_text_close(_fh);
	_got      = string_replace_all(string_replace_all(_got, "\r", ""), "\n", "");
	var _want = string_replace_all(string_replace_all(string(_text), "\r", ""), "\n", "");
	return _got == _want;
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
