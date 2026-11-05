// controller_case_6x.scad - printed 24 V controller case for the
// FluidNC 6x CNC Controller (integrated ESP32; Bart Dring; Elecrow/Tindie), v1.1/v1.2.
// External drivers (4x DM542T) live in dm542t_rack.scad, mounted next to this case.
// Bolts to a 2040 T-slot rail (6 mm slot, M5 T-nuts). Print in PETG or ASA.
//
// Render:  openscad -o case6x_base.stl -D 'part="base"' controller_case_6x.scad
//          openscad -o case6x_lid.stl  -D 'part="lid"'  controller_case_6x.scad
//
// SOURCE KEY:
//  [EDA]   bdring's EasyEDA layout "Layout 6X CNC Controller copy", doc 264e9166190648c196225592c9ae66c8,
//          project oshwlab.com/bdring/6-pack-2-0_copy_copy_copy ("6X CNC Controller ESP32 (integrated ESP32)",
//          linked from wiki.fluidnc.com 6x page). Outline, footprint centres, hole sizes read from the PCB JSON.
//          Board coords: origin = PCB corner next to the USB-C, X along the motor-connector edge, seen from the top.
//  [WIKI]  wiki.fluidnc.com/en/hardware/official/6x_CNC_Controller (pinout image, v1.2 antenna photo)
//  [ADA]   Adafruit #4218 USB C Round Panel Mount Extension Cable: 21.5-27 mm drill
//  EST     estimate - measure your part.
// v1.1 boards use the WROOM-32E (PCB antenna, overhangs the USB-side edge by ~7 mm, no U.FL):
// leave the ANT hole empty or plug it. v1.2 uses the WROOM-32UE with a U.FL socket [WIKI].

include <enclosure_lib.scad>

part = "assembly";  // "base" | "lid" | "assembly"

// ================= BOARD (board coordinates) =================
pcb_x   = 125.0;   // VERIFIED [EDA] 125.00 mm
pcb_y   = 85.0;    // VERIFIED [EDA] 85.00 mm
pcb_t   = 1.6;     // EST
// --- mounting holes: MEASURE AND EDIT THESE 4 NUMBERS if your board differs ---
hole_x0 = 3.5;     // VERIFIED [EDA] "MOUNTING HOLE 3.5" at (3.5, 3.5)
hole_y0 = 3.5;     // VERIFIED [EDA]
hole_dx = 118.0;   // VERIFIED [EDA]
hole_dy = 78.0;    // VERIFIED [EDA]
//                    hole diameter 3.5 mm VERIFIED [EDA]
comp_h  = 12;      // EST tallest part (5.08 mm power terminal). Add ~20 for an I/O module on J3.
under_h = 2.5;     // EST
// connector centres - VERIFIED [EDA]:
mot_x   = [28.29, 43.29, 58.29, 73.29, 88.29, 103.29]; // Motor1..6, 4-pin 3.5 mm (Ena/Stp/Dir/Gnd), y = 3.5, wires from y = 0
inp_x   = [31.1, 48.9];  // input block 2 (io.35/34/39/36 + Gnd), 8-pin 2.54 mm at y = 81.5
pwr_y   = 54.24;   // power 2-pin 5.08 mm at x = 120.74 (VMot/Gnd)
tb5_y   = 67.25;   // MOSFET block (io.12/VMot/io.4/VMot) 4-pin 3.5 mm at x = 121.26
usb_y   = 12.25;   // USB-C at x = 0
n_drv   = 4;       // Motor1..4 used (X, Y, Z, A)

// ================= CASE =================
wall     = 3;
floor_t  = 3;
r_out    = 4;
gap_L    = 35;     // USB side (USB-C plug; v1.1 PCB antenna overhang)
gap_R    = 40;     // power/MOSFET side: >= 30 mm + gland nut
gap_F    = 40;     // motor-signal side: >= 30 mm + gland nut
gap_B    = 40;     // input side: >= 30 mm + gland nut
standoff_h = 8;
standoff_d = 8;
fan_size = 60;     // 60 x 60 x 25 mm, 24 V (the 6x has no drivers on board, so 60 mm is plenty)
fan_thk  = 25;
fan_pitch = 50;    // standard 60 mm fan hole pitch
fan_gap  = 8;
boss_b   = 9;
boss_h   = 12;
lid_t    = 3;

M16 = 16.5;  M12 = 12.5;  USB_D = 22.0;  SMA_D = 6.5;   // see controller_case_4x.scad
gland_z = 23;
lab16 = 14;  lab12 = 10;

// ---------- derived ----------
X = 2 * wall + gap_L + pcb_x + gap_R;          // 206
Y = 2 * wall + gap_F + pcb_y + gap_B;          // 171
ox = wall + gap_L;
oy = wall + gap_F;
pcb_z = floor_t + standoff_h;
comp_top = pcb_z + pcb_t + comp_h;
H = ceil(comp_top + fan_gap + fan_thk);        // 58
holes = [[hole_x0, hole_y0], [hole_x0 + hole_dx, hole_y0], [hole_x0, hole_y0 + hole_dy], [hole_x0 + hole_dx, hole_y0 + hole_dy]];
standoffs = [for (h = holes) [ox + h[0], oy + h[1]]];

drv_c = ox + (mot_x[0] + mot_x[n_drv - 1]) / 2;
lim_c = ox + (inp_x[0] + inp_x[1]) / 2;
drv_pitch = 26;    // M12 nut ~15-17 AF
names = ["X", "Y", "Z", "A", "B", "C"];
features = [
    // step/dir/enable cables to the DM542T rack (Motor1..4 terminals)
    for (i = [0 : n_drv - 1])
        ["F", drv_c + (i - (n_drv - 1) / 2) * drv_pitch, gland_z, M12, str("DRV ", names[i]), lab12],
    ["B", lim_c - 45, gland_z, M16, "LIM A", lab16],
    ["B", lim_c - 15, gland_z, M16, "LIM Z", lab16],
    ["B", lim_c + 15, gland_z, M16, "LIM Y", lab16],
    ["B", lim_c + 45, gland_z, M16, "LIM X", lab16],
    ["R", oy + 40,  gland_z, M16, "24V", lab16],      // to the power terminal at y = 54
    ["R", oy + 76,  gland_z, M16, "SIG", lab16],      // SSR control (MOSFET io.4) + E-stop NC3 (io.39)
    ["L", oy + usb_y, 25,    USB_D, "USB", 16],
    ["L", oy + 50,    40,    SMA_D, "ANT", 6.5],
];
vents = [
    ["L", oy + 62, Y - 15, 28, 50],
    ["R", 18, Y - 18, 44, 52],
    ["B", 18, X / 2 - 8, 44, 52],
    ["B", X / 2 + 8, X - 18, 44, 52],
];
bosses = [[wall + boss_b / 2, wall + boss_b / 2], [X - wall - boss_b / 2, wall + boss_b / 2],
          [wall + boss_b / 2, Y - wall - boss_b / 2], [X - wall - boss_b / 2, Y - wall - boss_b / 2],
          [X / 2, wall + boss_b / 2], [X / 2, Y - wall - boss_b / 2]];
tabs = [["F", X / 2], ["B", X / 2]];
// fan over the 5 V/3.3 V regulator, ESP32 side of the I/O area and the step/dir buffers
fan = [ox + 70, oy + 42, fan_size, fan_pitch];

assert(X <= 220 && Y + 36 <= 220, "does not fit a 220 x 220 bed");
assert(H - fan_thk - comp_top >= fan_gap - 0.01, "fan hits components");

module base() {
    box_base(X, Y, H, wall, floor_t, r_out, features, vents, bosses, boss_b, boss_h,
             standoffs, standoff_h, standoff_d, tabs);
}
module lid() { box_lid(X, Y, wall, r_out, lid_t, bosses, boss_b, fan, []); }

board_parts = [   // ghost only: [EDA] centres, EST heights
    for (x = mot_x) [x - 7.25, 0.4, 14.5, 7.5, 10, "LimeGreen"],
    [9.1, 78, 17.8, 7, 8.5, "LimeGreen"], [31.1, 78, 17.8, 7, 8.5, "LimeGreen"], [53.1, 78, 17.8, 7, 8.5, "LimeGreen"],
    [75.2, 77, 10.5, 7.4, 10, "White"], [86.8, 77, 14, 7.4, 10, "LimeGreen"],
    [116, pwr_y - 5.1, 9, 10.2, 12, "MediumSeaGreen"], [117.5, tb5_y - 7.2, 7.5, 14.4, 10, "LimeGreen"],
    [1.5, 22.5, 18, 19.2, 3.2, "Silver"], [0, usb_y - 4.5, 7.3, 9, 3.3, "Silver"], [3.2, 46, 14.5, 15, 2, "Silver"],
];

if (part == "base") base();
else if (part == "lid") translate([0, 0, lid_t]) rotate([180, 0, 0]) lid();
else {
    color("Orange") render() base();
    board_ghost(ox, oy, pcb_z, pcb_x, pcb_y, pcb_t, holes, board_parts);
    translate([0, 0, H + 40]) { color("SteelBlue", 0.6) render() lid(); fan_ghost(fan[0], fan[1], 0, fan_size, fan_thk); }
}
