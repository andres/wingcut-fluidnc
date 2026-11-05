# 02 — Firmware and commissioning (FluidNC 4x + TMC2209, wingcut)

Files: [fluidnc-4x-hotwire.yaml](../config/fluidnc-4x-hotwire.yaml) · [wingcut-machine.toml](../config/wingcut-machine.toml).

Keys checked against **FluidNC v4.1.1** source. **Zero errors** in the v4.1.1 Linux simulator (TMC/I2S swapped for GPIO steppers, as the sim lacks them; `tmc_2209` keys checked against source and Bart's 4x example). Sim: `$32=0`, `$30=1000`, M3/M5 and a G93 XYZA move accepted, ranges X/Z 0–1000, Y/A 10–300.

## ⚠ Read first: hardware points

1. **Board revision trap.** Elecrow sells **v1.1** (front silkscreen; the back one is wrong). TMC UART = **gpio.26/gpio.2**. The older wiki page and `contributed/4x_2209/*.yaml` use gpio.16/**gpio.4** = the v1.1 MOSFET. Use only our YAML. Source: [current 4x wiki](http://wiki.fluidnc.com/en/hardware/official/new-page/4x_CNC_with_esp32) (pinout image `/hardware/4x_with_pinout.png`).
2. **E-stop wipes the driver settings.** The TMC2209s take their config only with motor power on ([wiki](http://wiki.fluidnc.com/en/hardware/official/TMC2209_4_Axis)). If the ESP32 survives an E-stop on USB power, the drivers return with wrong microsteps/current, unnoticed. **Fixed in hardware (audit #1):** a third E-stop NC contact goes to `control: estop_pin: gpio.33`, so FluidNC hard-stops, turns the wire off and stays in alarm even if USB keeps the ESP32 alive. Releasing the E-stop can't restart anything. **Rule: after every E-stop or power loss, RESET → `$MI` → `$H`.** Test (e)3 checks it.
3. **SSR margin (applied).** S1000 ≈ 2.7 A would leave no margin on a DC60S3 (3 A), so the BOM now specifies the **DC60S7** (7 A, [datasheet](https://jinzon.url.tw/pdf/crydom_dc60.pdf)). Keep its heatsink.
4. **No relay:** a shorted SSR keeps the wire hot until E-stop. SSR-blocking test (e) at commissioning and after any wire short; meter not **0.00 A** within 1 s of `M5` → E-stop, replace the SSR.
5. **Cooling:** `run_amps` is **1.0 A** (below the wiki's 1.2 A no-fan limit); the enclosure fan still blows onto the drivers.
6. **Verticals 900 mm/min** (7.5 rev/s) is near a 17HS19's 24 V limit → SpreadCycle (`CoolStep`). Stalls → 600.
7. **Heat numbers.** With SSR drop (≈1.2 V) and leads (≈0.3 Ω), I_full ≈ 2.7 A → S ≈ **550–725** for 2.0–2.3 A, not 490–650. Measure (e).

## Verified 4x v1.1 I/O map

| Function | Board terminal | FluidNC |
|---|---|---|
| X root chord | TB1 (motor 1), TMC addr 0 | step i2so.2, dir i2so.1, dis i2so.0 |
| Y root vertical | TB3 (motor 2), addr 1 | i2so.5 / i2so.4 / i2so.7 |
| Z tip chord | TB4 (motor 3), addr 2 | i2so.10 / i2so.9 / i2so.8 |
| A tip vertical | TB5 (motor 4), addr 3 | i2so.13 / i2so.12 / i2so.15 |
| TMC UART / I2SO | — | uart1 TX gpio.26, RX gpio.2 · BCK 22, DATA 21, WS 17 |
| Limit X (front, min) | Inputs "gpio.36" + Gnd | `limit_neg_pin: gpio.36` |
| Limit Y (top, max) | "gpio.39" + Gnd | `limit_pos_pin: gpio.39` |
| Limit Z (front, min) | "gpio.34" + Gnd | `limit_neg_pin: gpio.34` |
| Limit A (top, max) | "gpio.35" + Gnd | `limit_pos_pin: gpio.35` |
| Wire PWM → SSR | TB10 "VMot" → SSR 3(+); TB10 "gpio.4 (MOSFET)" → SSR 4(−) | `PWM: output_pin: gpio.4` |
| E-stop NC3 | Input gpio.33 + Gnd (+100 nF) | `control: estop_pin: gpio.33` |
| Spare | Input gpio.32; MOSFET gpio.12; 5 V outs gpio.13/14 | unused |

Inputs have **external pull-ups**, closed-to-Gnd = low ([wiki](http://wiki.fluidnc.com/en/hardware/official/new-page/4x_CNC_with_esp32)): NC-to-Gnd is active-high → **no `:pu`, no `:low`**; a broken wire reads triggered. Keep the 4 **StallGuard solder jumpers** (A/Z/Y/X = gpio.35/34/39/36) **open**. Leave the gpio.4/12 **5 V-output** terminals empty (they switch with the MOSFETs; gpio.12 is a strapping pin).

## (a) Flash and upload

1. Antenna on, 24 V polarity checked (no reverse protection). **Mains first** (5V LED), then USB-C.
2. Chrome/Edge → [installer.fluidnc.com](https://installer.fluidnc.com) → install **v4.1.1** (or newer; never v4.0.4, which is marked BAD), *wifi* build, full install.
3. Terminal (115200): `$Sta/SSID=<your-wifi-name>`, `$Sta/Password=<your-wifi-password>` (stored only on the board; never commit them), `$WiFi/Mode=STA>AP`, `$Bye`.
4. WebUI → Flash → upload the YAML → `$Config/Filename=fluidnc-4x-hotwire.yaml` → `$Bye`. No Wi-Fi (e.g. antenna problem in a steel box)? Upload the file over USB in the installer's file manager (installer.fluidnc.com → Files).
5. `$SS` (startup log) should show: `Axis count 4`, the four `Axis X (…)` ranges, **`X driver test passed` ×4 (X/Y/Z/A)**, `PWM Spindle Ena:NO_PIN Out:gpio.4 … Freq:100Hz`, and **no `[MSG:ERR`**. `driver test failed. Check motor power` means 24 V was off or USB went in first: press RESET.

## (b) Bench bring-up (one motor at a time, power off to connect)

Default TMC current is high (wiki): connect motors only after (a) shows four "driver test passed".

1. `$X`: shaft resists by hand (hold 0.5 A). `$MD` frees it, `$ME` locks it.
2. **UART current check:** `$/axes/x/motor0/tmc_2209/run_amps=0.3`, `$MI`, jog: torque clearly drops. Back to 1.0, `$MI`. No change = driver ignores UART (wrong-revision config?).
3. **Direction:** `$J=G91 G21 X10 F500`. **+X/+Z = away from you, +Y/+A = up.** If it's wrong: `$/axes/x/motor0/tmc_2209/direction_pin=i2so.1:low` (use that axis's own pin), then `$CD=fluidnc-4x-hotwire.yaml`, `$Bye`.
4. **Steps/mm:** jog X 500 (Y 100), measure: within 0.5 mm (80/1600 are exact). 2× error = microsteps not 16 (UART).
5. `$J=G91 X900 F1500` there and back 5× (verticals `Y250 F900`): back on the mark.
6. After 20 min jogging, a finger stays on the driver heatsinks (<60 °C); else more airflow. Raise `run_amps` (max 1.2) only if steps are lost.

## (c) Limits and homing

1. `?` shows no `Pn:`. Press each switch → its letter appears; unplugged → also appears (fail-safe). `$Limits` streams states.
2. Hand on the E-stop: `$HY`, `$HA` (up, touch, 2 mm back-off, slow retouch), then `$HX`, `$HZ` (toward the front), then `$H`. If it moves away from the switch, flip `positive_direction`, not `direction_pin`.
3. **Y0 = bed top:** after `$H`, measure the height of the **bottom of each MIG-tip bore** above the bed (the wire isn't strung yet) → `y`/`a` `homing: mpos_mm`; `max_travel_mm = mpos_mm − (lowest safe tip height + 2)`. 300/290 are **placeholders**: E-stop in hand until measured.
4. `$Bye`, `$H`, jog past each end: stops at the limit. Copy the `Axis … (min,max)` boot ranges into wingcut `limits`, 2 mm inside.

## (d) Tram (X vs Z, Y vs A)

Each tower homes to its own switch; tenths of a mm twist panels.
1. `$H`, jog to `X100 Z100`.
2. Measure each wire contact to a fence square to the bed: d = tip − root (+ = tip further back).
3. `z: homing: mpos_mm: +d`, `$CD=…`, `$Bye`, `$H`; repeat to **0.2 mm**. Keep |d| ≤ 2 mm (wingcut `limits.x` margin).
4. Jog `Y150 A150`, compare heights above the bed, correct `a: homing: mpos_mm` to 0.2 mm.
5. Zero the work offset: `G10 L2 P1 X0 Y0 Z0 A0`. **wingcut programs use machine coordinates.**

## (e) Wire bring-up

**Numbers (0.4 mm NiCr80, 8.7 Ω/m, 1.45 m):** R ≈ 12.6 Ω. I_full ≈ (V_PSU − 1.2)/(R + 0.3) ≈ **2.7 A** at 36 V. Under PWM the wire heats like I_eq = I_full·√(S/1000), so **S = 1000·(I_target/I_full)²**.

| Target I_eq | S at I_full 2.70 A | S at 2.86 A (no SSR/lead loss) |
|---|---|---|
| 2.00 A | 549 | 489 |
| 2.15 A | 634 | 565 |
| 2.30 A | 726 | 647 |

1–3. **Dummy-load, SSR-blocking, alarm and E-stop tests:** do them exactly as written in [01 §6.3](01-bom-wiring-assembly.md) (one version only, to avoid two different procedures). Expected: the meter ≈ 0.33 / 0.8 / 1.6 A at S200 / S500 / S1000, **0.00 A** after `M5`, 0 A with SSR 4 lifted, 0 A on any alarm, and nothing restarts after the E-stop is released.
4. **Wire** (tensioned, no foam within 50 mm): measure cold R (power off), compute I_full and S. In air `M3 S400 → S600 → S700`, 10 s each: no glow, no growing sag.
5. **Riden option** (LRS-150F-48 → RD6006 → SSR): in the menu set USB, baud 115200, address 1, **power-on output OFF**. USB only through the ADuM3160 isolator. Use CC **2.0–2.3 A**, voltage limit **36 V** (≈30 V needed; the RD6006 gives ≈43 V max from 48 V). Use `heat_on = "M3 S1000"` (the SSR fully on; S1000 is effectively DC). Expect ≈28–30 V and 13 Ω on the Riden display.
6. **Kerf:** 50×50 mm plugs at 120/180/240 mm/min, fixed S; kerf = 50 − side → `kerf` table. Check with a taper plug (150/75 mm chord). Redo per foam batch. "Adjust heat, not speed" ([rcKeith](https://rckeith.co.uk/grbl-hotwire-mega-5x-for-cnc-foam-cutters/)).

**Never change S mid-cut:** an S word with the wire on stops motion for `spinup_ms × ΔS/1000`. wingcut emits one `heat_on` per cut.

## (f) wingcut setup and tests

Follow wingcut's [hardware-bringup.md](https://github.com/andres/wingcut/blob/main/docs/hardware-bringup.md). Specific to this machine:

1. Open [wingcut-machine.toml](../config/wingcut-machine.toml) (Machine tab or `--machine`). Set `tower_spacing` (measured), `limits`, `heat_on`. Linux: `sudo usermod -aG dialout $USER`. Use `/dev/serial/by-id/…` paths so the board and the Riden can't swap.
2. **Connect:** the banner must not repeat on connect. State and positions update about 5×/s. Jog directions as in (b). **Home**: wingcut sees FluidNC's `[MSG:Homed:…]` and clears "not homed". Pre-flight must show *work offset zero*.
3. **Pause** ([FluidNC v4.1.1 Protocol.cpp](https://github.com/bdring/FluidNC/blob/v4.1.1/FluidNC/src/Protocol.cpp)): wingcut sends `!`, then `0x9E` at `Hold:0`; FluidNC calls `spinDown()`. On `~` it logs `Restoring spindle`, re-applies M3 S, waits `spinup_ms × S/1000` (1.8 s at S600), then moves. **No extra config.** Test on the dummy load in a real (not dry) run: Pause → stop, 0 A; Resume → current, ≈2 s, motion. A bare feed hold from another sender leaves the wire hot.
4. **STOP:** motion stops, 0 A, no alarm. **USB unplugged** in a dry run: reported; board finishes its buffer. **E-stop with USB in (variant A; for B see 02b):** a new `Grbl 4.1…` banner on release = ESP32 rebooted (`must_home` protects you). No banner = it stayed on USB power: always press **RESET** (top note 2).
5. **Dry run:** block placed per the panel, wire parked in front, pre-flight green, time ≈ estimate.
6. **Riden:** Connect supply → model and live V/A. **Apply current** shows on the display. Air cut with the wire hot: **lower V-set on the Riden front panel to 10 V**. The current falls to ≈0.8 A, below 50 % of 2.0 A, and within ≈1 s wingcut must pause the cut and turn the output off. After the cut the output is off.

## (g) Troubleshooting

| Symptom | Cause → fix |
|---|---|
| `driver test failed` | USB before 24 V → RESET / `$MI`; wrong-revision config (UART must be gpio.26/2) |
| Motor hot, moves wrong distance | Driver lost its UART settings (falls back to its address-pin microsteps; E-stop, USB-first) → RESET, re-home |
| Verticals stall on rapids | max_rate 900 → 600; check T8 binding |
| Wrong direction / homing goes away | `:low` on `direction_pin` / `positive_direction` |
| ALARM:1 random | Switch NC wire intermittent; StallGuard jumper bridged; missing 100 nF |
| ALARM:2 | wingcut `limits` wider than FluidNC soft range, or work offset not zero |
| ALARM:8/9 | Pull-off didn't clear / switch not found → wiring, `pulloff_mm`, direction |
| ALARM:11 / 14 | Switch open at boot / unhomed → `$H` |
| Wire never heats | No M3; SSR input polarity (+ to VMot); lead on the 5 V-out gpio.4 instead of the MOSFET terminal |
| Wire hot after M5 | SSR shorted → E-stop, replace |
| Wire stays hot in Pause | Paused with another sender (plain feed hold); with wingcut, report the log |
| Riden "no reply" | Port/baud/address; isolator powered? |
| Board doesn't boot | Something on the gpio.12 terminal pulling it high |
