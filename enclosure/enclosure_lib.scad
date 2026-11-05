// enclosure_lib.scad - shared modules for the hot-wire cutter enclosures.
// Used by controller_case_4x.scad, controller_case_6x.scad and dm542t_rack.scad.
// Units: mm. Coordinates: box outer corner at the origin, X = length, Y = depth,
// Z = up. Walls: "F" (y = 0), "B" (y = Y), "L" (x = 0), "R" (x = X).
// Everything prints without supports: wall holes are truncated teardrops,
// lid-screw bosses hang on 45-degree corbels, slots are narrow and vertical.

$fn = 48;

// ---------- shared hardware dimensions ----------
INSERT_HOLE_D = 4.0;   // M3 x 5.7 brass heat-set insert (OD 4.6): 4.0 mm pilot. Check your insert's datasheet.
INSERT_DEPTH  = 6.5;   // insert length 5.7 + 0.8
M3_CLEAR_D    = 3.4;   // M3 clearance
M5_SLOT_W     = 5.5;   // M5 clearance slot width
LABEL_FONT    = "Liberation Sans:style=Bold"; // bundled with OpenSCAD on Windows/macOS
LABEL_EMBOSS  = 0.6;   // raised text height

// ---------- 2D helpers ----------
module rrect(x, y, r) {            // rounded rectangle, corner at origin
    rr = max(min(r, x / 2 - 0.01, y / 2 - 0.01), 0.01);
    translate([rr, rr]) offset(r = rr) square([x - 2 * rr, y - 2 * rr]);
}

// Teardrop with the point up (+Y), cut flat at 1.15 r: support-free in a
// vertical wall, and the flat top is still hidden by the gland's seal/nut.
module teardrop2d(d) {
    r = d / 2;
    intersection() {
        hull() { circle(r); translate([0, r * sqrt(2)]) square(0.01, center = true); }
        translate([-r - 1, -r - 1]) square([2 * r + 2, r + 1 + 1.15 * r]);
    }
}

// Place children on the OUTER surface of a wall: local X = reading direction
// seen from outside, local Y = up, local Z = outward normal.
// s = position along the wall (X for F/B walls, Y for L/R walls).
module at_wall(w, s, z, X, Y) {
    if (w == "F") translate([s, 0, z]) rotate([90, 0, 0])   children();
    if (w == "B") translate([s, Y, z]) rotate([90, 0, 180]) children();
    if (w == "L") translate([0, s, z]) rotate([90, 0, -90]) children();
    if (w == "R") translate([X, s, z]) rotate([90, 0, 90])  children();
}

// ---------- features ----------
// feature = [wall, s, z, hole_d, "LABEL", label_dz]  (label baseline at z + label_dz)
module feature_holes(features, X, Y, wall) {
    for (f = features)
        at_wall(f[0], f[1], f[2], X, Y)
            translate([0, 0, -wall - 1]) linear_extrude(wall + 2) teardrop2d(f[3]);
}
module feature_labels(features, X, Y, size = 5) {
    for (f = features) if (f[4] != "")
        at_wall(f[0], f[1], f[2] + f[5], X, Y)
            translate([0, 0, -0.01]) linear_extrude(LABEL_EMBOSS + 0.01)
                text(f[4], size = size, font = LABEL_FONT, halign = "center", valign = "bottom");
}

// vent = [wall, s_from, s_to, z_from, z_to]: vertical slots 3 mm wide, 6 mm pitch.
module wall_vents(vents, X, Y, wall, slot_w = 3, pitch = 6) {
    for (v = vents) {
        n = floor((v[2] - v[1] - slot_w) / pitch) + 1;
        s0 = (v[1] + v[2]) / 2 - (n - 1) * pitch / 2;
        for (i = [0 : n - 1])
            at_wall(v[0], s0 + i * pitch, v[3], X, Y)
                translate([-slot_w / 2, 0, -wall - 1]) cube([slot_w, v[4] - v[3], wall + 2]);
    }
}

// Lid-screw boss: b x b column at the top of the wall with an M3 insert hole,
// carried by a 45-degree corbel so it prints without supports.
// boss = [cx, cy]; it hangs from whichever wall(s) it touches.
module lid_boss(c, H, b, boss_h, X, Y, wall) {
    x0 = c[0] - b / 2; y0 = c[1] - b / 2;
    // anchor strip(s) on the touching wall(s), b*1.5 below the boss bottom
    zf = H - boss_h - 1.5 * b;
    difference() {
        hull() {
            translate([x0, y0, H - boss_h]) cube([b, b, boss_h]);
            if (x0 <= wall + 0.01)       translate([wall - 0.01, y0, zf]) cube([0.01, b, 0.01]);
            if (x0 + b >= X - wall - 0.01) translate([X - wall, y0, zf]) cube([0.01, b, 0.01]);
            if (y0 <= wall + 0.01)       translate([x0, wall - 0.01, zf]) cube([b, 0.01, 0.01]);
            if (y0 + b >= Y - wall - 0.01) translate([x0, Y - wall, zf]) cube([b, 0.01, 0.01]);
        }
        translate([c[0], c[1], H - INSERT_DEPTH]) cylinder(d = INSERT_HOLE_D, h = INSERT_DEPTH + 1);
    }
}

// Mounting tab for a 2040 rail (two T-slots 20 mm apart), M5 slots.
// side = "F" or "B"; xc = tab centre along X.
module rail_tab(side, xc, X, Y, tab_w = 40, tab_l = 18, tab_t = 5, pitch = 20, slot_len = 4, wall = 3) {
    sgn = side == "F" ? -1 : 1;
    yw  = side == "F" ? 0 : Y;
    difference() {
        union() {
            // plate
            translate([xc - tab_w / 2, side == "F" ? -tab_l : Y, 0])
                linear_extrude(tab_t) rrect(tab_w, tab_l + 0.01, 3);
            // 45-degree fillet on top of the joint (wall stiffener)
            hull() {
                translate([xc - tab_w / 2, side == "F" ? -0.01 : Y, tab_t]) cube([tab_w, 0.01, 4]);
                translate([xc - tab_w / 2, side == "F" ? -4 : Y + 3.99, tab_t - 0.01]) cube([tab_w, 0.01, 0.01]);
            }
        }
        for (dx = [-pitch / 2, pitch / 2])
            translate([xc + dx, yw + sgn * (tab_l / 2 + 2), -1])
                hull() for (dy = [-slot_len / 2, slot_len / 2])
                    translate([0, dy, 0]) cylinder(d = M5_SLOT_W, h = tab_t + 6);
    }
}

// ---------- the open box ----------
// standoffs = [[x, y], ...] board-hole centres (absolute), standoff_h above floor.
module box_base(X, Y, H, wall, floor_t, r, features, vents, bosses, boss_b, boss_h,
                standoffs, standoff_h, standoff_d, tabs) {
    difference() {
        union() {
            difference() {
                linear_extrude(H) rrect(X, Y, r);
                translate([wall, wall, floor_t]) linear_extrude(H) rrect(X - 2 * wall, Y - 2 * wall, r - wall);
            }
            for (b = bosses) lid_boss(b, H, boss_b, boss_h, X, Y, wall);
            for (s = standoffs)
                translate([s[0], s[1], floor_t - 0.01]) cylinder(d = standoff_d, h = standoff_h + 0.01);
            for (t = tabs) rail_tab(t[0], t[1], X, Y, wall = wall);
            feature_labels(features, X, Y);
        }
        feature_holes(features, X, Y, wall);
        wall_vents(vents, X, Y, wall);
        for (s = standoffs)
            translate([s[0], s[1], floor_t + standoff_h - INSERT_DEPTH]) cylinder(d = INSERT_HOLE_D, h = INSERT_DEPTH + 1);
    }
}

// ---------- lid ----------
// Modelled in assembled orientation (z = 0 is the box rim). Print it upside down.
// fan = [cx, cy, size, hole_pitch] or [] ; slot_fields = [[x0, y0, x1, y1], ...]
module box_lid(X, Y, wall, r, lt, bosses, boss_b, fan, slot_fields, lip_h = 4, lip_w = 2, clr = 0.4,
               fan_hole_d = 4.4) {
    difference() {
        union() {
            linear_extrude(lt) rrect(X, Y, r);
            // locating lip inside the walls, notched around the bosses
            difference() {
                translate([wall + clr, wall + clr, -lip_h]) linear_extrude(lip_h + 0.01)
                    rrect(X - 2 * (wall + clr), Y - 2 * (wall + clr), max(r - wall - clr, 0.5));
                translate([wall + clr + lip_w, wall + clr + lip_w, -lip_h - 1]) linear_extrude(lip_h + 2)
                    rrect(X - 2 * (wall + clr + lip_w), Y - 2 * (wall + clr + lip_w), 0.5);
                for (b = bosses) translate([b[0] - boss_b / 2 - 1, b[1] - boss_b / 2 - 1, -lip_h - 1])
                    cube([boss_b + 2, boss_b + 2, lip_h + 1]);
            }
        }
        for (b = bosses) translate([b[0], b[1], -1]) cylinder(d = M3_CLEAR_D, h = lt + 2);
        if (len(fan) > 0) {
            // hex grill = intake + finger guard
            intersection() {
                translate([fan[0], fan[1], -1]) cylinder(d = fan[2] - 6, h = lt + 2);
                hex_grid(fan[0], fan[1], fan[2], 6.5, 1.6, lt);
            }
            for (dx = [-1, 1], dy = [-1, 1])
                translate([fan[0] + dx * fan[3] / 2, fan[1] + dy * fan[3] / 2, -1]) cylinder(d = fan_hole_d, h = lt + 2);
        }
        for (f = slot_fields) {
            n = floor((f[2] - f[0] - 3) / 6) + 1;
            for (i = [0 : n - 1]) translate([f[0] + i * 6, f[1], -1]) cube([3, f[3] - f[1], lt + 2]);
        }
    }
}

// Hex holes (vertex up in local Y, so the same grid also prints in vertical walls).
module hex_grid(cx, cy, span, hex, rib, t) {
    px = hex + rib; py = (hex + rib) * sqrt(3) / 2;
    n = ceil(span / px) + 1;
    for (i = [-n : n], j = [-n : n])
        translate([cx + i * px + (j % 2) * px / 2, cy + j * py, -1])
            rotate([0, 0, 90]) cylinder(d = hex / cos(30), h = t + 2, $fn = 6);
}

// ---------- preview helpers (not printed) ----------
module fan_ghost(cx, cy, z_top, size, thk) {
    color("DimGray", 0.6) translate([cx - size / 2, cy - size / 2, z_top - thk])
        difference() { cube([size, size, thk]); translate([size / 2, size / 2, -1]) cylinder(d = size - 4, h = thk + 2); }
}
// box = [x, y, w, d, h, "colour"] in board coordinates
module board_ghost(ox, oy, oz, pcb_x, pcb_y, pcb_t, holes, parts) {
    translate([ox, oy, oz]) {
        color("ForestGreen") difference() {
            cube([pcb_x, pcb_y, pcb_t]);
            for (h = holes) translate([h[0], h[1], -1]) cylinder(d = 3.5, h = pcb_t + 2);
        }
        for (p = parts) color(p[5]) translate([p[0], p[1], pcb_t]) cube([p[2], p[3], p[4]]);
    }
}
