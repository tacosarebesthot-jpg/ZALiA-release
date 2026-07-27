/// @description  icon_export()
// ============================================================================
// Dump every tracker item icon as a PNG **with the game's palette applied**.
//
// WHY: the sprite files on disk are stored in a BASE palette that the pal-swap
// shader remaps at draw time (see pal_swap_set / global.palette_image). Reading
// sprites\<name>\<guid>.png directly gives the wrong colours -- the sword comes
// out red and yellow, for instance. There is no practical way to reproduce that
// remap outside the engine, so the engine does it: draw each sprite through the
// shader onto a surface, then surface_save().
//
// PALETTE INDEX: global.PI_MOB_ORG, which is what PauseMenu_Create uses for every
// item on the in-game inventory screen (PauseMenu_Create.gml:551, `_PI_ITEM`).
// That screen IS the game's own item art, so matching it is the definition of
// "correct" here.
//
// Output: <working_directory>icon_export\<LABEL>.png
// Run once via the DEV-gated /icons/export route, then the PNGs get inlined into
// the tracker page and this never needs running again unless a sprite changes.
// ============================================================================
function icon_export() {

	var _dir = working_directory + "icon_export\\";
	if (!directory_exists(_dir)) directory_create(_dir);

	// Tracker label -> sprite. Mirrors the ITEMS table in datafiles\web\tracker.html.
	// FLOWER deliberately uses spr_Item_Flower_1a: g_Create registers
	// SPR_ITEM_MEDICINE for ITM_MEDI, but the player is handed a flower in
	// _WestA_5A and the tracker shows the player's word.
	// FAIRY is absent on purpose -- it is an animated strip, not a static icon.
	var _list = [
	    ["CANDLE", spr_Item_Candle],
	    ["GLOVE",  spr_Item_Glove],
	    ["RAFT",   spr_Item_Raft],
	    ["BOOTS",  spr_Item_Boots],
	    ["FLUTE",  spr_Item_Flute],
	    ["CROSS",  spr_Item_Cross],
	    ["HAMMER", spr_Item_Hammer],
	    ["BRACE",  spr_Item_Bracelet_1b],
	    ["MASK",   spr_Item_Mask_1a],
	    ["BOOK",   spr_Item_Book_1b],
	    ["MEAT",   spr_Item_Meat_1a],
	    ["SHIELD", spr_Item_Shield_2a_2],
	    ["RING",   spr_Item_Ring],
	    ["NECKLC", spr_Item_Necklace],
	    ["SWORD",  spr_Item_Sword_1a_3],
	    ["NOTE",   spr_Item_Map],
	    ["MIRROR", spr_Item_Mirror],
	    ["TROPHY", spr_Item_Trophy],
	    ["FLOWER", spr_Item_Flower_1a],
	    ["CHILD",  spr_Item_Child],
	    ["BOTTLE", spr_Item_Bottle_8a],
	    ["SKEY",   spr_Item_Skull_key_1a_1],
	    ["MAP1",   spr_Item_Map_2a],
	    ["MAP2",   spr_Item_Map_2b],

	    // NOT inventory items -- these are the game's own HUD/UI symbols, and they
	    // exist precisely so the tracker does not have to invent its own. The heart
	    // and magic pips were CSS clip-path shapes I drew, and the crystals and keys
	    // were plain boxes; all four were "close enough" rather than the real thing.
	    ["_HEART",   spr_HUD_life_container],
	    ["_MAGIC",   spr_HUD_magic_container],
	    ["_CRYSTAL", spr_Crystal_icon],
	    ["_KEY",     spr_Key_icon]
	];

	var _n = 0;

	for (var _i = 0; _i < array_length(_list); _i++)
	{
	    var _name = _list[_i][0];
	    var _spr  = _list[_i][1];
	    if (!sprite_exists(_spr)) continue;

	    // Items and UI symbols use DIFFERENT palettes. Items draw at PI_MOB_ORG (what
	    // PauseMenu_Create uses for the inventory screen); the HUD/UI sprites draw at
	    // PI_GUI1 (see draw_key_stats.gml:81 drawing spr_Key_icon). Exporting a UI
	    // sprite at the item palette gives the wrong colours -- the same class of
	    // mistake as reading the raw sprite files. Underscore prefix marks UI.
	    var _pi = (string_char_at(_name, 1) == "_") ? global.PI_GUI1 : global.PI_MOB_ORG;

	    var _w = sprite_get_width(_spr);
	    var _h = sprite_get_height(_spr);
	    if (_w <= 0 || _h <= 0) continue;

	    var _surf = surface_create(_w, _h);
	    surface_set_target(_surf);
	    draw_clear_alpha(c_black, 0);

	    // Offset by the sprite's origin so the art lands at 0,0 regardless of how
	    // the origin was set in the editor -- several of these are centre-origin and
	    // would otherwise export half off-surface.
	    draw_sprite_(_spr, 0, sprite_get_xoffset(_spr), sprite_get_yoffset(_spr), _pi);

	    surface_reset_target();
	    surface_save(_surf, _dir + _name + ".png");
	    surface_free(_surf);
	    _n++;
	}

	if (DEV) show_debug_message("[ICONS] exported " + string(_n) + " to " + _dir);
	return _n;

}
