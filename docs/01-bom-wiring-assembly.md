# wingcut-fluidnc build guide: BOM, wiring and assembly

*Version 4, 2026-11-05. A DIY 4-axis CNC hot-wire foam cutter for RC/UAV wing panels, driven by **[wingcut](https://github.com/andres/wingcut)** through **FluidNC** firmware. Two controller variants, same machine:*
- ***Variant A**: FluidNC **4x** board (4 on-board TMC2209 drivers). Recommended and cheapest.*
- ***Variant B**: FluidNC **6x** board + 4 external **DM542T** drivers. Use it if the 4x is out of stock, or if you want external drivers.*

*Firmware, bring-up and wingcut setup: [02-firmware-commissioning.md](02-firmware-commissioning.md) (variant A) plus [02b-6x-variant.md](02b-6x-variant.md) (differences for B).
Configs: [fluidnc-4x-hotwire.yaml](../config/fluidnc-4x-hotwire.yaml), [fluidnc-6x-hotwire.yaml](../config/fluidnc-6x-hotwire.yaml), [wingcut-machine.toml](../config/wingcut-machine.toml).
Printed controller enclosures: [enclosure/](../enclosure/). Orderable list: [bom.csv](../bom/bom.csv).
Prices (≈) are typical Nov-2026 street prices, excluding shipping and VAT. EUR ≈ USD × 0.92.*

> **Mains warning.** The **power box** contains 115/230 V AC wiring: inlet, E-stop and PSUs. If you are not qualified, have an electrician do section 3.1 (mains rows), 5.1 steps 1–2 and test 6.1. Feed the machine from a **30 mA RCD/GFCI** outlet. Everything outside the power box is 24–36 V DC.

---

## 0. What you are building

| Spec | Value |
|---|---|
| Panels | up to **1250 mm** long. A 4 m wing = 4–5 panels. |
| Wire span (wire contact to wire contact) | **1450 mm** default (= wingcut `tower_spacing`). **≈1350–1650 mm** without changing the base or bed. |
| Chord travel (X root, Z tip) | ≈1000 mm, MGN12 rail on T-slot, GT2 belt, 80 steps/mm |
| Vertical travel (Y root, A tip) | ≈300 mm, MGN12 + T8×2 lead screw, 1600 steps/mm, self-locking |
| Frame | **20×40 aluminium T-slot extrusion** (6 mm slot, V-slot compatible), cast corner brackets |
| Wire | 0.4 mm Ni80Cr20 through MIG contact tips, ≈20 N constant-force spring |
| Controller | **A:** FluidNC 4x (ESP32 + 4× TMC2209). **B:** FluidNC 6x (ESP32) + 4× DM542T. |
| Boxes | **Steel power box** (mains, PSUs, SSR, E-stop, meter) + **3D-printed controller box** on the frame (24 V only) |
| Power | **24 V** (controller + motors) + **separate floating 36 V** wire supply. Heat = PWM through an **isolated DC SSR**. Option: Riden RD6006 constant current. |
| PC link | USB through an **ADuM3160 USB isolator** (or Wi-Fi). wingcut runs on Linux (also macOS/Windows). |
| Safety | 3-NC E-stop: cuts AC (L+N) to both PSUs **and** drives FluidNC `estop_pin`. The wire circuit floats. Frame bonded to PE. wingcut Pause turns the wire off. |
| Axis letters | wingcut default `["X","Y","Z","A"]` = **X root chord, Y root vertical, Z tip chord, A tip vertical**. Root tower = left, tip tower = right. |

### Cost

| Build | ≈ USD | ≈ EUR |
|---|---|---|
| **Variant A (4x board), everything counted** | **≈ 990** + shipping | ≈ 910 |
| **Variant B (6x + 4× DM542T)** | **≈ 1130** + shipping | ≈ 1040 |
| Tighter (section 2.12): aluminium plates printed instead, hanging weight, no dummy load | −≈ 45 | −≈ 41 |
| Genuine Schneider E-stop instead of a generic 3-NC one | +85 | +78 |
| Riden RD6006 option (constant current, wingcut break detection), net | +75 | +69 |

Shipping is extra and not small: 1.9 m extrusions alone typically add $30–60, and a multi-seller order $80–150.

**Why not $600?** Early estimates (including wingcut's `docs/hardware-plan.md`) priced only the big parts. Counted honestly, about $250 more goes on:
- fasteners and enclosure hardware,
- ferrules, lugs, heat-shrink and PE bonding,
- chain-rated cable and drag chains,
- a steel mains box, terminals and glands,
- the USB isolator.

Two independent audits are behind this list ([audit](audit.md)). Going below it means a plywood/drawer-slide machine with a ~1 m wire.

```
TOP VIEW (W = wire/span direction, X = chord direction)
                 B2 base rail 2040 x1900  (back)
   ┌──────────────────────────────────────────────────────────┐
   │ idler                                            idler   │
   ║ X-beam root 2040x1250      C1        C2   X-beam tip 2040x1250
   ║ + MGN12 1200         ┌──────────────────┐   + MGN12 1200 ║
   ║   [ROOT tower X/Y]≡≡≡│  bed 1300 x 700  │≡≡≡[TIP tower Z/A]║  ← wire 1450 mm
   ║                      └──────────────────┘                ║
   │ motor X                                          motor Z │
   └──────────────────────────────────────────────────────────┘
                                           B1 base rail 2040 x1900 (front)
   [bench, left of the root tower, OUTSIDE the wire span: steel power box + printed controller box
    (and DM542T rack for B) on a short 2040 mounting rail; E-stop within reach of the operator]

SIDE VIEW OF ONE TOWER (looking along the wire, inboard = right)
   motor (Y or A) under top plate P3 ─ coupler ─ T8x2 screw (≈34 mm inboard of post face, behind rail)
   post 2040x500 │ MGN12 400 ─ block ─ head plate P2 ─ FR4 5 mm ─ tip block + MIG tip ═══ wire
   carriage plate P1 (asymmetric: inboard edge 20 mm from rail centre) on 2x MGN12H
   MGN12 1200 on X-beam (2040 standing) ─ sits across B1/B2
```

---

## 1. Electrical architecture

```
STEEL POWER BOX (mains + wire power)
 MAINS ─ IEC inlet (switch + F1) ─ E-STOP NC1 (L), NC2 (N) ─┬─► PSU1 LRS-100-24 ─ F2 5A ─► "24V OUT" ──(cable PB-24)──┐
                                                             └─► PSU2 LRS-150F-36 (wire, floating)                 │
 E-STOP NC3 ────────────────────────────────────────────────────────────────────(cable PB-SIG)───────────────────┤
 SSR control 3(+)/4(−) ◄────────────────────────────────────────────────────────(cable PB-SIG)───────────────────┤
 PSU2 +V ─ F3 4A ─ wire+ ─┬─► W-HR ─ ROOT tip ═══ wire ═══ TIP tip ─ W-HT ─┬─ SSR 1(+)  SSR 2(−) ─ meter shunt ─ PSU2 −V
                          └──────── freewheel diode (cathode → wire+) ─────┘ (anode)
 PE busbar ─► inlet PE, PSU FG ×2, box body + lid, frame bond, cable shields
                                                                                                                  │
PRINTED CONTROLLER BOX (24 V only, on the frame)  ◄────────────────────────────────────────────────────────────────┘
 Variant A: 4x board (VMot 24 V) ─ TMC2209 ×4 ─► motors X, Y, Z, A
 Variant B: 6x board (VMot 24 V) ─ STEP/DIR/EN ×4 ─► DM542T ×4 (printed rack, 24 V) ─► motors X, Y, Z, A
 Both:  limits X/Y/Z/A (gold NC to Gnd, 100 nF) ─► inputs
        E-stop NC3 ─► estop input          MOSFET "gpio.4" (PWM 100 Hz, M3 S0–1000) ─► SSR control
        USB ─► ADuM3160 USB isolator ─► PC running wingcut          (or Wi-Fi)

RIDEN OPTION: PSU2 = LRS-150F-48 ─► RD6006 (CC 2.0–2.3 A) ─► wire+ / SSR loop (SSR on/off only, M3 S1000)
              RD6006 USB ─► second ADuM3160 isolator ─► PC (wingcut)
```

Why:
- **Wire-off paths:**
  - **E-stop** cuts AC to everything (hardware, PC-independent). Its **third NC contact** drives FluidNC's `estop_pin`, so even if the controller stays alive (variant A may stay up through some USB isolators), FluidNC hard-stops, switches the wire off and stays in alarm. The 6x (B) simply powers off and reboots. **Releasing the E-stop never restarts the wire or the job**: RESET → (`$MI` on variant A) → `$H` is needed.
  - **SSR** opens on M5, any FluidNC alarm (`off_on_alarm`), reset, and wingcut Pause/Stop.
  - **Riden option:** wingcut also switches the Riden output off after every cut and on a broken wire.
  - If the PC or USB dies mid-cut, the board keeps the wire on. **The E-stop is the safety**, as wingcut's own docs say.
- **Isolation:**
  - The 24 V system is **PELV**: 0 V is bonded to PE at one point in the power box.
  - The wire supply floats, and the SSR is opto-isolated.
  - The **USB isolator** keeps PC ground off the controller's 0 V, which removes ground loops and protects the PC.
  - The Riden option has its own isolator, because its USB ground may be tied to its output negative ([EEVblog](https://www.eevblog.com/forum/testgear/ruideng-riden-rd6006-dc-power-supply/msg2870708/), [Hackaday](https://hackaday.com/2020/03/16/review-the-riden-rd6006w-dc-power-supply-module)).
  - A dropped wire on the earthed frame does nothing.
- **Two boxes:** mains, PSUs and the SSR sit in a **steel** box, because printed PETG/ASA is not flame-rated and this machine sits next to polystyrene. The printed box holds only 24 V parts, mounts on the frame, and keeps motor cables short.
- **Freewheel diode** across the long wire loop, as the DC60 datasheet requires for inductive loads ([datasheet](https://jinzon.url.tw/pdf/crydom_dc60.pdf)).

---

## 2. Bill of materials

Every line has a quantity and an approximate **line total** in USD. Buy **2.1 + 2.2 + (2.3 or 2.4) + 2.5–2.10**. Totals are in 2.11.

### 2.1 Power box: mains, wire power, safety (PW), both variants

| ID | Qty | Part | Spec / example P/N / notes | ≈ USD line |
|---|---|---|---|---|
| PW1 | 1 | **PSU1: Mean Well LRS-100-24** | 24 V 4.5 A, universal input. [Spec](https://www.meanwell.com/Upload/PDF/LRS-100/LRS-100-SPEC.PDF). Variant B real load ≈3 A, still fine. | 20 |
| PW2 | 1 | **PSU2 (wire): Mean Well LRS-150F-36** | 36 V 4.3 A, adj. 32.4–39.6 V, universal input. [Spec](https://www.meanwell.com/Upload/PDF/LRS-150F/LRS-150F-SPEC.PDF). Not the non-F LRS-150 (selector switch). | 27 |
| PW3 | 1 | **Isolated DC SSR: Sensata/Crydom DC60S7** (or DC60S5) | Control 3.5–32 VDC (3+/4−); load 3–60 VDC 7 A (1+/2−); t_on 0.1 / t_off 0.3 ms, so 100 Hz PWM is fine. Not the DC60S3 (no margin at 2.7 A). **No no-name "SSR-xxDD".** [RS](https://uk.rs-online.com/web/p/solid-state-relays/7360882) | 50 |
| PW4 | 1 | SSR heatsink ≤3 K/W + thermal pad | ≈2–3 W | 4 |
| PW5 | 1 | **E-stop** 22 mm mushroom, latching twist-release, **3 NC** (NC1 L, NC2 N, NC3 FluidNC), ≥10 A/250 VAC, finger-safe | Generic XB2/LA38 3-NC ≈ $15. Genuine Schneider XB5AS8442 (1 NC built in) + 2× ZBE102 ≈ $100. **NC3 must be a gold-plated / low-level contact block** (datasheet min. load ≤ 5 V / 1 mA). On variant A it switches **< 1 mA** (plain pull-up input), and silver contacts give random E-stops mid-cut. On B (≈12 mA opto input) silver is acceptable, but gold is still better. | 25 |
| PW6 | 1 | IEC C14 inlet with switch + 5×20 fuse holder | | 5 |
| PW7 | 5 | F1 mains fuses 5×20 slow-blow | **T3.15 A** (230 V) / **T6.3 A** (115 V) | 3 |
| PW8 | 1 | IEC C13 mains cord, local plug | | 5 |
| PW9 | 2 | **F2:** inline ATO holder + 5 A fuses (24 V). **F3:** inline **5×20 holder + T4 A 250 V** fuses (wire; ATO blades are only 32 V rated). 3 spares each. | | 6 |
| PW10 | 1 | **DC panel meter V/A 0–100 V / 10 A, internal shunt, self-powered from the measured line (≥40 V)** | Wire current. Must read **0.00 A** after M5, which is the shorted-SSR check. Never power it from 24 V. | 7 |
| PW11 | 1 | **Dummy load 22 Ω 100 W aluminium-clad** | Wire-circuit tests (6.3); screwed to the plate | 8 |
| PW12 | 1 | **Steel enclosure ≈ 400 × 300 × 150 mm** with mounting plate ≈ 360 × 260, PE studs on body + lid | PSUs 308 × 97 + DIN band + SSR row fit. Lay it out first. | 40 |
| PW13 | 2 | Vent grills / louvres | Low intake, high exhaust (PSUs are convection-cooled) | 4 |
| PW14 | 1 set | DIN rail 35 × 300 + **14 feed-through terminals 2.5 mm²** + **12-way PE busbar** + jumpers + end stops + markers | Buses L, N, +24 V out, 0 V, wire+; one PE conductor per clamp | 20 |
| PW15 | 7 | Cable glands: **2× M16 (4.5–10 mm)** for PB-24 and PB-SIG, **2× M12 (2–5 mm)** for W-HR and W-HT (or sleeve the leads with adhesive heat-shrink), **1× M12 (3–6.5 mm)** for PE, 2 spare | | 4 |
| PW16 | 2 | **Freewheel diode UF5404** (3 A 400 V) | 1 + spare | 1 |
| PW17 | 1 kit | Enclosure hardware: 10× M4×10, 14× M4 nuts, 6 serrated washers M4/M5, 8× M3×5 for the PSUs (**max 4 mm into the PSU**) | DIN rail, SSR/heatsink, dummy load, PE studs, PSUs | 4 |

### 2.2 Controller side, both variants (CC)

| ID | Qty | Part | Spec / notes | ≈ USD line |
|---|---|---|---|---|
| CC1 | 1 | **USB isolator ADuM3160 (full-speed 12 Mbit/s), ≥1.5 kV, boxed**: USB-B (or USB-A male) upstream, USB-A female downstream | Between PC and controller. Full speed is all the board's USB-serial chip uses. The board must be powered from 24 V: the isolator's output can't run it. | 12 |
| CC2 | 5 | **Gold-contact roller microswitches Omron D2F-01L3** (4 + spare) | Low-current inputs need gold contacts ([Omron](https://omronfs.omron.com/en_US/ecb/products/pdf/en-ss.pdf)) | 13 |
| CC3 | 10 | 100 nF ceramic capacitors 50 V | Across each limit and estop input at the board | 1 |
| CC4 | 1 | **Adafruit #4218 USB-C round panel-mount extension, 30 cm** (Ø22 mm hole), data-capable | Board USB-C → case wall | 6 |
| CC5 | 1 | USB-A ↔ USB-B 0.5 m (PC ↔ isolator, to match your isolator) + USB-A ↔ USB-C **data** cable 2 m (isolator ↔ case bulkhead) | | 7 |
| CC6 | 1 | U.FL → SMA bulkhead pigtail + 2.4 GHz antenna | Usually included with the board; else buy. **Never power the board without it.** | 4 |
| CC7 | 1 kit | Printed-box hardware: M3×5.7 heat-set inserts (10 per case, +12 for the rack), M3×6/×8 screws, M4×30 + nuts (fan), M5×10 + washers + T-nuts (4 per box). Exact list: [enclosure/README](../enclosure/README.md) §3 | | 6 |
| CC8 | 0.5 kg | PETG or ASA filament | Controller case (B needs VB9 too) | 10 |
| CC9 | 3 | WAGO 221-415 lever connectors (5 conductors each) | Shield drains in the case, linked with a 0.5 mm² GN/YE jumper (A: 9 drains; B: 6 + rack link). B also needs VB8. | 3 |

### 2.3 Variant A: FluidNC 4x (VA)

| ID | Qty | Part | Spec / notes | ≈ USD line |
|---|---|---|---|---|
| VA1 | 1 | **FluidNC 4x CNC Controller v1.1 (ESP32 + 4× TMC2209)** | Bart Dring. [Elecrow $49](https://www.elecrow.com/4x-cnc-controller-integrated-esp32-and-tmc2209.html), **out of stock 2026-11-05**: click "notify me", or build variant B. | 49 |
| VA2 | 1 | **80 × 80 × 25 mm 24 V fan** (≈0.1 A) | In the case lid, blowing onto the on-board drivers (lid grille = guard) | 5 |
| VA3 | 12 | Cable glands for the case: **10× M16 × 1.5 (4.5–10 mm)** (4 motor, 4 limit, PB-24, PB-SIG) + 2 spare | | 6 |

### 2.4 Variant B: FluidNC 6x + DM542T (VB)

| ID | Qty | Part | Spec / notes | ≈ USD line |
|---|---|---|---|---|
| VB1 | 1 | **FluidNC 6x CNC Controller, integrated ESP32** (v1.2+) | Bart Dring. 12–30 V, external-driver outputs only, CP2102 USB-C. [Elecrow $49](https://www.elecrow.com/6x-cnc-controller-for-fluidnc.html) / [Tindie](https://www.tindie.com/products/33366583/6x-cnc-controller-for-fluidnc-integrated-esp32/) | 49 |
| VB2 | 4 | **Stepper driver StepperOnline DM542T V4.0** | 18–50 VDC, differential PUL±/DIR±/ENA±, **S2 selector → 5 V** (ships at 24 V). [Manual](https://forum.duet3d.com/assets/uploads/files/1684504031141-dm542t_v4.0.pdf). Not the DM320T (common-anode inputs). | 108 |
| VB3 | 1 + 1 | **60 × 60 × 25 mm 24 V fan** (6x case lid) + **optional 80 × 80 × 25 mm 24 V fan** (rack end wall) | The rack also works as a chimney without its fan | 8 |
| VB4 | 4 × 0.6 m | Step/dir cables 6x → rack: 4-core shielded 0.25 mm² (or TRVVP 4×0.3), one per driver | STEP, DIR, EN, GND | 5 |
| VB5 | 3 m each | 1.0 mm² red/black | 24 V from the rack WAGOs to each DM542T (own pair per driver, inside the rack) | 4 |
| VB6 | 1 set | Twin ferrules 2×0.5 mm² | PUL−/DIR−/ENA− jumpers | 2 |
| VB7 | 21 | Cable glands: 6x case **6× M16 (4.5–10)** (4 limit, 24 V in, PB-SIG) + **4× M12** (step/dir out); rack **6× M16** (4 motors, PB-24 in, 24 V out to the 6x) + **4× M12** (step/dir in); 1 spare | | 10 |
| VB8 | 4 | WAGO 221-415 (rack): +24 V bus, 0 V bus (2 linked each) | 7 conductors per bus: PB-24, 4 drivers, 6x feed, rack fan | 4 |
| VB9 | 0.5 kg | Extra PETG/ASA for the 6x case + rack (≈0.9 kg total) | | 10 |

**Riden option (R), +≈$75 net** (+$82 before dropping PW10):
- **R1:** Riden RD6006 USB version (≈$65).
- **R2:** second ADuM3160 USB isolator (≈$12).
- **R3:** LRS-150F-48 instead of PW2 (same price).
- **R4:** USB cable + 1 M16 gland (≈$5). Pass the device end in from outside, or use a split USB grommet: a USB-A plug won't pass an M16 gland.
- **Mounting:** RD6006 in a cut-out in the power-box lid (its front-panel size; check the module's drawing).
- Drop PW10: the Riden shows V/A, and wingcut watches the current.

### 2.5 Cables and wiring consumables (CB), both variants

| ID | Qty | Part | Spec / use | ≈ USD line |
|---|---|---|---|---|
| CB1 | 18 m | **TRVVP (drag-chain) shielded 4×0.5 mm²** | 4 motor runs (15 m) + PB-SIG power box ↔ controller (3 m) | 26 |
| CB2 | 15 m | **TRVVP shielded 3×0.3 mm²** | 4 limit runs | 14 |
| CB3 | 5 m red + 6 m black | Silicone wire 1.0 mm² (18 AWG), fine-strand | Hot-wire leads W-HR (red), W-HT (black) | 10 |
| CB4 | 2 m each | 1.0 mm² H07V-K brown, blue, green/yellow | Mains inside the power box | 5 |
| CB5 | 3 m each | 1.0 mm² red, black, orange | 24 V and wire (orange) circuits inside the power box | 6 |
| CB6 | 3 m each | 0.5 mm² red, black | Fans, internal jumpers | 3 |
| CB7 | 1 set | 0.25 mm² hook-up, 4 colours | Caps, short internal links | 4 |
| CB8 | 5 m + 4 m | 1.5 mm² GN/YE (frame bond, lid strap, static frame jumpers, PELV bond) + 0.5 mm² GN/YE 4 m (rail and carriage bonds) + 6 M5 + 10 M3 ring lugs + serrated washers | PE bonding | 7 |
| CB9 | 2 | **Drag chain 15×20 mm inner, bend radius ≥ R48, openable, 1 m**, with end brackets | One per tower along X | 14 |
| CB10 | 1 set | Spiral wrap 8–10 mm (3 m) + 10 P-clips | Head-lead loops, power-box lid harness | 5 |
| CB11 | 1 set | Ferrules 0.25–1.5 mm² (+ twin) | Every screw terminal | 10 |
| CB12 | 1 set | Insulated ring lugs M4/M5 | Tip blocks, PE | 4 |
| CB13 | 1 set | Heat-shrink incl. adhesive-lined | Motor/limit splices | 6 |
| CB14 | 1 set | Cable ties, adhesive mounts, 10 T-slot tie mounts, labels | Routing | 8 |
| CB15 | 1 | Solder | Splices | 3 |
| CB16 | 3.5 m | **2-core 2×1.0 mm² red/black DC cable** (PVC or silicone, not grey mains cable) | **PB-24** (3 m) + B: rack → 6x (0.5 m). Label both ends "24 V DC". | 4 |

### 2.6 Frame (FR): 20-series T-slot, 6 mm slot

| ID | Qty | Part | Spec / use | ≈ USD line |
|---|---|---|---|---|
| FR1 | 2 | **2040 × 1900 mm** | Base rails B1 (front), B2 (back), standing (40 tall) | 43 |
| FR2 | 2 | **2040 × 1250 mm** | X-beams (root, tip), standing. **Tap both end holes M5.** | 28 |
| FR3 | 2 | **2040 × 1250 mm** | Bed supports C1, C2 | 28 |
| FR4 | 2 | **2040 × 500 mm** | Tower posts. **Tap both ends M5.** | 12 |
| FR5 | 24 | 2040 cast corner brackets + M5 screws | 8 X crossings, 8 C crossings, 4 posts, 4 for P6, spares 0 | 12 |
| FR6 | 150 | M5 drop-in T-nuts | ≈114 used | 11 |
| FR7 | 100 | M3 drop-in T-nuts | MGN12 rails (≈64 used) | 6 |
| FR8 | 1 | **Bed** 18 mm MDF/ply 1300 × 700, sealed 2× PU | | 25 |
| FR9 | 4 | Rubber pads | Feet | 4 |
| FR10 | 1 set | Foam hold-down: 4–6 kg steel offcuts + pins/carpet tape + 15–20 mm scrap-foam spacer strips | | 5 |
| FR11 | 1 | **Box mounting rail:** 2040 offcut lying flat, **250 mm (A) / 480 mm (B)**, + 4 M5 T-nuts + 2 wood screws/clamps to the bench | Printed boxes bolt to it, beside the power box | 5 |

### 2.7 Motion and drive (M, L, D)

| ID | Qty | Part | Spec / use | ≈ USD line |
|---|---|---|---|---|
| M1 | 5 | **NEMA17 17HS19-2004S1** (4 + spare) | 2.0 A, 59 Ncm, 1 m lead. Black/green = coil A, red/blue = coil B (≈1.4 Ω, verify). [StepperOnline](https://omc-stepperonline.com/nema-17-bipolar-59ncm-84oz-in-2a-42x48mm-4-wires-w-1m-cable-and-connector.html) | 42 |
| L1 | 2 | **MGN12 rail 1200 mm + 2× MGN12H blocks** | Chord axes | 64 |
| L2 | 2 | **MGN12 rail 400 mm + 1× MGN12H** | Vertical axes | 28 |
| L3 | 1 | Lithium grease | | 3 |
| D1 | 10 m | GT2 belt 6 mm, glass-fibre | 2 × ≈2.6 m | 8 |
| D2 | 3 | GT2 20T pulley, 5 mm bore | 2 + spare | 4 |
| D3 | 3 | GT2 20T toothed idler, 5 mm bore | 2 + spare | 4 |
| D4 | 4 | Steel NEMA17 L-bracket | 2 chord motors + 2 idler brackets | 10 |
| D5 | 2 | M5 × 40 bolt + 4 washers + nylock | Idler axles | 2 |
| D6 | 4 | GT2 belt clamps | On belt tab P4 | 4 |
| D7 | 2 | **T8×2 (2 mm lead, single start) lead screw 400 mm + flanged brass nut** | Verticals. Not T8×8 (back-drives). | 20 |
| D8 | 2 | Flexible coupler 5 → 8 mm | | 4 |
| D9 | 2 | KFL08 flange bearing | Screw bottom | 4 |
| D10 | 2 | T8 nut bracket (22 mm flange) | On head plate. Measure its nut-centre height (4.3). | 4 |

### 2.8 Wire heads, wire, tension (H)

| ID | Qty | Part | Spec / use | ≈ USD line |
|---|---|---|---|---|
| H1 | 1 reel | **Ni80Cr20 0.4 mm, 10–20 m** | ≈8.7 Ω/m → ≈12.6 Ω at 1.45 m | 10 |
| H2 | 10 | **MIG contact tips M6 × 25 for 0.6 mm wire** (CuCrZr) | Guide + current feed | 8 |
| H3 | 2 | Tip blocks (from ST5) | 20×20×30 alu: M6 through, M4 lug, 2× M4 mounting | 0 |
| H4 | 1 | **FR4/G10 5 mm**, 100 × 150 | Insulators | 8 |
| H5 | 2 | POM (Delrin) V-wheel with 625ZZ | Tip-side deflector. Plastic = insulating. | 3 |
| H6 | 1 | **Constant-force spring ≈20 N**, ≥150 mm usable extension, drum | McMaster 9293K / Gutekunst. Alternative: 2 kg weight in a 50 mm PVC tube. | 10 |
| H7 | 2 m | Aramid (Kevlar) line 1 mm, ≥50 kg | Insulating links | 4 |
| H8 | 20 | Crimp sleeves 1.0 mm | Wire loops | 2 |
| H9 | 4 | Nylon M4 screws + nuts | Root-side anchor | 3 |

### 2.9 Fasteners (FX)

| ID | Qty | Part | Use | ≈ USD line |
|---|---|---|---|---|
| FX1 | ≈150 | M5 button-head DIN 7380, 8/10/12/16 mm | Frame, brackets | 12 |
| FX2 | 40 + 10 | M5 washers + nylock | | 3 |
| FX3 | ≈200 | M3 socket cap 6–20 mm | Rails, blocks, motors | 8 |
| FX4 | 50 | M3 washers | | 2 |
| FX5 | 30 + 4 | M4 SHCS 8–20 + nuts + **4× M4×12 countersunk DIN 7991** | Tip blocks, lugs | 5 |
| FX6 | 1 | M5 shoulder bolt Ø6 × 10 | Spring drum | 3 |
| FX7 | 8 | **M3 × 5** | PSU mounting (max 4 mm into the PSU) | 1 |
| FX8 | 8 | M2 × 12 + nuts | D2F switches | 2 |
| FX9 | 1 | Thread-locker, medium | Set screws, couplers | 4 |
| FX11 | 8 | **M5×25 countersunk DIN 7991** | Bed down into T-nuts in C1/C2 | 1 |
| FX12 | 2 sets | Chain standoff: 2× M5 × 30 mm aluminium spacers + 2020 offcut 100 mm (or 6 mm plate 100 × 40) per tower | Chain fixed end ≥80 mm out from the X-beam, outboard of belt and motor | 4 |

### 2.10 Raw stock (ST) and fabricated parts

| ID | Qty | Part | Makes | ≈ USD line |
|---|---|---|---|---|
| ST1 | 2 | 6061 plate 8 mm, 160 × 130 | P1 | 15 |
| ST2 | 6 | 6061 plate 6 mm: 2× 80 × 140, 4× 70 × 60 | P2, P3, P6 | 15 |
| ST3 | 120 mm | Alu angle 30×30×3 | P4 | 2 |
| ST4 | 150 mm | Alu angle 20×20×2 | P5 | 2 |
| ST5 | 70 mm | 6061 bar 20×20 | Tip blocks | 2 |

#### Fabricated parts (made from ST, or printed: 2.12 #1)

| ID | Qty | Part | Size | Holes / features |
|---|---|---|---|---|
| P1 | 2 | **Tower carriage plate, asymmetric** | 160 (X) × 130 (W) × 8 | Rail centre line **20 mm from the inboard edge**, 110 mm outboard. 2× MGN12H patterns (4× M3, 20×20), block centres 100 mm apart. 2× M5 c'sunk into the post end. Outboard edge: 2× M5 for P4. Front edge = chord limit striker. |
| P2 | 2 | **Head plate** | 80 (X) × 140 (Y) × 6 | MGN12H pattern (front half). D10 nut bracket on the **inboard face, rear half**. FR4 + tip block at the **lower front inboard corner**. Tip-tower head: M5 for POM wheel + spring drum. Top edge = vertical limit striker. |
| P3 | 2 | Post-top motor plate | 70 × 60 × 6 | 2× M5 into the post top. NEMA17 (4× M3 / 31 mm, Ø23 boss) **centred on the screw axis** (≈32–36 mm inboard of the post face, behind the rail). |
| P4 | 2 | Belt tab | 30×30×3 angle × 50 | Bolted **under P1 at the belt line** (≈20–25 mm outboard of the rail centre), hanging ≈20 mm down to the belt top run, carries 2 clamps |
| P5 | 4 | Limit-switch brackets | 20×20×2 angle × 30 | M2 for D2F + M5 T-nut |
| P6 | 2 | Bottom bearing plate | 70 × 60 × 6 (like P3) | KFL08 **on the P3 screw axis**; fixed to the post bottom with 2 corner brackets |

### 2.11 Cost summary

| Group | ≈ USD | ≈ EUR |
|---|---|---|
| Power box: mains, wire power, safety (PW), both variants | 233 | 214 |
| Controller side, both variants (CC) | 62 | 57 |
| Variant A: FluidNC 4x (VA) | 60 | 55 |
| Variant B: FluidNC 6x + DM542T (VB) | 200 | 184 |
| Cables and wiring consumables (CB), both variants | 129 | 119 |
| Frame (FR): 20-series T-slot, 6 mm slot | 179 | 165 |
| Motion and drive (M, L, D) | 201 | 185 |
| Wire heads, wire, tension (H) | 48 | 44 |
| Fasteners (FX) | 45 | 41 |
| Raw stock (ST) and fabricated parts | 36 | 33 |
| **Variant A total** (all groups except 2.4) | **≈ 993** | **≈ 914** |
| **Variant B total** (all groups except 2.3) | **≈ 1133** | **≈ 1042** |

### 2.12 Tighter without losing reliability (≈ −$45)
1. **3D-print P1–P5 in PETG/ASA** (≥6 walls, 50 % gyroid) instead of cutting aluminium (−$30). Not the tip blocks.
2. **2 kg hanging weight** instead of the constant-force spring (−$8).
3. **Skip the dummy load** and test with the strung wire at low S (−$8). Keep the meter.
4. **Buy extrusion cut-to-length locally** (Misumi, Dold, Motedis, 8020 dealers) if shipping 1.9 m bars is expensive.

Do **not** cut: the isolated SSR, the E-stop (3 NC), the fuses, the diode, the PE bond, the gold switches, the chain-rated cable, the separate floating wire PSU, the USB isolator, the steel power box.

### 2.13 Workshop safety (not in the total, required)
- Ducted fume extraction outdoors (100 mm inline fan + hose, ≈$40).
- CO₂/ABC extinguisher.
- Smoke detector.
- Safety glasses when the wire is tensioned.
- RCD outlet.

### 2.14 Tools (not in the total)
- **Electrical:** multimeter (essential), ferrule crimper, ring-lug crimper, strippers, soldering iron, heat gun.
- **Machining:** M3/M5 taps, 2.5/4.2 mm drills, countersink, drill press (preferred), hex keys, square, 1 m rule, calipers, level, deburring tool.
- **Wire:** swaging pliers.
- **Printing:** a 3D printer with ≥220×220 mm bed and a heat-set insert tip.
- **Power-box cut-outs:** step drill (glands, E-stop 22.5 mm), jigsaw/nibbler + file (IEC, meter).

---
## 3. Wiring

### 3.1 Power box (both variants)

| From | To | Wire | Notes |
|---|---|---|---|
| IEC inlet **L** (after switch + F1) | E-stop **NC1** → **L-bus** | 1.0 brown | |
| IEC inlet **N** | E-stop **NC2** → **N-bus** | 1.0 blue | 2-pole: safe with non-polarised plugs |
| IEC PE | **PE busbar** | 1.0 GN/YE | Mains in its own corner. Lid harness (E-stop, meter) in spiral wrap with a hinge loop, P-clipped. |
| L / N / PE | PSU1 L / N / ⏚ and PSU2 L / N / ⏚ | 1.0 | |
| PE busbar | Body PE stud + plate; **lid PE stud via 1.5 mm² strap**, serrated washers | 1.0 / 1.5 GN/YE | The lid carries mains (E-stop) |
| PE busbar | M12 gland → **CB8 frame bond** → ring lug + serrated washer on B1 | 1.5 GN/YE | Bond-check every frame part (6.1) |
| PE busbar | Shield of PB-SIG (power-box end only) | 0.5 GN/YE | |
| PSU1 +V → **F2 5 A** | **+24 V out** terminal → PB-24 core "+" | 1.0 red | |
| PSU1 −V | **0 V out** terminal → PB-24 core "−" | 1.0 black | |
| **0 V out** terminal | **PE busbar** (one 1.0 mm² GN/YE, at this one point only) | 1.0 GN/YE | **PELV:** after a mains insulation fault, the 24 V system (USB-C and SMA shells on the printed case) can't float at mains potential. The USB isolator still breaks the PC ground loop. **PSU2 −V stays floating.** |
| E-stop **NC3** (two terminals) | PB-SIG cores 3 and 4 | 0.5 | Dry contact, goes to the controller's estop input |
| SSR **3 (+)** / **4 (−)** | PB-SIG core 1 / core 2 | 0.5 | Driven by the controller's MOSFET |
| PSU2 +V → **F3 T4 A** | **wire+** terminal | 1.0 orange | Wire circuit, kept apart |
| wire+ | W-HR (root lead, CB3 red); meter thin red; **diode cathode** | 1.0 orange | |
| W-HT (tip lead, CB3 black) | SSR **1 (+)**; **diode anode** | 1.0 orange | Diode across the wire, at the box |
| SSR **2 (−)** | Meter thick red (shunt in) | 1.0 orange | |
| Meter thick black (shunt out) | PSU2 **−V** | 1.0 black | |
| PSU2 −V | **nothing else** | | **OL to 0 V and PE** (6.1, 4.9) |
| *Riden option:* PSU2 (48 V) +V/−V | RD6006 input +/− | 1.0 | RD6006 **out + → F3 → wire+**; **out − → SSR 2 (−)** (meter removed). RD6006 USB → ADuM3160 → PC. Riden menu: **power-on output OFF**. |

### 3.2 Cables between the boxes

| Cable | Type | Core | Power-box end | Controller-box end |
|---|---|---|---|---|
| **PB-24** | CB16 2×1.0 mm² red/black, 3 m | + (red) | +24 V out | **A:** 4x VMot+ · **B:** rack "24V" gland → +24 V WAGO bus; from there 0.5 m of CB16 out of the rack's "24V OUT" gland → 6x case "24V" gland → 6x VMot+ |
| | | − (black) | 0 V out | **A:** 4x GND · **B:** rack 0 V WAGO bus → same 0.5 m CB16 → 6x GND |
| **PB-SIG** | CB1 TRVVP 4×0.5 shielded (≈6.5 mm), 3 m, standard M16 4.5–10 glands | 1 | SSR 3 (+) | MOSFET terminal **"VMot"** |
| | | 2 | SSR 4 (−) | MOSFET terminal **"gpio.4"** |
| | | 3 | E-stop NC3 a | **estop input** (A: gpio.33 · B: gpio.39) |
| | | 4 | E-stop NC3 b | that input's **Gnd** |
| | | shield | PE busbar | **WAGO 221 (CC9) with all field-cable shield drains**: this is how the field shields reach PE (one end only) |

### 3.3A Controller box, variant A: 4x board v1.1 (verified map, see 02)

| 4x terminal | Wire to | Cable | FluidNC |
|---|---|---|---|
| Power **VMot + / GND** (TB7) | PB-24 | CB16 | **24.0 V, never above 26 V** (TMC2209 max 29 V). **No reverse-polarity protection** (6.2 step 0). |
| **TB1** motor X (coils on adjacent pins) | Root chord motor: black/green on one adjacent pair, red/blue on the other | CB1 | X, TMC addr 0 |
| **TB3** motor Y | Root vertical motor | CB1 | Y, addr 1 |
| **TB4** motor Z | Tip chord motor | CB1 | Z, addr 2 |
| **TB5** motor A | Tip vertical motor | CB1 | A, addr 3 |
| Input **gpio.36** + Gnd | Root chord switch (COM → Gnd, NC → signal) + 100 nF | CB2 | X `limit_neg_pin` (front) |
| Input **gpio.39** + Gnd | Root vertical switch + 100 nF | CB2 | Y `limit_pos_pin` (top) |
| Input **gpio.34** + Gnd | Tip chord switch + 100 nF | CB2 | Z `limit_neg_pin` (front) |
| Input **gpio.35** + Gnd | Tip vertical switch + 100 nF | CB2 | A `limit_pos_pin` (top) |
| Input **gpio.33** + Gnd | PB-SIG cores 3/4 (E-stop NC3) + 100 nF | CB1 | `control: estop_pin: gpio.33` |
| **TB10 "VMot"** / **TB10 "gpio.4 (MOSFET)"** | PB-SIG core 1 / core 2 (SSR 3+/4−) | CB1 | `PWM: output_pin: gpio.4`, 100 Hz, S0–1000 |
| USB-C | Bulkhead CC4 → cable → **USB isolator CC1** → PC | | wingcut connection |
| Antenna (U.FL) | Pigtail → SMA bulkhead on the case, antenna outside | | Never run without it |
| Shields of CB1/CB2 field cables (drain wires) | 2–3 linked WAGO 221s (CC9) inside the case, together with the PB-SIG shield, which is earthed at the power box | | Field shields: earthed at this end only; insulated at the motor/switch end |
| **Leave empty:** input gpio.32, MOSFET gpio.12, all 5 V outputs, module socket | | | gpio.12 pulled high = no boot |
| **StallGuard solder jumpers** (X/Y/Z/A = gpio.36/39/34/35) | **Open** | | Closed = switches ignored |

### 3.3B Controller box, variant B: 6x board + 4× DM542T (details: [02b-6x-variant.md](02b-6x-variant.md))

| 6x terminal | Wire to | Cable | FluidNC |
|---|---|---|---|
| Power **VMot + / GND** (12–30 V) | 0.5 m CB16 from the rack's "24V OUT" gland | CB16 | **24.0 V.** **No reverse-polarity protection** (6.2 step 0). |
| Motor1 STEP / DIR / EN + GND | DM542T #1 (X, root chord): PUL+ / DIR+ / ENA+; PUL−, DIR−, ENA− jumpered (twin ferrules) to GND | VB4 | X (i2so.2/1/0) |
| Motor2 … | DM542T #2 (Y, root vertical) | VB4 | Y (i2so.5/4/7) |
| Motor3 … | DM542T #3 (Z, tip chord) | VB4 | Z (i2so.10/9/8) |
| Motor4 … | DM542T #4 (A, tip vertical) | VB4 | A (i2so.13/12/15) |
| Input **io.33** + GND | Root chord switch + 100 nF | CB2 | X `limit_neg_pin` (front) |
| Input **io.32** + GND | Root vertical switch + 100 nF | CB2 | Y `limit_pos_pin` (top) |
| Input **io.35** + GND | Tip chord switch + 100 nF | CB2 | Z `limit_neg_pin` (front) |
| Input **io.34** + GND | Tip vertical switch + 100 nF | CB2 | A `limit_pos_pin` (top) |
| Input **io.39** + GND | PB-SIG cores 3/4 (E-stop NC3) + 100 nF | CB1 | `control: estop_pin: gpio.39` |
| MOSFET **"VMot" / "io.4"** | PB-SIG core 1 / core 2 (SSR 3+/4−) | CB1 | `PWM: output_pin: gpio.4` |
| USB-C (CP2102) | Bulkhead CC4 → **USB isolator CC1** → PC | | |
| Antenna (U.FL) | Pigtail → SMA bulkhead, antenna outside | | |
| Shields of field cables (drains) | Case: shield WAGOs (CC9) with the PB-SIG shield. Rack: the 4 motor shields on a rack shield WAGO, linked to the case WAGO **through the shield of the SD X step/dir cable** (rack end and case end on the WAGOs) | | One end only |
| **Leave empty:** io.2, io.26, io.36, MOSFET io.12, Motor5/6, all 5 V outputs, 0–10 V, RS485 | | | |

**DM542T V4.0 (each):**
- **Power:** +Vdc / GND from the rack WAGOs, own 1.0 mm² pair.
- **Motor:** A+ A− B+ B− to the motor (black, green, red, blue).
- **Logic selector S2 = 5 V.**
- **DIP switches:**
  - SW1–3 ON-OFF-ON = 1.91 A peak.
  - SW4 OFF = 50 % idle.
  - SW5–8 ON-ON-OFF-ON = 3200 pulses/rev.
- **ENA+ high = disabled.**

### 3.4 Field cables (machine side)

Controller box (and, for B, the rack) on its FR11 mounting rail **on the bench ≈0.5 m left of the root tower, outside the wire span**, never on the frame under the wire. Power box beside it. Lengths include 15 % slack. **Variant B:** motor cables start at the DM542T rack next to the 6x case.

| Cable | Route | To | Type | ≈ Length |
|---|---|---|---|---|
| W-MX | bench → B1 | Root chord motor (front) | CB1 | 1.5 m |
| W-MY | bench → B1 → **root drag chain** → up post | Root vertical motor (post top) | CB1 | 3.1 m |
| W-MZ | bench → along B1 | Tip chord motor (front) | CB1 | 2.7 m |
| W-MA | bench → B1 → **tip drag chain** → up post | Tip vertical motor | CB1 | 4.8 m |
| W-LX | bench → B1, other slot | Root chord switch | CB2 | 1.5 m |
| W-LY | root chain | Root vertical switch (post top) | CB2 | 3.1 m |
| W-LZ | along B1, other slot | Tip chord switch | CB2 | 2.7 m |
| W-LA | tip chain | Tip vertical switch | CB2 | 4.8 m |
| W-HR | power box → B1 → root chain → spiral loop → head | **Root tip block** (wire+) | CB3 red | 4.0 m |
| W-HT | power box → B1 → tip chain → spiral loop → head | **Tip tip block** (to SSR 1) | CB3 black | 5.8 m |
| PE | power box gland | B1 (+ jumpers) | CB8 | 2–3 m |

- **Motor splice:** solder each core to the motor's 1 m pigtail (cut the 0.1″ connector off). Stagger the joints, heat-shrink each, adhesive heat-shrink over all, strain-relief tie to the profile.
  - Shield: motor end cut back and insulated. Controller end on the shield WAGO, which is earthed through the PB-SIG shield at the power box (3.2).
- **Limit:** COM → Gnd core, NC → signal core, NO empty. A broken wire reads as "triggered" (fail-safe).
- **Separation:** motor and hot-wire cables on one side of the chain divider, limits on the other. Different profile slots for motor and limit cables on static runs. Keep the hot-wire leads ≥30 mm from limit cables everywhere.

---
## 4. Mechanical assembly

*Geometry checked in two independent audits (docs/audit.md).*

**Before starting:**
- Deburr and square all cuts (±0.3 mm).
- Tap M5 in both ends of the X-beams and posts.
- Measure your D10 nut-centre height and your MGN12H block height (needed in 4.3).

### 4.1 Base frame
1. B1, B2 standing (40 tall), parallel, **1150 mm apart centre-to-centre** (X-beams overhang ≈70 mm front, ≈30 mm back).
2. C1, C2 across them at W = ±450 mm from the centre, 2 corner brackets per crossing, loose.
3. Square the frame (diagonals ±1 mm), tighten, pads, level.

### 4.2 Chord axes (root and tip)
4. MGN12 1200 rail on top of each X-beam:
   - M3 screws into M3 T-nuts, every other hole (50 mm pitch). Straightedge, tighten from the centre outwards.
   - Slide both blocks on. **Never** slide a block off without a dummy rail.
5. X-beams across B1/B2, front overhang ≈70 mm, provisional centre distance ≈1580 mm (final in step 17).
   - 2 brackets per crossing.
   - **Parallel** ±0.5 mm (front and back).
   - **Square:** diagonals between rail ends ±1 mm.
6. P1 (narrow 20 mm side **inboard**) on the two blocks. Hand-push the full length: no tight spots. If it binds, re-straighten the rail.

### 4.3 Towers
7. Post upright on P1: 2× M5 into the tapped end + 2 brackets on its front/back faces. **40 mm face inboard.** Square both ways (<0.2 mm over 100 mm).
8. MGN12 400 on the post's inboard face, **front slot**, lower end as low as P1 allows. Target: **tip axis ≈5–10 mm above the bed top** at the lowest head position (bed top ≈ 98 mm: B 40 + C 40 + bed 18).
9. **Lead-screw axis:**
   - Distance from the post face = block height (≈13) + P2 (6) + D10 nut-centre height (measured). Typically **≈32–36 mm**, **behind the rail** in X.
   - Drill P3 and P6 on that axis.
   - Motor under P3, shaft down → coupler → T8×2 → KFL08 on P6.
   - Parallel to the rail ±0.2 mm. Inside the coupler, leave ≈1 mm between the motor shaft end and the screw end.
10. P2 on the block (front half) and the nut via D10 (rear half).
    - Turn by hand over the full travel: smooth, otherwise shim P6.
    - Note what P2 hits first at the top: the motor body or the coupler. Expect **≈300 mm** of travel.

### 4.4 Chord belts
11. Chord motor on a NEMA17 L-bracket on B1's top, beside the X-beam's **outer** face, shaft inboard. 20T pulley on the flat (thread-locker). Belt plane ≈10–15 mm outboard of the beam.
12. Idler L-bracket on B2, M5×40 axle, **same height and offset as the pulley ±0.5 mm**.
13. P4 bolted **under P1 at the belt line** (≈20–25 mm outboard of the rail centre), reaching down to the belt top run. Before drilling, draw one full-size section through the X-beam: rail, P1, P4, belt, pulley, motor and chain must not overlap. Belt: pulley → idler → tab, clamp, pull firm, clamp. Light twang, no sag, parallel to the rail.

### 4.5 Wire heads
14. Tip blocks:
    - MIG tip in by hand only.
    - Block → 5 mm FR4 with 2× **countersunk** M4 from the FR4 back, heads **≥1 mm below** the surface.
    - FR4 → P2's lower front inboard corner with 2 separate M4. **No metal may bridge the block to P2.**
15. **Root head:** FR4 anchor tab with a **nylon** M4, ≈25 mm outboard and ≈5 mm below the tip axis. The offset presses the wire into the tip bore, which gives good contact.
16. **Tip head:**
    - POM wheel on M5, ≈25 mm outboard and ≈10 mm below the tip axis.
    - Spring drum on the M5 shoulder bolt.
    - Kevlar from the spring to the wire loop.
    - **≥100 mm free stroke** at the widest spacing and maximum taper offset.
    - *Weight option:* Kevlar over the POM wheel to 2 kg in a PVC tube on P2's outboard side.
17. **Set the span:** slide the X-beams until wire-contact to wire-contact (tip ends) = **1450 mm** (= wingcut `tower_spacing`). Re-check parallel and square, tighten.
18. Insulation: tip block ↔ P2 / post / frame = **OL**.

### 4.6 Limit switches (gold D2F-01L3)
19. Switch placement:
    - **Chord (X, Z):** switch at the **front** of each X-beam, tripped by P1's front edge ≈10 mm before P4 hits the pulley.
    - **Vertical (Y, A):** switch at the **top** of each post, tripped by P2 ≈5 mm before it hits the motor body or coupler. Homing goes up, away from the foam.
20. Wire COM + NC only. Solder the 100 nF caps across signal–GND at the board end (CC3).

### 4.7 Bed
21. Bed on C1–C2, centred. Fix it with 8× M5×25 countersunk (FX11) down into T-nuts in C1/C2, heads 1 mm below the surface.
22. To cut through the block bottom: stand the foam on 15–20 mm scrap-foam strips.
23. By hand, at front and back:
    - Lowest tip axis ≥5 mm above the bed. **Write the value down**: it goes into the YAML (02).
    - Nothing on the heads touches the bed edge over the full travel.

### 4.8 Cable routing
24. Drag chain per tower, **outboard of the belt and motor**: fixed end on the FX12 standoff ≥80 mm out from the X-beam face at mid-length, moving end on P1's outboard edge (that's what P1's 110 mm overhang is for), loop horizontal. Contents: vertical motor, vertical limit, hot-wire lead (hot-wire lead and limit on opposite sides of the divider).
25. Post: clip the motor and limit cables (static). Hot-wire lead gets a free spiral-wrapped loop to the head (full vertical travel), strain-relieved on the **FR4**.
26. Static runs in B1 slots with T-slot tie mounts. Motor and limit cables in different slots.

### 4.9 Stringing the wire (after 6.3)
27. **Safety glasses on.**
    - ≈1.9 m of NiCr. Swaged loop → Kevlar → root anchor.
    - Through the root tip (outside in), across, through the tip-side tip, over the POM wheel.
    - Pull ≈60 mm of spring stroke, swage the loop to the spring Kevlar.
28. Tension: 100 g at mid-span deflects **≈14–24 mm** (15–25 N at 1.45 m). The wire sits in the bottom of both tip bores.
29. **With the wire strung** (power off): wire ↔ frame and PSU2 −V ↔ PE = **OL**. Repeat after every wire change.

---

## 5. Boxes

### 5.1 Steel power box
**Layout (≈360 × 260 plate):** lay it out full-size before drilling.
- **Top band:** PSU1 + PSU2 side by side (≈308 × 97 mm, vents up, M3×5 screws). Mains terminals face the left corner.
- **Middle band:** DIN rail with L, N, +24 V out, 0 V out, wire+, the E-stop NC3 pass-through terminals, and the F2/F3 inline holders. PE busbar on the plate.
- **Segregation:** route 24 V, PB-SIG and NC3 cores apart from mains cores, tied to the low-voltage side. NC3 goes on its own contact block, furthest from NC1/NC2.
- **Bottom band:** SSR on its heatsink, dummy load (PW11) screwed to the plate, diode on the terminals.
- **Lid:** E-stop and panel meter. Harness in spiral wrap with a hinge loop, P-clipped both sides. Lid PE strap.
- **Walls:** IEC inlet on the side; bottom-wall glands (PB-24, PB-SIG, W-HR, W-HT, PE); vent grills low and high.

**Wiring order (cord unplugged):**
1. **Mains:** inlet → E-stop NC1/NC2 → L/N buses → both PSUs. PE busbar to inlet, PSU FGs, body, plate, lid strap. Ferrules everywhere.
2. **24 V:** PSU1 → F2 → +24 V out / 0 V out terminals. Wire PB-24 at the power-box end only; its controller end stays **unconnected and insulated** (6.2 step 0).
3. **Wire circuit (orange):**
   - PSU2 → F3 → wire+ → (W-HR, meter thin red, diode cathode).
   - W-HT → SSR 1 + diode anode.
   - SSR 2 → meter shunt → PSU2 −V.
4. **PB-SIG:** cores 1/2 → SSR 3/4; cores 3/4 → E-stop NC3; shield → PE.
5. Label every wire at both ends.

### 5.2 Printed controller box
Print and assemble per **[enclosure/README.md](../enclosure/README.md)**:
- **Variant A:** `controller_case_4x`.
- **Variant B:** `controller_case_6x` + `dm542t_rack`.

Install the M3 heat-set inserts, mount the board (and the DM542Ts), the fan, the glands, the USB-C bulkhead and the SMA bulkhead. Bolt the case (and the rack) with M5 T-nuts to the **FR11 mounting rail**: a 2040 offcut lying flat (40 mm face up), running front-to-back under the box tabs. Screw or clamp the rail to the bench **beside the power box, outside the wire span**. Never mount a box on the frame under the wire, where fumes and heat get into the case.

**Wiring order:**
1. **PB-24:** at the controller end, leave it unconnected and insulated until 6.2 step 0.
   - *B only:* PB-24 enters the rack ("24V") onto the +24 V / 0 V WAGO buses (VB8). From there run a 1.0 mm² pair to each DM542T, the rack fan, and 0.5 m of CB16 out through "24V OUT" to the 6x case "24V" gland.
2. **PB-SIG:** cores 1/2 → MOSFET "VMot"/"gpio.4"; cores 3/4 → estop input + Gnd with 100 nF across.
3. **Limits:** 4 cables → their inputs + Gnd, 100 nF across each.
4. **Motors:**
   - **A:** 4 cables → TB1/TB3/TB4/TB5.
   - **B:** 4 cables → DM542T A+/A−/B+/B−, and 4 step/dir cables VB4 → 6x motor ports 1–4.
5. **Shield drains** → the linked shield WAGOs together with the PB-SIG shield (max 4 drains + 1 link per WAGO).
6. **USB-C:** board → Adafruit #4218 bulkhead (left wall; coil the spare cable in the USB bay). Antenna pigtail → SMA bulkhead (left wall).
7. Close the lid only after 6.2.

---

## 6. Tests before firmware

### 6.1 Unpowered (cord unplugged)
| Test | Expected |
|---|---|
| Inlet L–N, L–PE, N–PE (switch on, E-stop released) | no short |
| E-stop pressed: inlet L ↔ L-bus **and** inlet N ↔ N-bus; PB-SIG cores 3–4 (at the controller end) | **OL** all three. Released: cores 3–4 ≈ 0 Ω |
| Inlet PE ↔ power-box plate, body, **lid**, PSU cases | < 0.5 Ω |
| Inlet PE (via frame cable) ↔ **B1, B2, both X-beams, both posts, both P1/P2** | **< 1 Ω** each. Static joints: CB8 jumper with serrated washers. Rails: M3 ring lug under a rail screw ↔ extrusion. If P1/P2 still read > 1 Ω (the balls insulate), run a 0.5 mm² GN/YE core in each drag chain to P1, with a short loop to P2. |
| +24 V ↔ 0 V; PSU2 +V ↔ −V | no short |
| 0 V out ↔ PE (the PELV bond) | **< 0.5 Ω** |
| **PSU2 −V ↔ 0 V, ↔ PE; wire+ ↔ PE** | **OL** (the wire circuit floats) |
| Each motor's two coil pairs at the controller (A) or rack (B) end | ≈1.4 Ω each, OL between pairs |

### 6.2 First power
0. **Polarity pre-check** (PB-24 controller end still insulated): power on, measure **+24.0 V on the core landed on "+24 V out" (red) against the 0 V core (black)** at the PB-24 end. Power off, wait 30 s, connect it.
1. Power on: **24 V first, then USB**. PSU1 = 24.0 V (**never trim above 24.0 V**). Board LEDs on. *B:* DM542T green LEDs on.
2. Panel meter reads ≈36 V, 0 A (SSR off).
3. Continue with [02-firmware-commissioning.md](02-firmware-commissioning.md) (*B: also [02b-6x-variant.md](02b-6x-variant.md)*): flash, config, motors, limits, homing, tram. Then 6.3.

### 6.3 Wire circuit (dummy load PW11, before stringing)
**Hook-up:** power off. Lift W-HR from wire+ and W-HT from SSR 1, insulate them. Connect PW11 between **wire+ and SSR 1** with 2× 0.3 m 1.0 mm² orange + M4 ring lugs. Limits: S1000 ≤ 10 s, S500 ≤ 60 s.
1. `M3 S1000`: ≈36 V / **≈1.6 A**. `M3 S500` ≈0.8 A, `M3 S200` ≈0.33 A (the meter shows the average). `M5`: **0.00 A**.
2. **SSR-blocking test:** **power off**, lift PB-SIG core 2 at SSR 4 and insulate it, power on, `M3 S1000`: **0 A**. Power off, reconnect.
3. **Alarm test:** during `M3 S500`, **press a limit switch by hand** → ALARM → 0 A.
4. **E-stop test (critical):** with `M3 S500` and a jog running, press the E-stop, then **release it**. Expected: 0 A stays, no motion. **A:** state **Alarm** (estop), **or** a new boot banner + ALARM:14 if the board browned out; either way nothing moves or heats until RESET → `$MI` → `$H`. **B:** the 6x runs only from 24 V, so it powers off and reboots; reconnect wingcut, the board is in alarm until `$H`. 02b has the extra estop-pin test for B (lift the io.39 wire).
5. **wingcut Pause test:** in 02 (f), once wingcut is set up.
6. Set PSU2 to **36.0 V** (trim pot). Restore W-HR/W-HT.

*No dummy load (2.12 #3):* do steps 1–4 with the strung wire, S ≤ 300, a DMM in series, and no foam near.

**Expected with the real wire** (1.45 m, 12.6 Ω + ≈0.3 Ω, SSR drop ≈1.2 V):
- Full on ≈**2.7 A**.
- Target 2.0–2.3 A DC-equivalent (35–46 W/m) → **S ≈ 550–725**. Put it in wingcut's `heat_on` (placeholder `M3 S600`).
- Meter = (S/1000) × 2.7 A. Heating current = 2.7 A × √(S/1000).
- *Riden option:* `heat_on = "M3 S1000"`, current start 2.0 A, tune 2.0–2.3 A.
- Final tuning by kerf (02).

---

## 7. Connecting wingcut

1. **Install wingcut** on the PC ([README](https://github.com/andres/wingcut#build)): `cargo build --release` (Linux: `bash scripts/try-local.sh`).
2. **Copy the config:** copy [wingcut-machine.toml](../config/wingcut-machine.toml) next to your wing file as `machine.toml`. Measure and edit the placeholders: `tower_spacing`, `limits.y`, `heat_on`, `kerf`.
3. **Connection:**
   - PC → **USB isolator CC1** → controller USB.
   - Linux: `sudo usermod -aG dialout $USER`, log out and back in.
   - Find the port with `ls -l /dev/serial/by-id/` (variant A shows a CH340/CP210x entry, variant B a CP2102). Put that path in `[connection] port`.
   - Wi-Fi alternative: `kind = "telnet"`, `host = "fluidnc.local"`.
4. **Control tab:**
   - Connect. State and positions update, and connecting must not reboot the board.
   - Home, jog both towers, then a **dry run** of one panel (wire cold).
   - Then the Pause/STOP tests from 02 (f) and wingcut's [hardware-bringup.md](https://github.com/andres/wingcut/blob/main/docs/hardware-bringup.md).
5. **Riden option:** enable `[riden]`, port through the second isolator, `max_voltage = 36`, `current = 2.0`. Riden menu: USB, baud 115200, address 1, power-on output OFF.
6. **First cuts:** kerf test plugs (02 (e)), fill the `kerf` table, then a rectangular panel, then a tapered/swept one.

---

## 8. Gotchas

- **Board power polarity:** neither board has protection. Do 6.2 step 0 after any rework.
- **Variant A: 24 V before USB**, or the TMC2209s don't get their config. **After every E-stop: RESET → `$MI` → `$H`.**
- **Variant B: DM542T S2 must be on 5 V** (it ships at 24 V and won't move). **After an E-stop the 6x reboots** (it runs only from 24 V): reconnect wingcut, then `$H`.
- **False E-stop alarms:** the NC3 contact carries ≈12 mA. Clean or replace the contact block, or use a gold-flashed one.
- **USB isolator:** the board must run on its own 24 V. An isolated USB port can't power it, so the board won't come up from USB alone.
- **PC or USB lost mid-cut:** the board finishes its buffer and the **wire stays on**. Stay at the machine. The E-stop is the safety.
- **SSR fails short:** the meter shows current after M5. E-stop and replace. Re-run 6.3 step 2 after any rework.
- **Metal pulley, uninsulated anchor, or a tip-block screw touching P2** grounds the wire. Plastic wheel + Kevlar + countersunk FR4 are mandatory. 4.9 step 29 must read OL.
- **Random limit alarms:** silver switches, missing 100 nF caps, or shield not on PE.
- **Riden option:** USB only through its own isolator. Power-on output OFF.
- **No mains in the printed box, ever.** PETG/ASA isn't flame-rated.
- **MIG tips:** hand-tight; replace when the bore wears oval.
- **Don't swap T8×2 for T8×8** (the wire would drop into the foam at power-off).
- **Fumes and fire:** extraction on every cut. Never leave a hot wire unattended.
