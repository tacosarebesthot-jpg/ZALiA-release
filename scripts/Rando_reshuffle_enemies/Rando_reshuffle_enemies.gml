/// @description  Rando_reshuffle_enemies() -> "" on success, else the reason it did nothing.
//
// Lane's "enemy reshuffler" (09-11 stream, confirmed in #zalia-playtest 09-12): re-roll
// the enemy randomizer in the middle of a seed. Items, spells, palaces, towns and every
// other rando table stay exactly as the seed made them; only the enemy mapping changes.
//
// The seed's enemy roll lives in f.dm_rando as either
//   method 1 (SPAWNS): <Randomize_Enemy_Spawn><dk>_Spawn_Datakey_Randomized = other dk
//                      <Randomize_Enemy_Spawn><dk>_OBJVER_Randomized        = that dk's objver
//   method 2 (TYPES):  <Randomize_Enemy_Type><objver>_OBJVER_Randomized       = other objver
// Rando_randomize_enemies shuffled within three classes (ground / flying / spawners, the
// g.dl_RandoEnemy_OBJVER1..3 lists) so a flyer never lands in a ground slot. A reshuffle
// keeps that: it groups the existing entries by the ORIGINAL side's class and permutes the
// assigned values inside each group, so the multiset of enemies per class is unchanged and
// every difficulty / omit decision the seed made still holds.
//
// Enemies already on screen are not touched; the next screen uses the new roll. The new
// mapping is written straight into the seed's _Rando_Data.txt, the same slot file_load
// reads, so it survives a restart. A counter in f.dm_rando says how many times it happened.
function Rando_reshuffle_enemies() {
	if (!instance_exists(f) || f.file_num < 1) return "no file loaded";
	if (!val(global.dm_save_file_settings[?STR_Randomize+STR_Item+STR_Locations])
	&&  !val(f.dm_rando[?STR_Randomize+STR_Enemy+STR_Method])) return "this seed has no enemy randomizer";
	var _method = val(f.dm_rando[?STR_Randomize+STR_Enemy+STR_Method]);
	if (_method != 1 && _method != 2) return "this seed has no enemy randomizer";

	// class of an objver: 1 ground, 2 flying, 3 spawner, 0 unknown
	static _class_of = function(_objver) {
		if (is_undefined(_objver) || !is_string(_objver)) return 0;
		if (ds_list_find_index(g.dl_RandoEnemy_OBJVER1, _objver) != -1) return 1;
		if (ds_list_find_index(g.dl_RandoEnemy_OBJVER2, _objver) != -1) return 2;
		if (ds_list_find_index(g.dl_RandoEnemy_OBJVER3, _objver) != -1) return 3;
		return 0;
	};

	var _prefix, _suffix;
	if (_method == 1) { _prefix = STR_Randomize+STR_Enemy+STR_Spawn; _suffix = STR_Spawn+STR_Datakey+STR_Randomized; }
	else              { _prefix = STR_Randomize+STR_Enemy+STR_Type;  _suffix = STR_OBJVER+STR_Randomized; }
	var _plen = string_length(_prefix), _slen = string_length(_suffix);

	// 1. collect (original, assigned) pairs per class -- never write while walking the map
	var _orig = [[], [], [], []];
	var _vals = [[], [], [], []];
	var _k = ds_map_find_first(f.dm_rando);
	while (!is_undefined(_k))
	{
		var _ks = string(_k);
		if (string_length(_ks) > _plen + _slen
		&&  string_copy(_ks, 1, _plen) == _prefix
		&&  string_copy(_ks, string_length(_ks) - _slen + 1, _slen) == _suffix)
		{
			var _mid = string_copy(_ks, _plen + 1, string_length(_ks) - _plen - _slen);
			var _v   = f.dm_rando[? _k];
			var _c   = (_method == 1) ? _class_of(g.dm_spawn[? _mid + STR_OBJVER]) : _class_of(_mid);
			if (_c > 0 && !is_undefined(_v))
			{
				array_push(_orig[_c], _mid);
				array_push(_vals[_c], string(_v));
			}
		}
		_k = ds_map_find_next(f.dm_rando, _k);
	}

	// 2. shuffle the assigned side of each class and write the pairs back
	var _seed  = val(f.dm_rando[?STR_Rando+STR_Seed]);
	var _count = val(f.dm_rando[?STR_Randomize+STR_Enemy+"_Reshuffle"+STR_Count]) + 1;
	random_set_seed(_seed + _count * 7919 + current_time mod 100000); // different every time, never the seed's own roll
	var _changed = 0;
	for (var _c = 1; _c <= 3; _c++)
	{
		var _n = array_length(_orig[_c]);
		if (_n < 2) continue;
		var _shuffled = array_shuffle(_vals[_c]);
		for (var _i = 0; _i < _n; _i++)
		{
			var _o = _orig[_c][_i], _nv = _shuffled[_i];
			if (_method == 1)
			{
				f.dm_rando[? _prefix + _o + _suffix] = _nv;
				var _ov = g.dm_spawn[? _nv + STR_OBJVER];
				if (!is_undefined(_ov)) f.dm_rando[? _prefix + _o + STR_OBJVER + STR_Randomized] = _ov;
			}
			else
			{
				f.dm_rando[? _prefix + _o + _suffix] = _nv;
			}
			_changed++;
		}
	}
	if (_changed == 0) return "nothing to reshuffle";
	f.dm_rando[?STR_Randomize+STR_Enemy+"_Reshuffle"+STR_Count] = _count;

	// 3. persist: the seed's rando data file, same shape file_load reads
	var _quest_key = STR_Quest + hex_str(f.quest_num);
	f.dm_rando_full[? _quest_key + STR_Rando + STR_Data] = json_encode(f.dm_rando);
	var _path = working_directory + f.dl_FILE_NAME_PREFIX[| f.file_num - 1] + STR_Rando + STR_Data + ".txt";
	var _fw = file_text_open_write(_path);
	if (_fw != -1) { file_text_write_string(_fw, json_encode(f.dm_rando_full)); file_text_close(_fw); }
	if (DEV) show_debug_message("[RANDO] enemies reshuffled (#" + string(_count) + ", " + string(_changed) + " entries, method " + string(_method) + ")");
	return "";
}
