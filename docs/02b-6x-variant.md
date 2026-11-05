# 02b — 6x variant: what differs from 02 (FluidNC 6x + 4× DM542T V4.0)

Everything not listed here is as in [02](02-firmware-commissioning.md), including axes, homing, tram, wire, wingcut and the Y/A PLACEHOLDERS. Config: [fluidnc-6x-hotwire.yaml](../config/fluidnc-6x-hotwire.yaml).

Keys checked against **FluidNC v4.1.1** source. The v4.1.1 simulator (I2S swapped for GPIO) reports **zero errors**, and M3/M5 and a G93 XYZA move run.

Parts list (variant B, section 2.4), wiring (3.3B) and boxes (5.2): [01-bom-wiring-assembly.md](01-bom-wiring-assembly.md). The 6x goes in the printed `controller_case_6x`, the DM542Ts in the printed `dm542t_rack` ([enclosure/](../enclosure/README.md)). The mains parts stay in the steel power box.

## ⚠ What changes vs the 4x

1. **No UART drivers:** current and microsteps are DIP switches, so they survive any power loss. **No `$MI`**, no "driver test passed", no StallGuard jumpers.
2. **The E-stop kills the whole board.** The ESP32 and the CP2102 run only from VMot; USB can't power the 6x ([wiki](http://wiki.fluidnc.com/en/hardware/official/6x_CNC_Controller)). On release the board reboots (new banner, ALARM:14). The serial port disappears, so reconnect wingcut. **Rule: after every E-stop or power loss, reconnect → `$H`.** `estop_pin` covers the PSU hold-up time.
3. **Every DM542T: S2 = 5 V.** It ships at 24 V, and then "the motor won't work" with the 6x's 5 V signals ([manual](https://forum.duet3d.com/assets/uploads/files/1684504031141-dm542t_v4.0.pdf)).
4. **Timing:** `pulse_us 6` (PUL ≥ 2.5 µs), `dir_delay_us 6` (DIR leads PUL ≥ 5 µs), `disable_delay_us 200000` (enable ≥ 200 ms). FluidNC waits only on a disabled → enabled change; `idle_ms 255` never disables.

## Verified 6x terminal map

From the [6x wiki pinout](http://wiki.fluidnc.com/en/hardware/official/6x_CNC_Controller#pinout-reference). Motor ports read **Ena / Stp / Dir / Gnd**. Each input has its own Gnd beside it.

| Function | 6x terminal | FluidNC |
|---|---|---|
| X root chord | **Motor1** → DM542T #1 | ena i2so.0, step i2so.2, dir i2so.1 |
| Y root vertical | **Motor2** → #2 | i2so.7 / i2so.5 / i2so.4 |
| Z tip chord | **Motor3** → #3 | i2so.8 / i2so.10 / i2so.9 |
| A tip vertical | **Motor4** → #4 | i2so.15 / i2so.13 / i2so.12 |
| I2SO | — | BCK gpio.22, DATA 21, WS 17 |
| Limit X (front, min) | Inputs **io.33** + Gnd | `limit_neg_pin: gpio.33` |
| Limit Y (top, max) | **io.32** + Gnd | `limit_pos_pin: gpio.32` |
| Limit Z (front, min) | **io.35** + Gnd | `limit_neg_pin: gpio.35` |
| Limit A (top, max) | **io.34** + Gnd | `limit_pos_pin: gpio.34` |
| E-stop NC3 | **io.39** + Gnd (+100 nF) | `control: estop_pin: gpio.39` |
| Wire PWM → SSR | MOSFETs (TB5) **VMot → SSR 3(+)**, **io.4 → SSR 4(−)** | `PWM: output_pin: gpio.4` |
| Power | **VMot (+) / Gnd (−)**, 12–30 V, ≥ 2 A, **no reverse-polarity protection** | — |
| Antenna | U.FL (V1.2) → SMA bulkhead. Never power up without it (overheats) | — |
| USB-C | CP2102, needs VMot on | — |
| Leave empty | io.2/io.26 (no pull-up), io.36, MOSFET io.12, **all "Outputs (5v)"**, Motor5/6, RS485, 0–10 V | — |

Opto inputs, ≈ 12 mA per closed switch (keep the gold D2F switches), 10 k pull-ups except gpio.2/26. NC-to-Gnd: closed = low = OK, open or broken = active (wiki: "Normally closed are active high"). So **no `:pu`, no `:low`**. The io.4/io.12 5 V outputs switch with the MOSFETs; gpio.12 is a strapping pin.

## DM542T V4.0 (each of the 4)

| Item | Setting / wire |
|---|---|
| **S2** | **5 V** |
| SW1–3 | **ON-OFF-ON** = 1.91 A peak / 1.36 A RMS |
| SW4 | **OFF** = 50 % standstill current (T8 is self-locking) |
| SW5–8 | **ON-ON-OFF-ON** = 3200 pulses/rev (matches 80 / 1600 steps/mm) |
| +Vdc / GND | Its **own** 1.0 mm² pair to the 24 V / 0 V bus (18–50 V range) |
| PUL+ / DIR+ / ENA+ | Its port's **Stp / Dir / Ena** |
| PUL− / DIR− / ENA− | Jumpered together with **twin ferrules**, one wire to that port's **Gnd** (common ground, as the wiki recommends) |
| A+ A− B+ B− | Motor coils (17HS19: A+ A− = one coil, B+ B− = the other; check with a meter) |

ENA+ high = **disabled** ("Disable the drive by 4.5–24 V"), so `disable_pin` stays active-high. Never unplug driver terminals with power on.

## Bring-up differences

**(a)5 `$SS`:** no `driver test` lines. Expect `Stepping:I2S Pulse:6us Dsbl Delay:200000us Dir Delay:6us`, `estop_pin gpio.39`, `PWM Spindle Ena:NO_PIN Out:gpio.4`, and no `[MSG:ERR`.

**(b) Bench first, drivers unpowered:** jumper each limit input to its Gnd. Jog: that port's **Stp LED** glows dimly and its **Dir LED** flips when you reverse. `$MD`/`$ME` toggle the **Ena LED** (on = disabled).

Replaces (b)1–2, one driver at a time, DIP and S2 checked:
1. Green LED on, red LED off.
2. `$ME`: shaft locked. `$MD`: free. Reversed → check wiring, then `:low` on `disable_pin`.
3. In (b)4, a **2×/½× distance error = SW5–8 wrong**.

**(c)/(e) E-stop test** (replaces (e)3's E-stop part):
1. `M3 S500` + jog, press the E-stop: stop, 0 A, board dark.
2. Release: new banner, ALARM:14, 0 A, no motion. `$H`.
3. **estop_pin alone:** power on, lift the io.39 lead: `Pn:E`, Alarm. Reconnect: still Alarm until RESET and `$H`.

## Troubleshooting rows that differ

| Symptom | Cause → fix |
|---|---|
| No COM port | 24 V off (the CP2102 runs from VMot) · [CP210x driver](https://www.silabs.com/developer-tools/usb-to-uart-bridge-vcp-drivers) · charge-only cable |
| wingcut loses the port on E-stop | Normal (board unpowered). Reconnect, then `$H` |
| Stp/Dir LEDs active, motor dead | S2 still at 24 V · ENA inverted (`$ME` test) · red LED blinking |
| Red LED: 1 blink / 2 blinks per 3 s | Over-current (phase short) / over-voltage (> 60 V). Fix it, then **power-cycle** the driver |
| Moves 2× or ½ the distance | SW5–8 ≠ 3200 |
| Driver hot, motor weak | SW1–3 wrong · SW4 ON (90 % idle current) |
| ALARM:1 random | NC wire intermittent · missing 100 nF · silver switch (12 mA loop) |
| Board doesn't boot | Something on the io.12 5 V output pulling gpio.12 high |
| Weak Wi-Fi, ESP hot | Antenna not connected |
| Dropped rows | `driver test failed`, StallGuard, lost UART settings |
