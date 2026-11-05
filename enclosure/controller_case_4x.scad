// controller_case_4x.scad - printed 24 V controller case for the
// FluidNC 4x CNC Controller v1.1 (Bart Dring; ESP32-WROOM-32UE + 4x TMC2209; sold by Elecrow).
// Bolts to a 2040 T-slot rail (6 mm slot, M5 T-nuts). Print in PETG or ASA.
//
// Render:  openscad -o case4x_base.stl -D 'part="base"' controller_case_4x.scad
//          openscad -o case4x_lid.stl  -D 'part="lid"'  controller_case_4x.scad
// part = "assembly" shows board + fan ghosts (preview only).
//
// SOURCE KEY used in the comments below:
//  [EDA]   bdring's EasyEDA layout "Layout 4x CNC Controller (ESP32 and TMC2209)",
//          doc b15879b582174631a81802742c055b9e, project oshwlab.com/bdring/tmc2130-2-axis_copy_copy_copy_copy_copy
//          (linked from wiki.fluidnc.com 4x page). Read from the PCB JSON: outline,
//          footprint centres, hole sizes. Coordinates here: origin = PCB corner next to
//          the USB-C, X along the motor-terminal edge, Y toward the input terminals, seen from the top.
//  [WIKI]  wiki.fluidnc.com/en/hardware/official/new-page/4x_CNC_with_esp32 (pinout image, photo)
//  [ADA]   Adafruit #4218 "USB C Round Panel Mount Extension Cable": 21.5-27 mm drill
//  EST     estimate - measure your part.

include <enclosure_lib.scad>

part = "assembly";  // "base" | "lid" | "assembly"

// ================= BOARD (all in board coordinates) =================
pcb_x   = 125.0;   // VERIFIED [EDA] outline layer, 125.00 mm
pcb_y   = 85.0;    // VERIFIED [EDA] 85.00 mm
pcb_t   = 1.6;     // EST standard PCB
// --- mounting holes: MEASURE AND EDIT THESE 4 NUMBERS if your board differs ---
hole_x0 = 3.5;     // VERIFIED [EDA] "MOUNTING HOLE 3.5" at (3.5, 3.5)
hole_y0 = 3.5;     // VERIFIED [EDA]
hole_dx = 118.0;   // VERIFIED [EDA] 121.5 - 3.5
hole_dy = 78.0;    // VERIFIED [EDA] 81.5 - 3.5
//                    hole diameter 3.5 mm VERIFIED [EDA] -> M3 screws
comp_h  = 12;      // EST tallest part above the PCB (5.08 mm power terminal TB7). Add ~20 if you fit an I/O module on J3.
under_h = 2.5;     // EST through-hole pin length under the PCB
// connector centres (board coords) - VERIFIED [EDA] footprint centres:
mot_x   = [39.82, 60.68, 81.72, 102.17]; // TB1 (X), TB3 (Y), TB4 (Z), TB5 (A); 4-pin 3.5 mm, y = 4.1, wires enter from the y = 0 edge
inp_x   = [31.1, 48.9];                  // input block 2 (gpio.35/34/39/36 + Gnd), 8-pin 2.54 mm, y = 81.5, wires from the y = 85 edge
pwr_y   = 13.0;    // TB7 VMot/Gnd, 2-pin 5.08 mm at x = 120.5, wires from the x = 125 edge
tb10_y  = 67.25;   // TB10 MOSFETs (gpio.12/VMot/gpio.4/VMot), 4-pin 3.5 mm at x = 121.26
usb_y   = 12.25;   // USB-C at the x = 0 edge
ufl_xy  = [3, 38]; // EST U.FL socket on the WROOM-32UE, scaled from the [WIKI] photo (+-2 mm). The pigtail reaches anyway.

// ================= CASE =================
wall     = 3;      // wall thickness
floor_t  = 3;
r_out    = 4;      // outer corner radius
gap_L    = 35;     // PCB edge -> inner wall, USB side (USB-C plug + bend radius)
gap_R    = 40;     // power/TB10 side: >= 30 mm free + ~8 mm gland nut inside
gap_F    = 40;     // motor-terminal side: >= 30 mm free + gland nut
gap_B    = 40;     // input-terminal side: >= 30 mm free + gland nut
standoff_h = 8;    // floor -> PCB underside (clears under_h, room for an M3 x 5.7 insert)
standoff_d = 8;
fan_size = 80;     // 80 x 80 x 25 mm, 24 V
fan_thk  = 25;
fan_pitch = 71.5;  // standard 80 mm fan hole pitch
fan_gap  = 8;      // fan underside -> tallest component
boss_b   = 9;      // lid-screw boss size
boss_h   = 12;
lid_t    = 3;

// glands / bulkheads (hole diameters)
M16 = 16.5;        // M16 x 1.5 cable gland (4.5-10 mm cable), nut 22 AF
M12 = 12.5;        // M12 x 1.5 gland
USB_D = 22.0;      // [ADA] Adafruit #4218, drill 21.5-27 mm, nut OD 29.5
SMA_D = 6.5;       // SMA bulkhead (1/4-36 UNS), 8 mm AF nut
gland_z = 23;      // gland centre height (nut 22 AF -> 12.7 mm radius clears floor and tab fillet)
lab16 = 14;        // label baseline above an M16 centre (clears the 22 AF hex)
lab12 = 10;

// ---------- derived ----------
X = 2 * wall + gap_L + pcb_x + gap_R;          // 206
Y = 2 * wall + gap_F + pcb_y + gap_B;          // 171
ox = wall + gap_L;                             // PCB origin in case coords
oy = wall + gap_F;
pcb_z = floor_t + standoff_h;
comp_top = pcb_z + pcb_t + comp_h;
H = ceil(comp_top + fan_gap + fan_thk);        // 58: wall height = lid underside
holes = [[hole_x0, hole_y0], [hole_x0 + hole_dx, hole_y0], [hole_x0, hole_y0 + hole_dy], [hole_x0 + hole_dx, hole_y0 + hole_dy]];
standoffs = [for (h = holes) [ox + h[0], oy + h[1]]];

mot_c = ox + (mot_x[0] + mot_x[3]) / 2;        // centre the motor glands on the motor terminals
lim_c = ox + (inp_x[0] + inp_x[1]) / 2;        // and the limit glands on input block 2
features = [
    // wall, s, z, hole, label, label dz
    ["F", mot_c - 48, gland_z, M16, "MOT X", lab16],
    ["F", mot_c - 16, gland_z, M16, "MOT Y", lab16],
    ["F", mot_c + 16, gland_z, M16, "MOT Z", lab16],
    ["F", mot_c + 48, gland_z, M16, "MOT A", lab16],
    // limit inputs left->right on the PCB: gpio.35 (A), 34 (Z), 39 (Y), 36 (X)
    ["B", lim_c - 45, gland_z, M16, "LIM A", lab16],
    ["B", lim_c - 15, gland_z, M16, "LIM Z", lab16],
    ["B", lim_c + 15, gland_z, M16, "LIM Y", lab16],
    ["B", lim_c + 45, gland_z, M16, "LIM X", lab16],
    ["R", oy + pwr_y,  gland_z, M16, "24V", lab16],
    ["R", oy + tb10_y, gland_z, M16, "SIG", lab16],   // SSR control (TB10) + E-stop NC3 (gpio.33)
    ["L", oy + usb_y,  25,      USB_D, "USB", 16],
    ["L", oy + 50,     40,      SMA_D, "ANT", 6.5],
];
vents = [   // exhaust slots, high on the walls (fan blows in through the lid)
    ["L", oy + 62, Y - 15, 28, 50],
    ["R", 18, Y - 18, 44, 52],
    ["B", 18, X / 2 - 8, 44, 52],
    ["B", X / 2 + 8, X - 18, 44, 52],
];
bosses = [[wall + boss_b / 2, wall + boss_b / 2], [X - wall - boss_b / 2, wall + boss_b / 2],
          [wall + boss_b / 2, Y - wall - boss_b / 2], [X - wall - boss_b / 2, Y - wall - boss_b / 2],
          [X / 2, wall + boss_b / 2], [X / 2, Y - wall - boss_b / 2]];
tabs = [["F", X / 2], ["B", X / 2]];
// fan centred over the four TMC2209s (board x 35-105, y 10-25) and the board's driver half
fan = [ox + 72, oy + 27, fan_size, fan_pitch];

// ---------- checks ----------
assert(X <= 220 && Y + 36 <= 220, "does not fit a 220 x 220 bed");
assert(H - fan_thk - comp_top >= fan_gap - 0.01, "fan hits components");
assert(fan[1] - fan_size / 2 > wall + 12, "fan hits front gland nuts");

// ---------- parts ----------
module base() {
    box_base(X, Y, H, wall, floor_t, r_out, features, vents, bosses, boss_b, boss_h,
             standoffs, standoff_h, standoff_d, tabs);
}
module lid() { box_lid(X, Y, wall, r_out, lid_t, bosses, boss_b, fan, []); }

board_parts = [   // [x, y, w, d, h, colour] - ghost only, from [EDA] centres, EST heights
    for (x = mot_x) [x - 7.25, 0.4, 14.5, 7.5, 10, "LimeGreen"],
    [9.1, 78, 17.8, 7, 8.5, "LimeGreen"], [31.1, 78, 17.8, 7, 8.5, "LimeGreen"], [53.1, 78, 17.8, 7, 8.5, "LimeGreen"],
    [75.2, 77, 10.5, 7.4, 10, "LimeGreen"], [86.8, 77, 14, 7.4, 10, "LimeGreen"],
    [116, pwr_y - 5.1, 9, 10.2, 12, "MediumSeaGreen"], [117.5, tb10_y - 7.2, 7.5, 14.4, 10, "LimeGreen"],
    [1.5, 23, 18, 19.2, 3.2, "Silver"], [0, usb_y - 4.5, 7.3, 9, 3.3, "Silver"], [1.5, 49, 14.5, 15, 2, "Silver"],
    for (x = [39.8, 60.7, 81.7, 102.2]) [x + 7, 15, 6.6, 6.6, 8, "Black"],
];

if (part == "base") base();
else if (part == "lid") translate([0, 0, lid_t]) rotate([180, 0, 0]) lid();      // print orientation: top face on the bed
else {
    color("Orange") render() base();
    board_ghost(ox, oy, pcb_z, pcb_x, pcb_y, pcb_t, holes, board_parts);
    translate([0, 0, H + 40]) { color("SteelBlue", 0.6) render() lid(); fan_ghost(fan[0], fan[1], 0, fan_size, fan_thk); }
}
