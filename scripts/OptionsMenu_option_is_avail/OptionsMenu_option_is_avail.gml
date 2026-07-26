/// @description  OptionsMenu_option_is_avail(menu, option index)
/// @param menu
/// @param  option index
function OptionsMenu_option_is_avail(argument0, argument1) {


	switch(argument0)
	{
	    // ============================================================
	    case menu_state_MAIN:{
	    switch(argument1)
	    {
	        default:                       {return false; break;}
	        case MainOption_SND_VOL:       {return true; break;}
	        case MainOption_MUS_VOL:       {return true; break;}
	        case MainOption_MUSIC_SET:     {return true; break;}
	        case MainOption_PC_SPRITES:    {return true; break;}
	        case MainOption_INPUT_CONFIG:  {return true; break;}
	        case MainOption_CO_OP:         {return true; break;}
	        // DEV TOOLS hidden from players (2026-07-26). Runtime gate, not the DEV
	        // macro: enter the dev code (mirror of the Konami code) to reveal it for
	        // the session, or drop dev_unlock.txt in the save dir to keep it visible.
	        case MainOption_DEV_TOOLS:     {return dev_avail(); break;}
	        case MainOption_TWITCH:        {return true; break;}
	        case MainOption_DISPLAY:       {return true; break;}
	        case MainOption_OTHER:         {return true; break;}
	        case MainOption_RANDO:         {return true; break;}
	        //case MainOption_PAL_EDITOR:    {return true; break;}
	        case MainOption_FORCE_GAMEOVER:{return true; break;}
	        case MainOption_CLOSE:         {return true; break;}
	    }//switch(argument1)
	    break;}//case Menu_MAIN
    
    
    
    
	    // ============================================================
	    // DEV TOOLS is now a LAUNCHER: rows just open sub-folders, all always selectable.
	    case menu_state_DEV_TOOLS:{
	    switch(argument1)
	    {
	        default:                {return false; break;}
	        case DevTools.OVERLAYS: {return true; break;}
	        case DevTools.CHEATS:   {return true; break;}
	        case DevTools.COLOR:    {return true; break;}
	        case DevTools.TEST_CAP: {return true; break;}
	        case DevTools.SWEEPS:   {return true; break;}
	        case DevTools.MISC:     {return true; break;}
	        case DevTools.BACK:     {return true; break;}
	    }//switch(argument1)
	    break;}//case Menu_DEV_TOOLS




	    // ============================================================
	    // DEV TOOLS sub-folder: OVERLAYS (debug overlays). DEV-only diagnostics keep
	    // their original DEV gate; everything else stays available in play builds.
	    case menu_state_OVERLAYS:{
	    switch(argument1)
	    {
	        default:                      {return false; break;}
	        case Overlays.HITBOXES:       {return true; break;}
	        case Overlays.SCP:            {return true; break;}
	        case Overlays.XY:             {return true; break;}
	        case Overlays.OG_CAM:         {return true; break;}
	        case Overlays.HP:             {return true; break;}
	        case Overlays.SPRITE_OUTLINE: {return true; break;}
	        case Overlays.FRAME_COUNT:    {return true; break;}
	        case Overlays.DEPTH_DEBUG:    {return true; break;}
	        case Overlays.DEATH_COUNTER:  {return true; break;}
	        case Overlays.EXITS:          {return dev_avail(); break;}
	        case Overlays.SOLID_TILES:    {return dev_avail(); break;}
	        case Overlays.UNIQUE_TILES:   {return dev_avail(); break;}
	        case Overlays.DUNGEON_MAP:    {return dev_avail(); break;}
	        case Overlays.INPUT_DISPLAY:  {return true; break;}
	        case Overlays.BACK:           {return true; break;}
	    }//switch(argument1)
	    break;}//case menu_state_OVERLAYS




	    // ============================================================
	    // DEV TOOLS sub-folder: CHEATS. ADD_ITEMS keeps its DEV gate; the rest stay
	    // available in play builds (DEV==false).
	    case menu_state_CHEATS:{
	    switch(argument1)
	    {
	        default:                 {return false; break;}
	        case Cheats.ADD_ITEMS:   {return dev_avail(); break;}
	        case Cheats.PC_DASH:     {return true; break;}
	        case Cheats.INF_HP:      {return true; break;}
	        case Cheats.INF_MP:      {return true; break;}
	        case Cheats.INF_LIVES:   {return true; break;}
	        case Cheats.INVULN:      {return true; break;}
	        case Cheats.BACK:        {return true; break;}
	    }//switch(argument1)
	    break;}//case menu_state_CHEATS




	    // ============================================================
	    // DEV TOOLS sub-folder: COLOR (palette editors).
	    case menu_state_COLOR:{
	    switch(argument1)
	    {
	        default:                  {return false; break;}
	        case ClrTools.BGR_COLOR:  {return true; break;}
	        case ClrTools.ROOM_COLOR: {return true; break;}
	        case ClrTools.BACK:       {return true; break;}
	    }//switch(argument1)
	    break;}//case menu_state_COLOR




	    // ============================================================
	    // DEV TOOLS sub-folder: TEST / CAPTURE. BUGPROBE keeps its DEV gate.
	    // TWITCH: player-facing, every row always selectable. COMMANDS is read-only.
	    case menu_state_TWITCH:{
	    switch(argument1)
	    {
	        default:                    {return false; break;}
	        case Twitch.REWARDS:        {return true; break;}
	        case Twitch.CHAT:           {return true; break;}
	        case Twitch.COOLDOWN:       {return true; break;}
	        case Twitch.DURATION:       {return true; break;}
	        case Twitch.COMMANDS:       {return true; break;}
	        case Twitch.SETUP:          {return true; break;}
	        case Twitch.BACK:           {return true; break;}
	    }//switch(argument1)
	    break;}//case menu_state_TWITCH


	    case menu_state_TEST_CAP:{
	    switch(argument1)
	    {
	        default:                    {return false; break;}
	        case TestCap.BUGPROBE:      {return dev_avail();  break;}
	        case TestCap.TAS_RECORD:    {return true; break;}
	        case TestCap.TAS_PLAYBACK:  {return true; break;}
	        case TestCap.PLAYLOG:       {return true; break;}
	        case TestCap.WALKTUNE:      {return true; break;}
	        case TestCap.GP_DIAG:       {return true; break;}
	        case TestCap.COOP_TEST:     {return true; break;}
	        case TestCap.REPLAY_MARK:   {return true; break;}
	        case TestCap.SPAWN_MARK:    {return true; break;}
	        case TestCap.BACK:          {return true; break;}
	    }//switch(argument1)
	    break;}//case menu_state_TEST_CAP




	    // ============================================================
	    // DEV TOOLS sub-folder: SWEEPS (live room-sweep starters, always selectable).
	    case menu_state_SWEEPS:{
	    switch(argument1)
	    {
	        default:                      {return false; break;}
	        case Sweeps.SW_FULL:          {return true; break;}
	        case Sweeps.SW_OVERWORLD:     {return true; break;}
	        case Sweeps.SW_PALACES:       {return true; break;}
	        case Sweeps.SW_TOWNS:         {return true; break;}
	        case Sweeps.SW_CAVES:         {return true; break;}
	        case Sweeps.SW_CAVES_WEST:    {return true; break;}
	        case Sweeps.SW_CAVES_EAST:    {return true; break;}
	        case Sweeps.SW_CAVES_DTHMT:   {return true; break;}
	        case Sweeps.SW_CAVES_MAZIS:   {return true; break;}
	        case Sweeps.SW_OTHER:         {return true; break;}
	        case Sweeps.BACK:             {return true; break;}
	    }//switch(argument1)
	    break;}//case menu_state_SWEEPS




	    // ============================================================
	    // DEV TOOLS sub-folder: MISC.
	    case menu_state_MISC:{
	    switch(argument1)
	    {
	        default:                          {return false; break;}
	        case MiscTools.SET_DEFAULT:       {return true; break;}
	        case MiscTools.APP_PERFORMANCE:   {return true; break;}
	        case MiscTools.DEV_TOOLS_STATE:   {return true; break;}
	        case MiscTools.BACK:              {return true; break;}
	    }//switch(argument1)
	    break;}//case menu_state_MISC




	    // ============================================================




	    // ============================================================
	    case menu_state_DISPLAY:{
	    switch(argument1)
	    {
	        default:             {return false; break;}
	        case Display.FULLSCREEN:  {return true; break;}
	        case Display.WINDOW_SCALE:{return true; break;}
	        case Display.SMOOTH: {return true; break;}
	        case Display.SHARP:  {return true; break;}
	        case Display.PIXEL:  {return true; break;}
	        case Display.FILL:   {return true; break;}
	        case Display.CRT:    {return true; break;}
	        case Display.SCAN:   {return true; break;}
	        case Display.BACK:   {return true; break;}
	    }//switch(argument1)
	    break;}//case menu_state_DISPLAY




	    // ============================================================
	    case menu_state_RANDO:{
	    switch(argument1)
	    {
	        default:                    {return false; break;}
	        case Rando_MARK_ACQUIRED:   {return val(global.dm_save_file_settings[?STR_Randomize+STR_Item+STR_Locations]) || val(global.dm_save_file_settings[?STR_Randomize+STR_PBAG+STR_Locations]) || val(global.dm_save_file_settings[?STR_Randomize+STR_Key +STR_Locations]); break;}
	        case Rando_HINTS:           {return val(global.dm_save_file_settings[?STR_Randomize+STR_Item+STR_Locations]); break;}
	        case Rando_MAPS_SHOW_KEYS:  {return val(global.dm_save_file_settings[?STR_Randomize+STR_Key+STR_Locations]); break;}
	        case Rando_ENEMY_RANDO:     {return val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy+STR_Method]) || val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy+STR_Spawner]) || val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy+STR_ENIGMA]); break;}
	        //case Rando_RANDO_ENEMY:     {return val(global.dm_save_file_settings[?STR_Randomize+STR_Enemy+STR_Method]); break;}
	        case Rando_DUNGEON_TILESETS:{return true; break;}
	        case Rando_OW_BIOMES:       {return ds_map_size(global.OVERWORLD.dm_Rando_TSRC)>0; break;}
	        case Rando_SCENES:          {return true; break;}
	        case Rando_PALETTE:         {return true; break;}
	        case Rando_DUNGEONS_REQUIREMENT:{return global.RandoDungeonRequirement_ADJUST_IN_GAME; break;}
	        case Rando_BACK:            {return true; break;}
	    }//switch(argument1)
	    break;}//case Menu_RANDO_OPTIONS
    
    
    
    
	    // ============================================================
	    case menu_state_OTHER:{
	    switch(argument1)
	    {
	        default:                       {return false; break;}
	        case Other_FLASHING:           {return true;  break;}
	        case Other_DIALOGUE_SPEED:     {return true;  break;}
	        case Other_GAME_FONT:          {return true;  break;}
	        case Other_HIDDEN_OW_EXITS:    {return true;  break;}
	        case Other_HUD:                {return true;  break;}
	        case Other_QUEST_TIMER:        {return true;  break;}
	        case Other_TORCH_LIGHTING:     {return true;  break;}
	        //case Other_RENDER_DELAY:       {return global.RenderFrameDelay_state!=-1; break;}
	        case Other_BLACK_BGR:          {return true;  break;}
	        case Other_SCREEN_SHAKE:       {return true;  break;}
	        case Other_STAB_FRENZY:        {return true;  break;}
	        case Other_ANARKHYA_OW:        {return true;  break;}
	        case Other_HP_BEEP:            {return true;  break;}
	        case Other_HALLOWEEN1:         {return true;  break;}
	        //case Other_CHRISTMAS1:         {return true;  break;} // no content yet
	        //case Other_SHOW_ACTIVE_SPELLS:{return false; break;}
	        //case Other_SCENE_COLORS_EDITOR:{return true;  break;}
	        //case Other_BGR_COLOR_EDITOR:   {return true;  break;}
	        case Other_DOUBLE_JUMP:        {return f.items&ITM_FTHR; break;}
	        case Other_GEE:                {return true;  break;}
	        case Other_BACK:               {return true;  break;}
	    }//switch(argument1)
	    break;}//case menu_state_OTHER
	}//switch(argument0)



	return false;







}
