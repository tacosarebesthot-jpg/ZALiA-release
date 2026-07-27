/// @description  jukebox_zone_themes(zone)
/// @param zone  0..JB_ZONE_COUNT-1
// ============================================================================
// The SEVEN player-facing zones, and the themes each one fans out to.
//
// This is the owner's own taxonomy: "title screen, overworld, neutral areas
// with no mobs like towns, caves with monsters, levels which would be dungeons,
// boss music, ending credits". It deliberately does NOT expose the 49 internal
// themes -- nobody choosing music wants to pick between _Overworld_ValleyOfDeath
// and _Overworld_Dragmire; they want "overworld".
//
// It mirrors how the NESmix registration already works (Audio_Create ~1470):
// a track is binned into a CATEGORY and fanned across every theme in it, rather
// than pinned to one.
//
// CAVES ride the DUNGEON list on purpose. _Cave01 is a dead theme -- verified
// 2026-07-26, no room ever selects it -- so anything registered there would
// never be heard. Caves already play dungeon music.
// ============================================================================
function jukebox_zone_themes(_zone) {

    switch (_zone)
    {
        case 0: // TITLE / menus
            return [STR_Title, dk_FileSelect, dk_ContinueSave];

        case 1: // OVERWORLD
            return [STR_Overworld+STR_Standard, STR_Overworld+dk_DeathMountain,
                    STR_Overworld+dk_MazeIsland, STR_Overworld+dk_ValleyOfDeath,
                    STR_Overworld+STR_Dragmire,  STR_Overworld+STR_Makarrha];

        case 2: // TOWNS and other safe interiors
            return [STR_Rauru, STR_Ruto, STR_Saria, STR_Mido, STR_Nabooru,
                    STR_Darunia, STR_New_Kasuto, STR_Old_Kasuto, STR_Bulblin,
                    STR_House+"01", STR_Basement+"01"];

        case 3: // DUNGEONS (caves included -- see header)
            return [STR_Dungeon+hex_str(1), STR_Dungeon+hex_str(2), STR_Dungeon+hex_str(3),
                    STR_Dungeon+hex_str(4), STR_Dungeon+hex_str(5), STR_Dungeon+hex_str(6),
                    STR_Dungeon+hex_str(7), STR_Dungeon+hex_str(8)];

        case 4: // BOSSES
            return [STR_Boss+"01", dk_ThunderBird, dk_ShadowBoss+"01", dk_ShadowBoss+"02",
                    STR_Ganon+"1", STR_Ganon+"2", STR_Ganon+"3"];

        case 5: // ENDING
            return [dk_Credits, dk_GameClear];

        case 6: // MINIGAME
            return [dk_Minigame+"01"];
    }

    return [];

}

/// @description  jukebox_zone_name(zone) -- label for logs and the companion
function jukebox_zone_name(_zone) {

    switch (_zone)
    {
        case 0: return "TITLE";
        case 1: return "OVERWORLD";
        case 2: return "TOWN";
        case 3: return "DUNGEON";
        case 4: return "BOSS";
        case 5: return "ENDING";
        case 6: return "MINIGAME";
    }
    return "ZONE" + string(_zone);

}
