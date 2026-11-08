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

**Buying in the USA** (prices checked 2026-11-07, links in §2; excluding shipping and sales tax):

| Build | ★ Recommended mix | All budget picks | All quality picks |
|---|---|---|---|
| **Variant A (4x board)** | **≈ $1,610** | ≈ $1,790 | ≈ $3,000 |
| **Variant B (6x + 4× DM542T)** | **≈ $1,780** | ≈ $1,990 | ≈ $3,210 |
| Riden RD6006 option (net) | ≈ +$125 | | |

- **★ Recommended mix:** the quality source where fakes or safety matter (Mean Well PSUs, Crydom SSR, E-stop, gold switches, drivers, controller board, WAGO, USB isolator, meter, motors, NiCr), and the cheaper source everywhere else.
- **"All budget" costs more than the mix:** on several lines the Amazon "budget" pack is pricier than Digi-Key for the exact quantity.
- **"All quality"** is dominated by genuine HIWIN rails (≈ $670 vs ≈ $190 for clones) and igus chain cable. Clones are fine for this machine's tiny loads.
- **Why the US price is higher than the ≈ $990 (A) / ≈ $1,130 (B) line estimates in §2:**
  - The estimates assume AliExpress per-unit pricing.
  - US retail sells packs and spools (100 T-nuts, a 25 ft wire spool, 10 glands), so you pay for spares.
  - A few lines share one purchase (one red/black spool covers CB5, CB16 and VB5; one ferrule kit covers CB11 and VB6), so the mix total double-counts ≈ $30–50.
- **To get closer to the estimate:** order the generic items (cable, glands, T-nuts, brackets, belts, pulleys, heat-shrink, standoffs) from AliExpress in one cart, and keep the ★ quality picks for the safety and fake-prone parts. Expect ≈ $1,250–1,350 for A and 2–4 weeks of shipping.

| Option | ≈ USD | ≈ EUR |
|---|---|---|
| Tighter (section 2.12): printed plates, hanging weight, no dummy load | −≈ 45 | −≈ 41 |
| Genuine Schneider E-stop + ZBE1026 gold block (vs a generic 3-NC + separate gold block) | +≈ 60 | +≈ 55 |

**Why not $600?** Early estimates (including wingcut's `docs/hardware-plan.md`) priced only the big parts. Counted honestly, about $250 more goes on:
- fasteners and enclosure hardware,
- ferrules, lugs, heat-shrink and PE bonding,
- chain-rated cable and drag chains,
- a steel mains box, terminals and glands,
- the USB isolator.

Two independent audits are behind this list ([audit](audit.md)). Going below it means a plywood/drawer-slide machine with a ~1 m wire.

The §2 "≈ USD line" column is that AliExpress-level estimate (A ≈ $990, B ≈ $1,130). The real US prices per source are in the last column, with the ★ pick marked.

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

**Where to buy (US).** Each line has two links, checked on 2026-11-07 (prices change):
- **Q** = quality pick: authorised distributor or genuine brand.
- **B** = budget alternative: decent, but check reviews and specs when it arrives.
- **★** = the pick I recommend for that line: Q where fakes or safety matter (PSUs, SSR, E-stop, switches, drivers, boards, WAGO, isolator, meter), otherwise the cheaper one.

Fake-prone parts (Mean Well PSUs, Crydom SSRs, MGN12 rails, Omron switches) are safest from the Q source. The full list with notes is in [bom.csv](../bom/bom.csv).

Every line has a quantity and an approximate **line total** in USD. Buy **2.1 + 2.2 + (2.3 or 2.4) + 2.5–2.10**. Totals are in 2.11.

### 2.1 Power box: mains, wire power, safety (PW), both variants

| ID | Qty | Part | Spec / example P/N / notes | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| PW1 | 1 | **PSU1: Mean Well LRS-100-24** | 24 V 4.5 A, universal input. [Spec](https://www.meanwell.com/Upload/PDF/LRS-100/LRS-100-SPEC.PDF). Variant B real load ≈3 A, still fine. | 20 | ★ [Q: TRC Electronics (Mean Well distributor)](https://www.trcelectronics.com/products/mean-well-lrs-100-24) $16.48 · [B: Jameco Electronics](https://www.jameco.com/z/LRS-100-24-MEAN-WELL-100-Watt-24V-Single-Output-Enclosed-Power-Supply_2257694.html) $15.00 |
| PW2 | 1 | **PSU2 (wire): Mean Well LRS-150F-36** | 36 V 4.3 A, adj. 32.4–39.6 V, universal input. [Spec](https://www.meanwell.com/Upload/PDF/LRS-150F/LRS-150F-SPEC.PDF). Not the non-F LRS-150 (selector switch). | 27 | ★ [Q: TRC Electronics (Mean Well distributor)](https://www.trcelectronics.com/products/mean-well-lrs-150f-36) $25.51 · [B: Jameco Electronics](https://www.jameco.com/z/LRS-150F-36-MEAN-WELL-154W-36V-4300mA-Single-Output-Switching-Power-Supply-1U-Profile_2257811.html) $22.60 |
| PW3 | 1 | **Isolated DC SSR: Sensata/Crydom DC60S7** (or DC60S5) | Control 3.5–32 VDC (3+/4−); load 3–60 VDC 7 A (1+/2−); t_on 0.1 / t_off 0.3 ms, so 100 Hz PWM is fine. Not the DC60S3 (no margin at 2.7 A). **No no-name "SSR-xxDD".** [RS](https://uk.rs-online.com/web/p/solid-state-relays/7360882) | 50 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/sensata-crydom/DC60S7/221846) $54.16 · [B: Amazon (seller Online Components)](https://www.amazon.com/dp/B00DJUH128) $83.94 |
| PW4 | 1 | SSR heatsink ≤3 K/W + thermal pad | ≈2–3 W | 4 | [Q: Digi-Key](https://www.digikey.com/en/products/detail/sensata-crydom/HS301/2122802) $35.25 · ★ [B: Amazon (Easycargo store)](https://www.amazon.com/dp/B07B3Y2ZNY) $5.99 |
| PW5 | 1 | **E-stop** 22 mm mushroom, latching twist-release, **3 NC** (NC1 L, NC2 N, NC3 FluidNC), ≥10 A/250 VAC, finger-safe | Generic XB2/LA38 3-NC ≈ $15. Genuine Schneider XB5AS8442 (1 NC built in) + 2× ZBE102 ≈ $100. **NC3 must be a gold-plated / low-level contact block** (datasheet min. load ≤ 5 V / 1 mA), e.g. **Schneider ZBE1026** (gold-flashed). On variant A it switches **< 1 mA** (plain pull-up input), and silver contacts give random E-stops mid-cut. On B (≈12 mA opto input) silver is acceptable, but gold is still better. | 25 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/schneider-electric/XB5AS8442/17179244) $127.67 · [B: Amazon (genuine Schneider via 3rd-party sellers)](https://www.amazon.com/dp/B07JFN2LJW) $64.93 |
| PW6 | 1 | IEC C14 inlet with switch + 5×20 fuse holder | | 5 | [Q: Digi-Key](https://www.digikey.com/en/products/detail/schurter-inc/DD11-0111-1111/1646862) $16.04 · ★ [B: Amazon (Antrader store)](https://www.amazon.com/dp/B081VD1NNT) $11.99 |
| PW7 | 5 | F1 mains fuses 5×20 slow-blow | **T3.15 A** (230 V) / **T6.3 A** (115 V) | 3 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/schurter-inc/0034-3125/639703) $4.00 · [B: Amazon (BOJACK)](https://www.amazon.com/dp/B07X1KD6WS) $6.99 |
| PW8 | 1 | IEC C13 mains cord, local plug | | 5 | [Q: Amazon (sold by Amazon.com)](https://www.amazon.com/dp/B000067SLV) $8.92 · ★ [B: Amazon (sold by Amazon.com)](https://www.amazon.com/dp/B07BBTBNR7) $7.99 |
| PW9 | 2 | **F2:** inline ATO holder + 5 A fuses (24 V). **F3:** inline **5×20 holder + T4 A 250 V** fuses (wire; ATO blades are only 32 V rated). 3 spares each. | | 6 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/littelfuse-inc/01500274Z/29453) $16.29 · [B: Amazon (Wave One Marine / DIGITEN / BOJACK)](https://www.amazon.com/dp/B09F1VQPFC) $23.97 |
| PW10 | 1 | **DC panel meter V/A, self-powered from the measured line: PZEM-031 type (6.5–100 V, built-in 20 A shunt, 0.01 A resolution)** | Wire current. Must read **0.00 A** after M5, which is the shorted-SSR check. Never power it from 24 V. | 7 | ★ [Q: Amazon (HiLetgo store)](https://www.amazon.com/dp/B079JVGRSL) $14.99 · [B: AliExpress](https://www.aliexpress.us/item/3256809999186422.html) $6.54 |
| PW11 | 1 | **Dummy load 22 Ω 100 W aluminium-clad** | Wire-circuit tests (6.3); screwed to the plate | 8 | [Q: Digi-Key](https://www.digikey.com/en/products/detail/te-connectivity-passive-product/HSC10022RJ/1149656) $18.82 · ★ [B: AliExpress](https://www.aliexpress.us/item/3256806980591158.html) $0.82 |
| PW12 | 1 | **Steel enclosure ≈ 400 × 300 × 150 mm** with mounting plate ≈ 360 × 260, PE studs on body + lid | PSUs 308 × 97 + DIN band + SSR row fit. Lay it out first. | 40 | [Q: Amazon (VEVOR store, ships from Amazon)](https://www.amazon.com/dp/B09247D9LH) $53.62 · ★ [B: Amazon (QLYYOPSK, sold by Imperial Palace USA)](https://www.amazon.com/dp/B0DKXNGV5Y) $45.99 |
| PW13 | 2 | Vent grills / louvres | Low intake, high exhaust (PSUs are convection-cooled) | 4 | [Q: Amazon (nVent Hoffman, seller Megamart USA)](https://www.amazon.com/dp/B07DMS5W2M) $124.54 · ★ [B: Amazon (Raneped, sold by Otto-Pro)](https://www.amazon.com/dp/B0FCM6Y7DP) $14.70 |
| PW14 | 1 set | DIN rail 35 × 300 + **14 feed-through terminals 2.5 mm²** + **12-way PE busbar** + jumpers + end stops + markers | Buses L, N, +24 V out, 0 V, wire+; one PE conductor per clamp | 20 | [Q: Amazon (International Connector store)](https://www.amazon.com/dp/B07NVVP9X7) $28.99 · ★ [B: Amazon (Erayco) + AliExpress](https://www.amazon.com/dp/B0BX2SDSQC) $21.08 |
| PW15 | 7 | Cable glands: **2× M16 (4.5–10 mm)** for PB-24 and PB-SIG, **2× M12 (2–5 mm)** for W-HR and W-HT (or sleeve the leads with adhesive heat-shrink), **1× M12 (3–6.5 mm)** for PE, 2 spare | | 4 | [Q: Digi-Key](https://www.digikey.com/en/products/detail/lapp/S2509/11200370) $19.93 · ★ [B: Amazon (ToolRise)](https://www.amazon.com/dp/B0F387JHTM) $13.50 |
| PW16 | 2 | **Freewheel diode UF5404** (3 A 400 V) | 1 + spare | 1 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/vishay-general-semiconductor-diodes-division/UF5404-E3-54/2217932) $2.98 · [B: Amazon (Chanzon)](https://www.amazon.com/dp/B079KDYNKT) $6.98 |
| PW17 | 1 kit | Enclosure hardware: 10× M4×10, 14× M4 nuts, 6 serrated washers M4/M5, 8× M3×5 for the PSUs (**max 4 mm into the PSU**) | DIN rail, SSR/heatsink, dummy load, PE studs, PSUs | 4 | [Q: Amazon (Mywish store)](https://www.amazon.com/dp/B0CQWYFTXC) $17.99 · ★ [B: Amazon (SVLING)](https://www.amazon.com/dp/B0GSDRXGHR) $9.99 |

### 2.2 Controller side, both variants (CC)

| ID | Qty | Part | Spec / notes | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| CC1 | 1 | **USB isolator ADuM3160 (full-speed 12 Mbit/s), ≥1.5 kV, boxed**, e.g. DSD TECH SH-G01A. Check its PC-side plug (USB-A male or USB-B) before buying CC5. | Between PC and controller. Full speed is all the board's USB-serial chip uses. The board must be powered from 24 V: the isolator's output can't run it. | 12 | ★ [Q: Amazon (DSD TECH Direct)](https://www.amazon.com/dp/B093LKN3YH) $16.99 · [B: Amazon (EC Buying)](https://www.amazon.com/dp/B0BXDKHNZN) $13.99 |
| CC2 | 5 | **Gold-contact roller microswitches Omron D2F-01L3** (4 + spare) | Low-current inputs need gold contacts ([Omron](https://omronfs.omron.com/en_US/ecb/products/pdf/en-ss.pdf)) | 13 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/aratas-formerly-omron-components/D2F-01L3/368448) $11.75 · [B: AliExpress](https://www.aliexpress.us/item/2255799885023469.html) $8.55 |
| CC3 | 10 | 100 nF ceramic capacitors 50 V | Across each limit and estop input at the board | 1 | [Q: Digi-Key](https://www.digikey.com/en/products/detail/kemet/C320C104K5R5TA/818040) $9.61 · ★ [B: Amazon (BOJACK)](https://www.amazon.com/dp/B07X5XTDPB) $6.99 |
| CC4 | 1 | **Adafruit #4218 USB-C round panel-mount extension, 30 cm** (Ø22 mm hole), data-capable | Board USB-C → case wall | 6 | [Q: Adafruit](https://www.adafruit.com/product/4218) $9.95 · ★ [B: AliExpress](https://www.aliexpress.us/item/3256805321247540.html) $3.55 |
| CC5 | 1 | USB-A ↔ USB-B 0.5 m (PC ↔ isolator, to match your isolator) + USB-A ↔ USB-C **data** cable 2 m (isolator ↔ case bulkhead) | | 7 | [Q: Amazon (Monoprice / AnkerDirect)](https://www.amazon.com/dp/B009GUVZOK) $12.94 · ★ [B: Amazon (Monoprice / FEMORO)](https://www.amazon.com/dp/B0FP1BX6FB) $10.44 |
| CC6 | 1 | U.FL → SMA bulkhead pigtail + 2.4 GHz antenna | Usually included with the board; else buy. **Never power the board without it.** | 4 | [Q: Adafruit + Digi-Key](https://www.adafruit.com/product/851) $16.86 · ★ [B: Amazon (DAMGOO)](https://www.amazon.com/dp/B0GDJTDMRR) $5.98 |
| CC7 | 1 kit | Printed-box hardware: M3×5.7 heat-set inserts (10 per case, +12 for the rack), M3×6/×8 screws, M4×30 + nuts (fan), M5×10 + washers + T-nuts (4 per box). Exact list: [enclosure/README](../enclosure/README.md) §3 | | 6 | [Q: Amazon (ruthex / Boeray)](https://www.amazon.com/dp/B08BCRZZS3) $17.98 · ★ [B: Amazon (Moicstiy / Boeray)](https://www.amazon.com/dp/B0DQL4ZSCP) $13.98 |
| CC8 | 0.5 kg | PETG or ASA filament | Controller case (B needs VB9 too) | 10 | [Q: Amazon (Polymaker LLC)](https://www.amazon.com/dp/B0FG3HMCVY) $15.19 · ★ [B: Amazon (ELEGOO Official US)](https://www.amazon.com/dp/B0D41Y3WWZ) $11.69 |
| CC9 | 3 | WAGO 221-415 lever connectors (5 conductors each) | Shield drains in the case, linked with a 0.5 mm² GN/YE jumper (A: 9 drains; B: 6 + rack link). B also needs VB8. | 3 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/wago-corporation/221-415/13549457) $3.51 · [B: Amazon (Peppy Products)](https://www.amazon.com/dp/B0CJ5QF4Z2) $12.45 |

### 2.3 Variant A: FluidNC 4x (VA)

| ID | Qty | Part | Spec / notes | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| VA1 | 1 | **FluidNC 4x CNC Controller v1.1 (ESP32 + 4× TMC2209)** | Bart Dring. [Elecrow $49](https://www.elecrow.com/4x-cnc-controller-integrated-esp32-and-tmc2209.html), **out of stock 2026-11-05**: click "notify me", or build variant B. | 49 | ★ [Q: Elecrow (Bart Dring partner store)](https://www.elecrow.com/4x-cnc-controller-integrated-esp32-and-tmc2209.html) $49.00 · [B: Tindie (Bart Dring, River Forest IL)](https://www.tindie.com/products/33366583/4x-cnc-controller-integrated-esp32-and-tmc2209) $49.00 |
| VA2 | 1 | **80 × 80 × 25 mm 24 V fan** (≈0.1 A) | In the case lid, blowing onto the on-board drivers (lid grille = guard) | 5 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/sunon-fans/MF80252V1-1000U-A99/6198743) $7.74 · [B: Amazon (GDSTIME official store)](https://www.amazon.com/dp/B00N1Y3T9G) $8.99 |
| VA3 | 12 | Cable glands for the case: **10× M16 × 1.5 (4.5–10 mm)** (4 motor, 4 limit, PB-24, PB-SIG) + 2 spare | | 6 | [Q: Digi-Key](https://www.digikey.com/en/products/detail/altech-corporation/5308-951-SET/21378719) $16.44 · ★ [B: Amazon (uxcell store)](https://www.amazon.com/dp/B08K8J8242) $9.99 |

### 2.4 Variant B: FluidNC 6x + DM542T (VB)

| ID | Qty | Part | Spec / notes | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| VB1 | 1 | **FluidNC 6x CNC Controller, integrated ESP32** (v1.2+) | Bart Dring. 12–30 V, external-driver outputs only, CP2102 USB-C. [Elecrow $49](https://www.elecrow.com/6x-cnc-controller-for-fluidnc.html) / [Tindie](https://www.tindie.com/products/33366583/6x-cnc-controller-for-fluidnc-integrated-esp32/) | 49 | ★ [Q: Elecrow (Bart Dring partner store)](https://www.elecrow.com/6x-cnc-controller-for-fluidnc.html) $49.00 · [B: Tindie (Bart Dring, US)](https://www.tindie.com/products/33366583/6x-cnc-controller-for-fluidnc-integrated-esp32/) $75.00 |
| VB2 | 4 | **Stepper driver StepperOnline DM542T V4.0** | 18–50 VDC, differential PUL±/DIR±/ENA±, **S2 selector → 5 V** (ships at 24 V). [Manual](https://forum.duet3d.com/assets/uploads/files/1684504031141-dm542t_v4.0.pdf). Not the DM320T (common-anode inputs). | 108 | ★ [Q: StepperOnline (omc-stepperonline.com, US warehouse)](https://www.omc-stepperonline.com/digital-stepper-driver-1-0-4-2a-20-50vdc-for-nema-17-23-24-stepper-motor-dm542t) $97.04 · [B: StepperOnline (same page, China warehouse)](https://www.omc-stepperonline.com/digital-stepper-driver-1-0-4-2a-20-50vdc-for-nema-17-23-24-stepper-motor-dm542t) $78.60 |
| VB3 | 1 + 1 | **60 × 60 × 25 mm 24 V fan** (6x case lid) + **optional 80 × 80 × 25 mm 24 V fan** (rack end wall) | The rack also works as a chimney without its fan | 8 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/sunon-fans/MF60252V1-1000U-A99/6198718) $20.44 · [B: Amazon (GDSTIME official store)](https://www.amazon.com/dp/B013HN7XEM) $21.98 |
| VB4 | 4 × 0.6 m | Step/dir cables 6x → rack: 4-core shielded 0.25 mm² (or TRVVP 4×0.3), one per driver | STEP, DIR, EN, GND | 5 | ★ [Q: igus (igus.com US)](https://www.igus.com/product/CF240?artnr=CF240.02.04) $13.44 · [B: Amazon (WJRZA store)](https://www.amazon.com/dp/B0D9JY3MC4) $16.99 |
| VB5 | 3 m each | 1.0 mm² red/black | 24 V from the rack WAGOs to each DM542T (own pair per driver, inside the rack) | 4 | [Q: Remington Industries (US)](https://www.remingtonindustries.com/hook-up-wire/hook-up-wire-18-awg-600v-pvc-stranded-10-colors-7-sizes-available/) $30.66 · ★ [B: Amazon (Mziklr)](https://www.amazon.com/dp/B0FH4XTP88) $9.99 |
| VB6 | 1 set | Twin ferrules 2×0.5 mm² | PUL−/DIR−/ENA− jumpers | 2 | [Q: AutomationDirect](https://www.automationdirect.com/adc/shopping/catalog/wire_-a-_cable_termination/wire_end_connectors/insulated_ferrules/v30ae001134) $28.50 · ★ [B: Amazon (HKS)](https://www.amazon.com/dp/B0GWZW5VHR) $9.99 |
| VB7 | 21 | Cable glands: 6x case **6× M16 (4.5–10)** (4 limit, 24 V in, PB-SIG) + **4× M12** (step/dir out); rack **6× M16** (4 motors, PB-24 in, 24 V out to the 6x) + **4× M12** (step/dir in); 1 spare | | 10 | [Q: Digi-Key + AutomationDirect](https://www.digikey.com/en/products/detail/altech-corporation/5308-951-SET/21378719) $24.31 · ★ [B: Amazon (uxcell + Dimove)](https://www.amazon.com/dp/B08K8J8242) $15.78 |
| VB8 | 4 | WAGO 221-415 (rack): +24 V bus, 0 V bus (2 linked each) | 7 conductors per bus: PB-24, 4 drivers, 6x feed, rack fan | 4 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/wago-corporation/221-415/13549457) $4.68 · [B: Amazon (WAGO store, sold by DE Supply)](https://www.amazon.com/dp/B01M6Y2UEK) $33.90 |
| VB9 | 0.5 kg | Extra PETG/ASA for the 6x case + rack (≈0.9 kg total) | | 10 | [Q: Amazon (Polymaker official store)](https://www.amazon.com/dp/B0FG3HMCVY) $15.19 · ★ [B: Amazon (OVERTURE official store)](https://www.amazon.com/dp/B07PGYHYV8) $13.22 |

**Riden option (R), +≈$75 net** (+$82 before dropping PW10):
- **R1:** Riden RD6006 USB version (≈$65).
- **R2:** second ADuM3160 USB isolator (≈$12).
- **R3:** LRS-150F-48 instead of PW2 (same price).
- **R4:** USB cable + 1 M16 gland (≈$5). Pass the device end in from outside, or use a split USB grommet: a USB-A plug won't pass an M16 gland.
**Riden option: where to buy (US):** R1: [Q: Amazon (RuiDeng Official Store)](https://www.amazon.com/dp/B09B9KJ39R) $94.00 · ★ [B: AliExpress](https://www.aliexpress.us/item/3256806709143589.html) $91.60; R2: [Q: Amazon (DSD TECH Direct)](https://www.amazon.com/dp/B093LKN3YH) $16.99 · ★ [B: Amazon (EC Buying)](https://www.amazon.com/dp/B0BXDKHNZN) $13.99; R3: [Q: TRC Electronics (Mean Well distributor)](https://www.trcelectronics.com/products/mean-well-lrs-150f-48) $25.51 · ★ [B: Jameco Electronics](https://www.jameco.com/z/LRS-150F-48-MEAN-WELL-158W-48V-3300mA-Single-Output-Switching-Power-Supply-1U-Profile_2257820.html) $22.60; R4: [Q: Amazon (Monoprice) + Digi-Key (LAPP)](https://www.amazon.com/dp/B07KFQH2ZF) $6.89 · ★ [B: Amazon (Monoprice)](https://www.amazon.com/dp/B07KFQH2ZF) $4.09
- **Mounting:** RD6006 in a cut-out in the power-box lid (its front-panel size; check the module's drawing).
- Drop PW10: the Riden shows V/A, and wingcut watches the current.

### 2.5 Cables and wiring consumables (CB), both variants

| ID | Qty | Part | Spec / use | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| CB1 | 18 m | **TRVVP (drag-chain) shielded 4×0.5 mm²** | 4 motor runs (15 m) + PB-SIG power box ↔ controller (3 m) | 26 | [Q: igus (igus.com US)](https://www.igus.com/product/CF78_UL?artnr=CF78.UL.05.04) $153.40 · ★ [B: AliExpress (TRVVP listing, 706 sold, 5.0 stars)](https://www.aliexpress.us/item/3256804585223639.html) $24.01 |
| CB2 | 15 m | **TRVVP shielded 3×0.3 mm²** | 4 limit runs | 14 | [Q: igus (igus.com US)](https://www.igus.com/product/CF240?artnr=CF240.03.03) $82.50 · ★ [B: AliExpress (same TRVVP listing as CB1)](https://www.aliexpress.us/item/3256804585223639.html) $24.01 |
| CB3 | 5 m red + 6 m black | Silicone wire 1.0 mm² (18 AWG), fine-strand | Hot-wire leads W-HR (red), W-HT (black) | 10 | ★ [Q: Amazon (BNTECHGO official store)](https://www.amazon.com/dp/B07HGTKQ89) $13.98 · [B: Amazon (TUOFENG)](https://www.amazon.com/dp/B07FMWNF3J) $16.99 |
| CB4 | 2 m each | 1.0 mm² H07V-K brown, blue, green/yellow (US: **UL1015 600 V 18 AWG**; earth = green) | Mains inside the power box | 5 | [Q: Remington Industries (US)](https://www.remingtonindustries.com/hook-up-wire/hook-up-wire-18-awg-600v-pvc-stranded-10-colors-7-sizes-available/) $45.99 · ★ [B: Amazon (BNTECHGO official store)](https://www.amazon.com/dp/B09X46HDZG) $19.48 |
| CB5 | 3 m each | 1.0 mm² (US: 18 AWG) red, black, orange | 24 V and wire (orange) circuits inside the power box | 6 | [Q: Remington Industries (US)](https://www.remingtonindustries.com/hook-up-wire/hook-up-wire-18-awg-600v-pvc-stranded-10-colors-7-sizes-available/) $45.99 · ★ [B: Amazon (BNTECHGO official store)](https://www.amazon.com/dp/B09X46HDZG) $19.48 |
| CB6 | 3 m each | 0.5 mm² red, black | Fans, internal jumpers | 3 | [Q: Remington Industries (US)](https://www.remingtonindustries.com/hook-up-wire/hook-up-wire-20-awg-600v-pvc-stranded-10-colors-7-sizes-available/) $28.92 · ★ [B: Amazon (BNTECHGO official store)](https://www.amazon.com/dp/B07HGTHTKT) $12.48 |
| CB7 | 1 set | 0.25 mm² hook-up, 4 colours | Caps, short internal links | 4 | [Q: Remington Industries (US)](https://www.remingtonindustries.com/hook-up-wire/24-awg-ul1015-hook-up-wire-600v-pvc-stranded-10-colors-7-sizes-available/) $49.80 · ★ [B: Amazon (CBAZY)](https://www.amazon.com/dp/B073QHZK55) $14.85 |
| CB8 | 5 m + 4 m | 1.5 mm² (US: **14 AWG**) GN/YE (US: green) (frame bond, lid strap, static frame jumpers, PELV bond) + 0.5 mm² GN/YE 4 m (rail and carriage bonds) + 6 M5 + 10 M3 ring lugs + serrated washers | PE bonding | 7 | [Q: Remington Industries (US)](https://www.remingtonindustries.com/hook-up-wire/hook-up-wire-14-awg-600v-pvc-stranded-10-colors-7-sizes-available/) $34.50 · ★ [B: Amazon (BNTECHGO + Vifmy)](https://www.amazon.com/dp/B06XDNM1P5) $24.97 |
| CB9 | 2 | **Drag chain 15×20 mm inner, bend radius ≥ R48, openable, 1 m**, with end brackets | One per tower along X | 14 | ★ [Q: igus (igus.com US)](https://www.igus.com/product/series-Z08?artnr=Z08.20.048.0) $70.00 · [B: Amazon (GAVATKLKCP)](https://www.amazon.com/dp/B0FV96P51C) $77.70 |
| CB10 | 1 set | Spiral wrap 8–10 mm (3 m) + 10 P-clips | Head-lead loops, power-box lid harness | 5 | [Q: MarineEngine.com (Ancor) + Amazon](https://www.marineengine.com/boat-accessories/electrical/452381) $23.88 · ★ [B: Amazon (uxcell + ISPINNER)](https://www.amazon.com/dp/B07Z2VBSJ2) $19.98 |
| CB11 | 1 set | Ferrules 0.25–1.5 mm² (+ twin) | Every screw terminal | 10 | ★ [Q: Ferrules Direct (US specialist)](https://www.ferrulesdirect.com/products/sk2210tw) $18.50 · [B: Amazon (Preciva store)](https://www.amazon.com/dp/B0CDBKY8HK) $23.98 |
| CB12 | 1 set | Insulated ring lugs M4/M5 | Tip blocks, PE | 4 | ★ [Q: Digi-Key](https://www.digikey.com/en/products/detail/te-connectivity-amp-connectors/2-36160-1/289206) $3.68 · [B: Amazon (smseace)](https://www.amazon.com/dp/B0CHR87N2D) $8.99 |
| CB13 | 1 set | Heat-shrink incl. adhesive-lined | Motor/limit splices | 6 | [Q: Digi-Key](https://www.digikey.com/en/products/detail/qualtek/Q5-3X-QK1-01-6IN-114/3692964) $45.54 · ★ [B: Amazon (XHF official store)](https://www.amazon.com/dp/B0DC5YN5CD) $9.99 |
| CB14 | 1 set | Cable ties, adhesive mounts, 10 T-slot tie mounts, labels | Routing | 8 | [Q: Digi-Key](https://www.digikey.com/en/products/detail/panduit-corp/TM2S8-C0/2671108) $7.35 · ★ [B: AliExpress](https://www.aliexpress.us/item/3256809694138608.html) $1.09 |
| CB15 | 1 | Solder | Splices | 3 | [Q: Adafruit](https://www.adafruit.com/product/5897) $9.25 · ★ [B: Amazon (MAIYUM)](https://www.amazon.com/dp/B075WB98FJ) $8.99 |
| CB16 | 3.5 m | **2-core 2×1.0 mm² red/black DC cable** (PVC or silicone, not grey mains cable) | **PB-24** (3 m) + B: rack → 6x (0.5 m). Label both ends "24 V DC". | 4 | [Q: Amazon (BNTECHGO official store)](https://www.amazon.com/dp/B0779QRR58) $14.98 · ★ [B: Amazon (Mziklr)](https://www.amazon.com/dp/B0FH4XTP88) $9.99 |

### 2.6 Frame (FR): 20-series T-slot, 6 mm slot

| ID | Qty | Part | Spec / use | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| FR1 | 2 | **2040 × 1900 mm** | Base rails B1 (front), B2 (back), standing (40 tall) | 43 | ★ [Q: TNUTZ](https://www.tnutz.com/product/exm-2040/) $39.48 · [B: Amazon (VEVOR store, ships from Amazon)](https://www.amazon.com/dp/B0F4823SDV) $50.36 |
| FR2 | 2 | **2040 × 1250 mm** | X-beams (root, tip), standing. **Tap both end holes M5.** | 28 | ★ [Q: TNUTZ](https://www.tnutz.com/product/exm-2040/) $26.48 · [B: Amazon (VEVOR store)](https://www.amazon.com/dp/B0F4823SDV) $50.36 |
| FR3 | 2 | **2040 × 1250 mm** | Bed supports C1, C2 | 28 | ★ [Q: TNUTZ](https://www.tnutz.com/product/exm-2040/) $26.48 · [B: Amazon (PENGLONG)](https://www.amazon.com/dp/B0DSV2JWQ1) $75.99 |
| FR4 | 2 | **2040 × 500 mm** | Tower posts. **Tap both ends M5.** | 12 | ★ [Q: TNUTZ](https://www.tnutz.com/product/exm-2040/) $10.88 · [B: Amazon (VEVOR store)](https://www.amazon.com/dp/B0F4823SDV) $0.00 |
| FR5 | 24 | 2040 cast corner brackets + M5 screws | 8 X crossings, 8 C crossings, 4 posts, 4 for P6, spares 0 | 12 | [Q: TNUTZ](https://www.tnutz.com/product/cbk-020-a/) $36.00 · ★ [B: Amazon (JCSPBYL)](https://www.amazon.com/dp/B0DQDT9K64) $12.99 |
| FR6 | 150 | M5 drop-in T-nuts | ≈114 used | 11 | [Q: TNUTZ](https://www.tnutz.com/product/db-020-m5/) $75.00 · ★ [B: Amazon (Xiexxinhai)](https://www.amazon.com/dp/B0DX7B5ZNN) $19.98 |
| FR7 | 100 | M3 drop-in T-nuts | MGN12 rails (≈64 used) | 6 | [Q: TNUTZ](https://www.tnutz.com/product/db-020-m3/) $50.00 · ★ [B: Amazon (Mriuuod US)](https://www.amazon.com/dp/B0DPK1TXBQ) $9.49 |
| FR8 | 1 | **Bed** 18 mm MDF/ply 1300 × 700, sealed 2× PU | | 25 | [Q: The Home Depot](https://www.homedepot.com/p/309177124) · ★ [B: Lowe's](https://www.lowes.com/pd/MDF-Actual-0-745-in-x-48-92-in-x-8-07-ft/1000344499) |
| FR9 | 4 | Rubber pads | Feet | 4 | ★ [Q: Digi-Key (3M)](https://www.digikey.com/en/products/detail/3m/SJ-5023-BROWN/3866055) $2.08 · [B: Amazon (Rrina)](https://www.amazon.com/dp/B0B3MLC5FR) $9.99 |
| FR10 | 1 set | Foam hold-down: 4–6 kg steel offcuts + pins/carpet tape + 15–20 mm scrap-foam spacer strips | | 5 | [Q: Amazon (Scotch/3M, sold by Amazon)](https://www.amazon.com/dp/B003B4NUFE) $5.99 · ★ [B: Amazon (Kraftex)](https://www.amazon.com/dp/B0G1YV418T) $5.99 |
| FR11 | 1 | **Box mounting rail:** 2040 offcut lying flat, **250 mm (A) / 480 mm (B)**, + 4 M5 T-nuts + 2 wood screws/clamps to the bench | Printed boxes bolt to it, beside the power box | 5 | ★ [Q: TNUTZ](https://www.tnutz.com/product/exm-2040/) $5.18 · [B: Amazon (VEVOR store)](https://www.amazon.com/dp/B0F4823SDV) $25.18 |

### 2.7 Motion and drive (M, L, D)

| ID | Qty | Part | Spec / use | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| M1 | 5 | **NEMA17 17HS19-2004S1** (4 + spare) | 2.0 A, 59 Ncm, 1 m lead. Black/green = coil A, red/blue = coil B (≈1.4 Ω, verify). [StepperOnline](https://omc-stepperonline.com/nema-17-bipolar-59ncm-84oz-in-2a-42x48mm-4-wires-w-1m-cable-and-connector.html) | 42 | ★ [Q: StepperOnline (US warehouse)](https://www.omc-stepperonline.com/nema-17-bipolar-59ncm-84oz-in-2a-42x48mm-4-wires-w-1m-cable-connector-17hs19-2004s1) $65.45 · [B: Amazon (STEPPERONLINE store, sold by StepperOnline)](https://www.amazon.com/dp/B00QEYADRQ) $55.00 |
| L1 | 2 | **MGN12 rail 1200 mm + 2× MGN12H blocks** | Chord axes. Clones are fine at these loads. Genuine HIWIN comes in 1195 mm and costs ≈5×. | 64 | [Q: Motion Constrained (genuine HIWIN)](https://motionconstrained.com/store/hiwin-linear-guides/mgn-series/mgn-rails-only/hiwin-mgnr12r-linear-guideway-rail/) $471.44 · ★ [B: Amazon (Mssoomm)](https://www.amazon.com/dp/B08RWDYYKR) $146.37 |
| L2 | 2 | **MGN12 rail 400 mm + 1× MGN12H** | Vertical axes (HIWIN: 395 mm) | 28 | [Q: Motion Constrained (genuine HIWIN)](https://motionconstrained.com/store/hiwin-linear-guides/mgn-series/mgn-rails-only/hiwin-mgnr12r-linear-guideway-rail/) $201.04 · ★ [B: Amazon (uxcell / Amadeo City)](https://www.amazon.com/dp/B0D54LQ8QG) $40.29 |
| L3 | 1 | Lithium grease | | 3 | ★ [Q: Amazon (Permatex, sold by Amazon)](https://www.amazon.com/dp/B000HBNV58) $3.99 · [B: Amazon (AstraVox)](https://www.amazon.com/dp/B0DMK9ZM3N) $7.99 |
| D1 | 10 m | GT2 belt 6 mm, glass-fibre | 2 × ≈2.6 m | 8 | [Q: ServoCity](https://www.servocity.com/2mm-pitch-gt2-timing-belt-6mm-width-5-meter-cut-length/) $29.98 · ★ [B: Amazon (Zeelo-US)](https://www.amazon.com/dp/B08974S1CC) $13.99 |
| D2 | 3 | GT2 20T pulley, 5 mm bore | 2 + spare | 4 | [Q: ServoCity](https://www.servocity.com/2mm-pitch-gt2-pinion-timing-pulley-5mm-bore-20-tooth/) $23.97 · ★ [B: Amazon (WINSINN)](https://www.amazon.com/dp/B077GNZK3J) $6.99 |
| D3 | 3 | GT2 20T toothed idler, 5 mm bore | 2 + spare | 4 | [Q: Printed Solid (LDO)](https://www.printedsolid.com/products/ldo-2gt-20t-idler-with-5mm-bore-for-6mm-belt) $11.70 · ★ [B: Amazon (WINSINN)](https://www.amazon.com/dp/B07BPGYX3G) $8.99 |
| D4 | 4 | Steel NEMA17 L-bracket | 2 chord motors + 2 idler brackets | 10 | ★ [Q: StepperOnline (US warehouse)](https://www.omc-stepperonline.com/nema-17-bracket-for-stepper-motor-and-geared-stepper-motor-alloy-steel-bracket-st-m1) $16.04 · [B: Amazon (HenGu)](https://www.amazon.com/dp/B09372B2D1) $19.98 |
| D5 | 2 | M5 × 40 bolt + 4 washers + nylock | Idler axles | 2 | ★ [Q: Bolt Depot](https://boltdepot.com/Product-Details?product=6206) $1.02 · [B: The Home Depot (Everbilt)](https://www.homedepot.com/p/204273659) |
| D6 | 4 | GT2 belt clamps | On belt tab P4 | 4 | [Q: ServoCity](https://www.servocity.com/steel-belt-clamp-for-2mm-pitch-gt2-timing-belt-2-pack/) $9.98 · ★ [B: Amazon (3Dman)](https://www.amazon.com/dp/B08XVVQW6G) $7.99 |
| D7 | 2 | **T8×2 (2 mm lead, single start) lead screw 400 mm + flanged brass nut** | Verticals. Not T8×8 (back-drives). | 20 | [Q: ZYLtech (Houston TX)](https://www.zyltech.com/8mm-t8x2-trapezoidal-acme-lead-screw-w-brass-nut-pre-cut-lengths-150mm-2000mm/) $19.30 · ★ [B: Amazon (JRGJ TECH)](https://www.amazon.com/dp/B095MBMQNM) $15.59 |
| D8 | 2 | Flexible coupler 5 → 8 mm | | 4 | [Q: ServoCity](https://www.servocity.com/5mm-to-8mm-flexible-clamping-shaft-coupler/) $13.98 · ★ [B: Amazon (ReliaBot)](https://www.amazon.com/dp/B079J22KX1) $6.99 |
| D9 | 2 | KFL08 flange bearing | Screw bottom | 4 | [Q: Amazon (uxcell / Amadeo City)](https://www.amazon.com/dp/B0DM5KRT23) $7.39 · ★ [B: Amazon (XDGM)](https://www.amazon.com/dp/B0CWXC1BBJ) $6.99 |
| D10 | 2 | T8 nut bracket (22 mm flange) | On head plate. Measure its nut-centre height (4.3). | 4 | [Q: Amazon (SEIWEI, sold by Revotool)](https://www.amazon.com/dp/B0BN3BHGD4) $18.98 · ★ [B: Amazon (YEJMKJ)](https://www.amazon.com/dp/B0GZZSHY7X) $16.18 |

### 2.8 Wire heads, wire, tension (H)

| ID | Qty | Part | Spec / use | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| H1 | 1 reel | **Ni80Cr20 0.4 mm, 10–20 m** | ≈8.7 Ω/m → ≈12.6 Ω at 1.45 m | 10 | ★ [Q: Amazon (Remington Industries brand store)](https://www.amazon.com/dp/B07622D2KY) $18.18 · [B: Amazon (Master Wire Supply)](https://www.amazon.com/dp/B07CHVKKCQ) $8.99 |
| H2 | 10 | **MIG contact tips M6 × 25 for 0.6 mm wire** (CuCrZr) | Guide + current feed | 8 | [Q: Everlast Power Equipment (US)](https://www.everlastgenerators.com/product/24kd-hd-m6-contact-tip-0023-10-pc) $15.00 · ★ [B: Amazon (Startbuymore)](https://www.amazon.com/dp/B0F9PMWMLT) $8.96 |
| H3 | 2 | Tip blocks (from ST5) | 20×20×30 alu: M6 through, M4 lug, 2× M4 mounting | 0 | Made, not bought. Uses 60 mm of the ST5 bar. The US 3/4 in ( |
| H4 | 1 | **FR4/G10 5 mm** (US: 3/16 in = 4.8 mm is fine), 100 × 150 | Insulators | 8 | [Q: Rock West Composites](https://www.rockwestcomposites.com/g10-188-1212.html) $43.99 · ★ [B: Zoro (USA Industrials)](https://www.zoro.com/usa-industrials-g-10-garolite-sheet-316-thick-x-6-wide-x-6-long-bulk-cs-gg10-56/i/G7919683) $12.39 |
| H5 | 2 | POM (Delrin) V-wheel with 625ZZ | Tip-side deflector. Plastic = insulating. | 3 | [Q: Amazon (Official Creality store)](https://www.amazon.com/dp/B09QPG7XGR) $9.99 · ★ [B: Amazon (MKDCHUI)](https://www.amazon.com/dp/B0FL84VWR5) $7.99 |
| H6 | 1 | **Constant-force spring ≈20 N**, ≥150 mm usable extension, drum | McMaster 9293K / Gutekunst. Alternative: 2 kg weight in a 50 mm PVC tube. | 10 | [Q: McMaster-Carr](https://www.mcmaster.com/9293K337) · ★ [B: Home Depot (Charlotte Pipe)](https://homedepot.com/p/Charlotte-Pipe-2-in-x-2-ft-PVC-DWV-Schedule-40-Pipe-PVC072000200HA/100585960) $8.48 |
| H7 | 2 m | Aramid (Kevlar) line 1 mm, ≥50 kg (US: **150 lb**, not 100 lb) | Insulating links | 4 | [Q: Amazon (emma kites store)](https://www.amazon.com/dp/B0184ZGSQ2) $9.95 · ★ [B: Amazon (9KM DWLIFE store)](https://www.amazon.com/dp/B0BYYRZ2SL) $9.25 |
| H8 | 20 | Crimp sleeves 1.0 mm | Wire loops | 2 | [Q: Amazon (HIGOOD)](https://www.amazon.com/dp/B08Q431RP4) $9.99 · ★ [B: Amazon (uxcell)](https://www.amazon.com/dp/B0CWN2TM9C) $6.39 |
| H9 | 4 | Nylon M4 screws + nuts | Root-side anchor | 3 | ★ [Q: Bolt Depot](https://boltdepot.com/Product-Details?product=21906) $2.00 · [B: Amazon (Keadic)](https://www.amazon.com/dp/B0DLM3P24Z) $6.99 |

### 2.9 Fasteners (FX)

| ID | Qty | Part | Use | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| FX1 | ≈150 | M5 button-head DIN 7380, 8/10/12/16 mm | Frame, brackets | 12 | [Q: AFT Fasteners](https://www.aftfasteners.com/m5-0-80-x-10-mm-metric-button-head-cap-screw-coarse-18-8-ss-a2/) $27.03 · ★ [B: Amazon (Glvaner)](https://www.amazon.com/dp/B09B72S5ZT) |
| FX2 | 40 + 10 | M5 washers + nylock | | 3 | ★ [Q: AFT Fasteners](https://www.aftfasteners.com/m5-din-125a-stainless-steel-a2-flat-washers-100-pkg/) $6.24 · [B: Amazon (uxcell)](https://www.amazon.com/dp/B0D9XMMHCS) $12.98 |
| FX3 | ≈200 | M3 socket cap 6–20 mm | Rails, blocks, motors | 8 | ★ [Q: AFT Fasteners](https://www.aftfasteners.com/m3-0-50-x-10-mm-metric-socket-head-cap-screw-coarse-18-8-ss-a2/) $10.54 · [B: Amazon (Socell)](https://www.amazon.com/dp/B0DYNLT9MK) |
| FX4 | 50 | M3 washers | | 2 | ★ [Q: Bolt Depot](https://boltdepot.com/Product-Details?product=4513) $1.45 · [B: Amazon (Zernmiarder)](https://www.amazon.com/dp/B0DK6GQK78) $4.99 |
| FX5 | 30 + 4 | M4 SHCS 8–20 + nuts + **4× M4×12 countersunk DIN 7991** | Tip blocks, lugs | 5 | [Q: AFT Fasteners](https://www.aftfasteners.com/m4-0-70-x-12-mm-metric-socket-head-cap-screw-coarse-18-8-ss-a2/) $17.90 · ★ [B: Amazon (Csxydz)](https://www.amazon.com/dp/B0G4DNJMTD) |
| FX6 | 1 | M5 shoulder bolt Ø6 × 10 | Spring drum | 3 | [Q: McMaster-Carr](https://www.mcmaster.com/92981A100) · ★ [B: Zoro (Zoro Select / Fabory M07111.060.0010)](https://www.zoro.com/zoro-select-shoulder-screw-m5-080-thr-sz-95-mm-thr-lg-10-mm-shoulder-lg-alloy-steel-5-pk-m071110600010/i/G1199012/) $2.89 |
| FX7 | 8 | **M3 × 5** | PSU mounting (max 4 mm into the PSU) | 1 | ★ [Q: Bolt Depot](https://boltdepot.com/Product-Details?product=6377) $0.40 · [B: Amazon (Fullerkreg)](https://www.amazon.com/dp/B07H14FQ2Z) $8.89 |
| FX8 | 8 | M2 × 12 + nuts | D2F switches | 2 | ★ [Q: Bolt Depot](https://boltdepot.com/Product-Details?product=6366) $1.60 · [B: Amazon (Fgruh)](https://www.amazon.com/dp/B0FG2CC91J) $9.99 |
| FX9 | 1 | Thread-locker, medium | Set screws, couplers | 4 | ★ [Q: Amazon (Loctite store)](https://www.amazon.com/dp/B004VODM24) $21.16 · [B: Amazon (Permatex store)](https://www.amazon.com/dp/B0002UEMZ2) $7.16 |
| FX11 | 8 | **M5×25 countersunk DIN 7991** | Bed down into T-nuts in C1/C2 | 1 | ★ [Q: Bolt Depot](https://boltdepot.com/Product-Details?product=6677) $2.00 · [B: Amazon (Fastener Cart)](https://www.amazon.com/dp/B07RYHWS39) $12.21 |
| FX12 | 2 sets | Chain standoff: 2× M5 × 30 mm aluminium spacers (+ 4× **M5×45** screws) + 2020 offcut 100 mm (or 6 mm plate 100 × 40) per tower | Chain fixed end ≥80 mm out from the X-beam, outboard of belt and motor | 4 | [Q: Lyn-Tron (made in USA)](https://www.lyntron.com/10.0mm-aluminum-round-spacer-unplated/pn/AA5008-50-30.0-00) · ★ [B: Amazon (uxcell)](https://www.amazon.com/dp/B0CQ89536M) $8.49 |

### 2.10 Raw stock (ST) and fabricated parts

| ID | Qty | Part | Makes | ≈ USD line | Buy in the US (Q = quality · B = budget) |
|---|---|---|---|---|---|
| ST1 | 2 | 6061 plate 8 mm, 160 × 130 (US imperial: 5/16 in) | P1 | 15 | [Q: Speedy Metals](https://speedymetals.com/pc-2409-8360-516-6061-t651-aluminum-plate.aspx) $75.89 · ★ [B: Amazon (ZOFORTY store)](https://www.amazon.com/dp/B0B4F1BWQ8) $29.99 |
| ST2 | 6 | 6061 plate 6 mm: 2× 80 × 140, 4× 70 × 60 (US imperial: 1/4 in = 6.35 mm; re-measure the P2 stack and D10 height, 4.3) | P2, P3, P6 | 15 | [Q: Speedy Metals](https://speedymetals.com/pc-2408-8360-14-6061-t651-aluminum-plate.aspx) $59.51 · ★ [B: Amazon (ZOFORTY store)](https://www.amazon.com/dp/B0B4DV12NK) $20.99 |
| ST3 | 120 mm | Alu angle 30×30×3 | P4 | 2 | ★ [Q: Speedy Metals](https://speedymetals.com/pc-2182-8344-1-14-x-1-14-angle-6061-t6-aluminum-extruded.aspx) $5.15 · [B: Amazon (SHOUCAN)](https://www.amazon.com/dp/B0CRHKLVC8) $38.99 |
| ST4 | 150 mm | Alu angle 20×20×2 | P5 | 2 | ★ [Q: Speedy Metals](https://speedymetals.com/pc-2180-8344-18-a-x-34-b-x-34-c-angle-6061-t6-aluminum-extruded.aspx) $3.02 · [B: Home Depot (Everbilt)](https://homedepot.com/p/Everbilt-3-4-in-x-3-ft-1-8-in-Thick-Aluminum-Angle-6405/332734017) $11.63 |
| ST5 | 70 mm | 6061 bar 20×20 | Tip blocks | 2 | ★ [Q: Speedy Metals](https://speedymetals.com/pc-2496-8378-34-sq-6061-t6511-aluminum-extruded.aspx) $9.37 · [B: Amazon (SSCZRAI)](https://www.amazon.com/dp/B0F1F8FY4Y) $18.81 |

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

*Line-estimate totals (AliExpress-level pricing). For US retail totals see §0: ★ mix A ≈ $1,610, B ≈ $1,780.*

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
