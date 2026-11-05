// dm542t_rack.scad - printed rack for 4x StepperOnline DM542T V4.0 drivers (6x variant).
// Drivers stand on edge ("side mounting", as the manual recommends), big faces vertical,
// >= 10 mm air gaps. An optional 80 mm 24 V fan on the inside of the left end wall blows
// along the gaps; exhaust through the right end wall and the vented cover. Without the fan
// it works as a chimney: floor slots under every gap, slotted cover on top.
// Mounts on the same 2040 rail as controller_case_6x.scad.
//
// Render:  openscad -o rack_base.stl  -D 'part="base"'  dm542t_rack.scad
//          openscad -o rack_cover.stl -D 'part="cover"' dm542t_rack.scad
//
// SOURCE KEY:
//  [MAN] StepperOnline "DM542T(V4.0) Digital Stepper Drive User Manual", 2.3 Mechanical
//        Specifications, Figure 1 (forum.duet3d.com/assets/uploads/files/1684504031141-dm542t_v4.0.pdf)
//  EST   estimate - measure your drivers.

include <enclosure_lib.scad>

part = "assembly";  // "base" | "cover" | "assembly"

// ================= DRIVER: DM542T V4.0 =================
drv_L     = 118;   // VERIFIED [MAN] overall length incl. mounting flanges
drv_H     = 75.5;  // VERIFIED [MAN] overall height (big face)
drv_T     = 25.5;  // VERIFIED [MAN] overall thickness
// --- side-mount screws: MEASURE AND EDIT if needed ---
drv_pitch = 112;   // VERIFIED [MAN] slot/hole pitch along the length
drv_off   = 4.5;   // VERIFIED [MAN] slot centre from the face that stands on the -Y side.
                   // EST which face that is: if your slots are 4.5 mm from the OTHER face, set drv_off = drv_T - 4.5 (= 21).
//                    (Flat-mount alternative [MAN]: 4x d3.5 holes, 112 x 22.5 pattern, 25.3/47.8 mm from the edge. Not used.)
plug_h    = 10;    // EST height of the pluggable P1/P3 terminals above the top edge
n_drv     = 4;
gap       = 12;    // air gap between drivers and to the side walls (>= 10)

// ================= RACK =================
wall      = 3;
floor_t   = 3;
r_out     = 4;
seat_h    = 6;     // driver rests on two insert bosses this high: air passes underneath
wire_clr  = 30;    // free space above the terminals
fan_size  = 80;    // 80 x 80 x 25 mm 24 V, optional
fan_thk   = 25;
fan_pitch = 71.5;
plenum    = 15;    // fan -> driver ends, spreads the air across all gaps
gap_end   = 12;    // driver ends -> right (exhaust) wall
boss_b    = 9;
boss_h    = 12;
lid_t     = 3;
M16 = 16.5;  M12 = 12.5;
gland_z_above = 20;   // gland centre above the driver top edge

// ---------- derived ----------
X = 2 * wall + fan_thk + plenum + drv_L + gap_end;      // 176
Y = 2 * wall + n_drv * drv_T + (n_drv + 1) * gap;       // 168
drv_top = floor_t + seat_h + drv_H;                     // 84.5
H = ceil(drv_top + plug_h + wire_clr);                  // 125
dx0 = wall + fan_thk + plenum;                          // driver start X
dxc = dx0 + drv_L / 2;
function dy(i) = wall + gap + i * (drv_T + gap);        // driver i, -Y face
gz = drv_top + gland_z_above;                           // 104.5
fan_c = [Y / 2, floor_t + 3 + fan_size / 2];            // fan centre on the left wall (y, z)

lab_below = -19;   // labels under the glands (lid lip is above them)
features = [
    ["F", dxc - 45, gz, M16, "MOT X", lab_below],
    ["F", dxc - 15, gz, M16, "MOT Y", lab_below],
    ["F", dxc + 15, gz, M16, "MOT Z", lab_below],
    ["F", dxc + 45, gz, M16, "MOT A", lab_below],
    // B wall reads right-to-left from outside: 24V OUT, SD A..X, then 24 V in
    ["B", 50,  gz, M12, "SD A", -15],
    ["B", 75,  gz, M12, "SD Z", -15],
    ["B", 100, gz, M12, "SD Y", -15],
    ["B", 125, gz, M12, "SD X", -15],
    ["B", 150, gz, M16, "24V", lab_below],
    ["B", 25,  gz, M16, "OUT", lab_below],   // 24 V out to the 6x case (0.5 m CB16)
];
vents = [ ["R", 16, Y - 16, floor_t + 6, 45], ["R", 16, Y - 16, 49, drv_top] ];   // exhaust wall, 2 rows
bosses = [[wall + boss_b / 2, wall + boss_b / 2], [X - wall - boss_b / 2, wall + boss_b / 2],
          [wall + boss_b / 2, Y - wall - boss_b / 2], [X - wall - boss_b / 2, Y - wall - boss_b / 2]];
tabs = [["F", X / 2], ["B", X / 2]];

assert(X <= 220 && Y + 36 <= 220, "does not fit a 220 x 220 bed");
assert(gap >= 10, "gap must be >= 10 mm");
assert(gz - 12.7 > drv_top + 2, "gland nuts hit the drivers");

module driver_seats() {
    for (i = [0 : n_drv - 1]) {
        y0 = dy(i);
        // two insert bosses under the side-mount slots
        for (s = [-1, 1]) difference() {
            translate([dxc + s * drv_pitch / 2, y0 + drv_off, floor_t - 0.01]) cylinder(d = 9, h = seat_h + 0.01);
            translate([dxc + s * drv_pitch / 2, y0 + drv_off, floor_t + seat_h - INSERT_DEPTH]) cylinder(d = INSERT_HOLE_D, h = 10);
        }
        // low guide rails each side (locate the driver, keep it upright while screwing)
        for (yy = [y0 - 0.4 - 2, y0 + drv_T + 0.4])
            translate([dxc - 35, yy, floor_t - 0.01]) cube([70, 2, seat_h + 8]);
    }
}
module floor_slots() {   // chimney intake under every gap
    for (i = [0 : n_drv]) {
        yc = wall + gap / 2 + i * (drv_T + gap);
        for (seg = [[dx0 + 2, X / 2 - 22], [X / 2 + 22, dx0 + drv_L - 2]])   // solid over the rail
            translate([seg[0], yc - 2, -1]) cube([seg[1] - seg[0], 4, floor_t + 2]);
    }
}
module fan_wall_cut() {   // left wall: grill + 4 screw holes for the inside fan
    intersection() {
        at_wall("L", fan_c[0], fan_c[1], X, Y) translate([0, 0, -wall - 1]) cylinder(d = fan_size - 6, h = wall + 2);
        at_wall("L", fan_c[0], fan_c[1], X, Y) translate([0, 0, -wall]) hex_grid(0, 0, fan_size, 6.5, 1.6, wall);
    }
    for (a = [-1, 1], b = [-1, 1])
        at_wall("L", fan_c[0] + a * fan_pitch / 2, fan_c[1] + b * fan_pitch / 2, X, Y)
            translate([0, 0, -wall - 1]) cylinder(d = 4.4, h = wall + 2);
}

module base() {
    difference() {
        union() {
            box_base(X, Y, H, wall, floor_t, r_out, features, vents, bosses, boss_b, boss_h, [], 0, 0, tabs);
            driver_seats();
        }
        floor_slots();
        fan_wall_cut();
    }
}
// cover: slots over the drivers, solid strip over the plenum (stiffness)
module cover() {
    box_lid(X, Y, wall, r_out, lid_t, bosses, boss_b, [],
            [[dx0, wall + 8, dx0 + drv_L, Y / 2 - 4], [dx0, Y / 2 + 4, dx0 + drv_L, Y - wall - 8]]);
}

if (part == "base") base();
else if (part == "cover") translate([0, 0, lid_t]) rotate([180, 0, 0]) cover();
else {
    color("Orange") render() base();
    for (i = [0 : n_drv - 1])
        color("DimGray") translate([dx0, dy(i), floor_t + seat_h]) cube([drv_L, drv_T, drv_H]);
    for (i = [0 : n_drv - 1])
        color("LimeGreen") translate([dx0 + 8, dy(i) + 4, drv_top]) cube([drv_L - 16, drv_T - 8, plug_h]);
    color("Black", 0.6) translate([wall, Y / 2 - fan_size / 2, floor_t + 3]) cube([fan_thk, fan_size, fan_size]);
    translate([0, 0, H + 40]) color("SteelBlue", 0.6) render() cover();
}
