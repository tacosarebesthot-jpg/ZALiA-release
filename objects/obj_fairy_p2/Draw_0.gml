/// @description  obj_fairy_p2 :: Draw -- flapping fairy sprite (MVP)

if (!global.coop_enabled) exit; // !!!!! OFF by default -> draw nothing

// Only draw once a SEPARATE 2nd controller has actually JOINED P2: slot assigned
// (not -1) AND distinct from P1's pad. Until then there is no orphan fairy on screen.
// Mirrors the join check the GUI join-prompt uses (Surface_Draw_GUI_End).
if (!instance_exists(Input)
||  Input.gamepad_slot_p2 == -1
||  Input.gamepad_slot_p2 == Input.gamepad_slot) exit;

// Flap between the two fairy frames, same pattern as the fairy-PC draw (PC_udp), but
// tinted GREEN so the co-op P2 fairy is unmistakable next to the rescue/red/dark fairies.
draw_sprite_ext(g.dl_Fairy_SPRITES[| sign(g.counter1 & $4)], 0, x, y, 1, 1, 0, c_lime, 1);
