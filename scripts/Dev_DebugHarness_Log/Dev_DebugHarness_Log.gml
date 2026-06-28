/// Debug harness — F7 snapshot + live state logging
function Dev_DebugHarness_Log(_label) {
	if (!DEV) exit;

	var _f = file_text_open_append("C:\\temp\\zalia_live_debug.log");
	var _timestamp = "T"+string(current_time);
	var _room_name = room_get_name(room);
	var _room_type = g.room_type;

	file_text_write_string(_f, "\n=== SNAPSHOT: "+_label+" "+_timestamp+" ===\n");
	file_text_write_string(_f, "ROOM: "+_room_name+" ("+_room_type+") hex="+hex_str(g.rm_name)+"\n");
	file_text_write_string(_f, "PC_POS: x="+string(global.pc.x)+" y="+string(global.pc.y)+"\n");
	file_text_write_string(_f, "PC_STATE: state="+string(global.pc.state)+" cs="+hex_str(global.pc.cs)+" vspd="+string(global.pc.vspd)+"\n");
	file_text_write_string(_f, "GAME_STATE: dungeon="+string(g.dungeon_num)+" quest="+string(f.quest_num)+" death_count="+string(f.death_count)+"\n");
	file_text_write_string(_f, "OW_TILES: ow_exists="+string(instance_exists(global.OVERWORLD))+" tile_layers=");

	var _layers = layer_get_all();
	for (var _i = 0; _i < array_length(_layers); _i++) {
		var _lname = layer_get_name(_layers[_i]);
		if (string_pos("tile", _lname) || string_pos("OW", _lname)) {
			file_text_write_string(_f, _lname+" ");
		}
	}
	file_text_write_string(_f, "\n");
	file_text_write_string(_f, "INSTANCES: total="+string(instance_count)+"\n");
	file_text_write_string(_f, "=== END SNAPSHOT ===\n");

	file_text_close(_f);
	show_debug_message("SNAPSHOT LOGGED: "+_label);
}

function Dev_DebugHarness_Init() {
	if (!DEV) exit;

	// Create debug HUD surface
	g.debug_hud_enabled = true;
	g.debug_hud_x = 8;
	g.debug_hud_y = 8;
	g.debug_hud_w = 320;
	g.debug_hud_h = 120;
}

function Dev_DebugHarness_Draw() {
	if (!DEV || !g.debug_hud_enabled) exit;

	var _xx = g.debug_hud_x;
	var _yy = g.debug_hud_y;
	var _c = c_white;

	draw_set_alpha(0.7);
	draw_rectangle_color(_xx, _yy, _xx+g.debug_hud_w, _yy+g.debug_hud_h, c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1.0);

	draw_set_color(_c);
	draw_text(_xx+4, _yy+4,   "Room: "+room_get_name(room)+" ("+g.room_type+")");
	draw_text(_xx+4, _yy+16,  "PC: ("+string(global.pc.x)+","+string(global.pc.y)+")");
	draw_text(_xx+4, _yy+28,  "State: "+string(global.pc.state)+" CS:"+hex_str(global.pc.cs));
	draw_text(_xx+4, _yy+40,  "Quest: "+string(f.quest_num)+" Deaths: "+string(f.death_count));
	draw_text(_xx+4, _yy+52,  "OW: "+string(instance_exists(global.OVERWORLD))+" Instances: "+string(instance_count));
	draw_text(_xx+4, _yy+64,  "Dungeon: "+string(g.dungeon_num));
	draw_text(_xx+4, _yy+100, "F7=Snapshot  F8=Toggle HUD");

	draw_set_color(c_white);
}
