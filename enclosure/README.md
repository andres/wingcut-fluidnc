# Printed 24 V enclosures: controller cases and DM542T rack

*2026-11-05. OpenSCAD 2021.01+, fully parametric. Mains, PSUs, SSR and E-stop stay in the **steel power box**. Only 24 V parts go in these printed boxes.*

| File | What | STLs (in `stl/`) | Size W × D × H (mm) |
|---|---|---|---|
| [controller_case_4x.scad](controller_case_4x.scad) | **FluidNC 4x CNC Controller v1.1** (ESP32 + 4× TMC2209) | `case4x_base.stl`, `case4x_lid.stl` | 206 × 171 × 61 (207 deep with tabs) |
| [controller_case_6x.scad](controller_case_6x.scad) | **FluidNC 6x CNC Controller** (integrated ESP32) | `case6x_base.stl`, `case6x_lid.stl` | 206 × 171 × 61 (207 deep with tabs) |
| [dm542t_rack.scad](dm542t_rack.scad) | **4× DM542T V4.0** rack for the 6x build | `rack_base.stl`, `rack_cover.stl` | 176 × 168 × 128 (204 deep with tabs) |
| [enclosure_lib.scad](enclosure_lib.scad) | Shared modules (box, lid, teardrop holes, labels, rail tabs) | — | — |
| [build.sh](build.sh) | Renders all STLs and the PNG previews in `png/` | — | — |

Every part fits a **220 × 220 mm** bed in one piece. No supports are needed. The STLs are already in print orientation, with lids upside down.

Previews: [png/case4x_assembly.png](png/case4x_assembly.png), [png/case6x_assembly.png](png/case6x_assembly.png), [png/rack_assembly.png](png/rack_assembly.png). Each assembly also has a `_back` view, and each printed part has its own PNG.

To change a dimension, edit the parameters at the top of the `.scad` file (every key one has a source comment), then run `bash build.sh`. To render one part: `openscad -o x.stl -D 'part="base"' controller_case_4x.scad`. The `assert`s stop the render if a part outgrows the bed or the fan hits the board.

---

## 1. Board dimensions: VERIFIED vs ESTIMATED

**VERIFIED** for both boards means **read from Bart Dring's own EasyEDA PCB layout files**, which the FluidNC wiki links as the design source. I pulled the PCB JSON (outline layer, footprint centres, drill sizes) from the EasyEDA API:
- 4x: doc `b15879b5…`, project [oshwlab.com/bdring/tmc2130-2-axis_copy_copy_copy_copy_copy](https://oshwlab.com/bdring/tmc2130-2-axis_copy_copy_copy_copy_copy) ("4x CNC Controller (Integrated ESP32 and TMC2209)", updated 2025-06-15).
- 6x: doc `264e9166…`, project [oshwlab.com/bdring/6-pack-2-0_copy_copy_copy](https://oshwlab.com/bdring/6-pack-2-0_copy_copy_copy) ("6X CNC Controller ESP32 (integrated ESP32)").

I checked the orientation and connector order against the wiki pinout images and photos. Board coordinates: origin = the PCB corner next to the USB-C, seen from the top, X along the motor-terminal edge.

> An estimate in earlier drafts (≈170 × 115 mm, scaled from the wiki image) was wrong. **Both boards are 125 × 85 mm.**

| Dimension | 4x v1.1 | 6x | Status |
|---|---|---|---|
| PCB outline | 125.0 × 85.0 | 125.0 × 85.0 | **VERIFIED** (EDA outline layer) |
| Mounting holes | 4× Ø3.5 at (3.5, 3.5), (121.5, 3.5), (3.5, 81.5), (121.5, 81.5) → **118 × 78 pattern** | same | **VERIFIED** (EDA "MOUNTING HOLE 3.5" footprints) |
| PCB thickness | 1.6 | 1.6 | ESTIMATED (standard) |
| Motor terminals | TB1/TB3/TB4/TB5 (X/Y/Z/A), 4-pin 3.5 mm, centres x = 39.8 / 60.7 / 81.7 / 102.2, y = 4.1, wires from the y = 0 edge | Motor1–6 (Ena/Stp/Dir/Gnd), 4-pin 3.5 mm, x = 28.3 … 103.3 (15 mm pitch), y = 3.5 | **VERIFIED** (EDA) |
| Input terminals | 3× 8-pin 2.54 mm at y = 81.5, x = 18.0 / 40.0 / 62.0; then 3-pin 3.5 mm (RS485) x = 78.8 and 5-pin 3.5 mm (0–10 V) x = 93.9 | same positions | **VERIFIED** (EDA) |
| Power terminal | 2-pin 5.08 mm at x = 120.5, **y = 13.0** | 2-pin 5.08 mm at x = 120.7, **y = 54.2** | **VERIFIED** (EDA) |
| MOSFET terminal (TB10 / TB5) | 4-pin 3.5 mm at x = 121.3, y = 67.3 | same | **VERIFIED** (EDA) |
| USB-C | left edge, y = 12.25 | same | **VERIFIED** (EDA) |
| ESP32 module | WROOM-32UE at (10.5, 32.0) | WROOM-32E footprint at (10.5, 31.6); v1.2 fits the 32UE | **VERIFIED** (EDA) |
| U.FL antenna socket | ≈ (3, 38) | ≈ (3, 38) on v1.2; **none on v1.1** (PCB antenna that overhangs the left edge ≈7 mm) | ESTIMATED (±2 mm, scaled from wiki photos; the pigtail reaches anyway) |
| microSD | left edge, y ≈ 49–64 | left edge, y ≈ 46–61 | **VERIFIED** (EDA) |
| Tallest component | ≈12 mm (5.08 mm power terminal) | ≈12 mm | ESTIMATED: the EDA 3D data has no usable heights. Add ≈20 mm if you fit an I/O module on J3 (wiki: 11 mm spacer). |
| Through-hole pins under the PCB | ≈2.5 mm | ≈2.5 mm | ESTIMATED (8 mm standoffs leave plenty of margin) |

**DM542T V4.0** (StepperOnline manual, §2.3 Fig. 1, [PDF](https://forum.duet3d.com/assets/uploads/files/1684504031141-dm542t_v4.0.pdf)):

| Dimension | Value | Status |
|---|---|---|
| Overall L × H × T | 118 × 75.5 × 25.5 | **VERIFIED** (manual) |
| Side-mount slots | pitch 112, centre 4.5 from one big face | **VERIFIED** numbers. **ESTIMATED** which face (see 4.3). |
| Flat-mount holes (not used) | 4× Ø3.5, 112 × 22.5, at 25.3 / 47.8 | **VERIFIED** (manual) |
| Terminal plug height above the top edge | ≈10 | ESTIMATED |
| Mounting orientation | "Side mounting recommended", "mount the drive vertically" | **VERIFIED** (manual §2.3/2.4) |

**Other parts:**

| Part | Value | Status |
|---|---|---|
| USB-C bulkhead **Adafruit #4218** "USB C Round Panel Mount Extension Cable" | Ø22 hole (drill range 21.5–27), nut OD 29.5 | **VERIFIED** ([Adafruit](https://www.adafruit.com/product/4218)) |
| SMA bulkhead | Ø6.5 hole | spec given; standard ¼-36 UNS thread |
| M16 / M12 gland holes | Ø16.5 / Ø12.5, nut 22 / 15–17 AF | ESTIMATED (typical nylon glands; check yours) |
| M3 heat-set insert hole | Ø4.0 × 6.5 deep (for M3 × 5.7, OD 4.6) | ESTIMATED (CNC Kitchen/Ruthex-style; check the datasheet) |
| Fan hole pitch | 80 mm: 71.5; 60 mm: 50 | standard |

**The hole pattern is verified from the design files, and the boards are commercial.** A production lot can still differ: the wiki photo of the 4x is silk-screened "V3.0", while the render says v1.1, with the same layout. So measure before you print (section 4).

---

## 2. Design summary

- **Cases (4x and 6x):**
  - Layout: the board sits on 4 printed standoffs with M3 inserts. There is **40 mm** between the board edge and the inner wall on the motor, input and power sides: **≥30 mm free** for ferrules, plus ≈8 mm for the gland nut. The USB side has 35 mm.
  - Wall assignment:
    - Each gland row faces the terminal row it serves: motor (4x) or step/dir (6x) glands in the **front** wall, limit glands in the **back** wall, 24 V and SIG in the **right** wall.
    - The USB-C bulkhead and SMA are in the **left** wall.
  - Gland pitch is 30–32 mm (M16) or 25–26 mm (M12), which leaves room for a 22 mm spanner.
- **Cooling (cases):**
  - The 4x has an **80 × 80 × 25 mm 24 V fan** under the lid, centred over the four TMC2209s, blowing down. The hex grille in the lid is the intake and the finger guard. Exhaust slots are high in the left, right and back walls.
  - The 6x has a **60 × 60 × 25 mm 24 V fan**, which is enough: the 6x has no drivers on board.
- **Rack:**
  - The 4 drivers stand on edge with **12 mm gaps**. Each sits on two insert bosses 6 mm high (air passes underneath) between low guide rails.
  - Cooling works two ways: an optional **80 mm 24 V fan** inside the left end wall blows along the gaps through a 15 mm plenum, exhausting through the slotted right wall and the slotted cover. Without the fan, the floor slots under every gap and the cover slots make a chimney.
  - Glands are 20 mm above the drivers' top edge: motors in the front wall; step/dir, 24 V in and 24 V "OUT" in the back wall. That leaves ≈40 mm above the terminals for wiring.
- **Mounting:**
  - Each box has **two tabs, front and back, centred, each with 2× M5 slots on a 20 mm pitch**. They match the two T-slots on the 40 mm face of a 2040, with the rail running front-to-back under the box.
  - **The rail is the separate box mounting rail (BOM FR11: a 2040 offcut lying flat, 250 mm for A, 480 mm for B), screwed or clamped to the bench beside the steel power box, outside the wire span. Never mount a box on the machine frame under the wire.** For B, put both boxes on the same rail, one after the other, with ≥40 mm between them for the tabs and the step/dir glands.
- **Labels:** 5 mm text, raised 0.6 mm, above every entry (below them on the rack):
  - 4x: MOT X/Y/Z/A, LIM X/Y/Z/A, 24V, SIG, USB, ANT.
  - 6x: DRV X/Y/Z/A instead of MOT.
  - Rack: MOT X/Y/Z/A, SD X/Y/Z/A (step/dir), 24V.
- **Support-free printing:**
  - Wall holes are teardrops, cut flat at 1.15 r. The point is up, and the gland seal or nut covers the flat.
  - Lid-screw bosses hang on 45° corbels.
  - Slots are 3 mm wide.

---

## 3. Parts list (per box)

### FluidNC 4x case

| Qty | Part | Note |
|---|---|---|
| 10 | **M3 × 5.7 brass heat-set insert** (OD 4.6) | 4 board + 6 lid |
| 4 | M3 × 6 pan/button head | Board → standoff |
| 6 | M3 × 8 pan/button head | Lid |
| 8 | **M16 × 1.5 nylon cable gland, 4.5–10 mm** + locknut | 4 motor (CB1), 4 limit (CB2) |
| 1 | M16 × 1.5 gland, 4.5–10 mm | 24 V in (2 × 1.0 mm² round cable) |
| 1 | **M16 × 1.5 gland, 4.5–10 mm** | SIG: PB-SIG = TRVVP 4×0.5 shielded (≈6.5 mm) to the power box (SSR control + E-stop NC3) |
| 1 | **Adafruit #4218 USB-C round panel-mount extension, 30 cm** | BOM item CC4. Ø22 hole. |
| 1 | U.FL → SMA female bulkhead pigtail + 2.4 GHz antenna | CC6. Ø6.5 hole. |
| 1 | **80 × 80 × 25 mm fan, 24 V** (any 8025 24 V, ≈0.1 A) | Powered from VMot. BOM item VA2. |
| 4 | M4 × 30 + M4 nut (or the fan's self-tapping screws) | Fan → lid |
| 4 | M5 × 10 button head + M5 washer + **M5 T-nut for 6 mm slot** | Tabs → 2040 |

### FluidNC 6x case

Same as the 4x case, with these changes:
- **4× M12 × 1.5 gland (3–6.5 mm)** for the step/dir cables, instead of the 4 motor M16s. That leaves 4 limit + 24 V in + SIG = 6× M16 (4.5–10 mm).
- **60 × 60 × 25 mm 24 V fan** + 4× M4 × 30 + nuts (4.3 mm fan holes; with a 3.5 mm-hole fan use M3 × 30).

### DM542T rack

| Qty | Part | Note |
|---|---|---|
| 12 | M3 × 5.7 heat-set insert | 8 driver (2 per driver) + 4 cover |
| 8 | M3 × 8 pan head + M3 washer | Driver side-mount slots |
| 4 | M3 × 8 | Cover |
| 6 | M16 × 1.5 gland, 4.5–10 mm | 4 motor (CB1), "24V" in (PB-24), "OUT" (24 V to the 6x case, 0.5 m CB16) |
| 4 | M12 × 1.5 gland, 3–6.5 mm | Step/dir from the 6x (4-core shielded, Ena/Stp/Dir/Gnd) |
| 1 | 80 × 80 × 25 mm 24 V fan (optional) + 4× M4 × 30 + nuts | Inside the left end wall |
| 4 | M5 × 10 + washer + M5 T-nut (6 mm slot) | Tabs |

---

## 4. Measure before printing (do this first)

1. **Board holes (4 numbers).** With calipers, measure:
   - the board outline (expect **125 × 85**);
   - the centre of the hole next to the USB-C, from the USB edge and from the motor-terminal edge (expect 3.5 / 3.5);
   - the hole-to-hole distances along X and Y (expect **118 / 78**).

   If anything differs by more than 0.3 mm, edit `hole_x0`, `hole_y0`, `hole_dx`, `hole_dy` (and `pcb_x`/`pcb_y`) at the top of the case file.
2. **Tallest component** (power terminal, or the I/O module if fitted): if it is more than 12 mm, raise `comp_h`. The wall height follows automatically.
3. **Your glands:** thread OD and nut size. Set `M16`/`M12` (hole Ø) so the thread just passes. If the nut is bigger than 22 AF, increase the pitch (the ±48/±16 offsets).
4. **Heat-set inserts:** set `INSERT_HOLE_D` in `enclosure_lib.scad` to your insert's recommended hole size.
5. **DM542T:** measure your driver's side-mount slots:
   - pitch along the length (expect **112**);
   - slot centre to the nearer big face (expect **4.5**).

   The rack puts the slots 4.5 mm from each driver's −Y face. If yours are 4.5 from the other face, either turn the driver round or set `drv_off = 21`. Also measure the terminal plug height (`plug_h`, ≈10).
6. **USB bulkhead:** if you don't use the Adafruit #4218, set `USB_D` to your part's cut-out.
7. Optional: print a 40 × 30 mm strip with one M16 hole first, to check the gland fit on your printer.

---

## 5. Print settings

- **Material:** **PETG** (easy) or **ASA** (better heat and UV; needs an enclosed printer). Not PLA: the box sits near a hot wire and warm drivers.
- **Process:** 0.4 mm nozzle, 0.2 mm layers, **4 perimeters** (makes the 3 mm walls solid), 5 top/bottom layers, 25 % gyroid infill. **No supports.**
- **Bed adhesion:**
  - The cases' footprint with tabs is 206 × 207 mm. Use a skirt of 1 loop at most, or no skirt.
  - For ASA, add a 3 mm brim only on the long sides.
  - The rack is 176 × 204 mm.
- **Orientation:** as exported. Bases open side up; lids and cover with the top face on the bed.
- **Time:** expect ≈10–14 h per case base and ≈15 h for the rack base, depending on the printer.

## 6. Assembly

1. **Inserts:** press the heat-set inserts with a soldering iron at 220–240 °C (PETG). Keep them square and flush.
2. **Glands:**
   - Fit the glands from outside, with the locknut inside. Tighten with a 22 mm (M16) or 15–17 mm (M12) spanner, without excess force on plastic.
   - Fit the USB-C bulkhead (nut inside) and the SMA bulkhead (left wall). Coil the spare 30 cm of USB cable in the 35 mm bay on the USB side, not over the board.
3. **Fan:**
   - Bolt the fan under the lid (4x/6x), label side down, so it blows **into** the box onto the board. On the rack, bolt it inside the left end wall, blowing into the box.
   - Wire the fan to VMot/GND, e.g. the H1 VMot/Gnd header or the 24 V bus. For a quieter fan, use a 24 V fan with a lower rated current rather than a series resistor.
4. **Board:**
   - Screw the board to the standoffs with 4× M3 × 6, motor terminals toward the **front** (MOT/DRV) wall.
   - Connect the U.FL pigtail. **Never power up without the antenna** (wiki).
5. **Wiring:**
   - Pull cables in through their labelled glands. Strip, ferrule and land them with ≥30 mm of free conductor. Tighten the gland domes last.
   - Land the field-cable shield drains on a WAGO 221 together with the shield of the SIG cable, which is earthed at the power box (01 §3.2). Never on the board Gnd.
6. **Rack:**
   - Stand each DM542T on its two bosses between the guide rails, terminals up. Screw it through its side-mount slots with M3 × 8 + washers.
   - Set the DIP switches **before** closing the cover.
   - Run the 4 step/dir cables from the 6x DRV glands to the rack SD glands, 24 V from the power box to the rack "24V" gland, and 0.5 m of 2×1.0 mm² from the rack "OUT" gland to the 6x case "24V" gland.
7. **Mount:**
   - Screw or clamp the FR11 mounting rail (2040, 40 mm face up) to the bench beside the power box, **outside the wire span**.
   - Slide 2 M5 T-nuts into each of the two slots on its 40 mm face.
   - Place the box with the rail running front-to-back under its middle. Bolt both tabs (4× M5 × 10 + washers).
   - Put the 6x case and the rack on the same rail, one after the other.
8. **Close:** fit the lid (the lip locates it) with 6× M3 × 8 (4 on the rack cover).

## 7. Notes and limits

- **Electrical:**
  - These boxes are **not** a mains enclosure. Only 24 V goes in them (01: mains, PSUs, SSR and E-stop stay in the steel power box).
  - PETG/ASA are not V-0. That is acceptable for the 24 V side with fused supplies (F2 5 A on the 24 V bus). Keep the box away from the hot wire and the foam.
- **Cooling:** the 4x TMC2209s have no heatsinks (wiki photo). The wiki asks for forced air above 1.2 A. The lid fan blows straight onto them, and `run_amps: 1.0` stays well inside that.
- **Antenna:** the 6x **v1.1** has a PCB antenna and no U.FL. Leave the ANT hole empty (or plug it). A plastic box doesn't block Wi-Fi.
- **SD card:** the slot faces the left wall, 35 mm away. Take the lid off to swap the card.
