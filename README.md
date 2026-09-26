# Go-Kart Telemetry & Thermal Safety System

An embedded, real-time telemetry and safety logging engine . Built on an Arduino microcontroller, this system processes multi-sensor inputs, drives active thermal warning alerts, and logs high-frequency data to an SD card.
---

## What I Built
A telemetry and thermal-safety system for a go-kart that measures engine/axle speed and temperature, calculates clutch slip, and records telemetry for later analysis through a microsd card.

### Core Hardware & Firmware 
* **Microcontroller:** ATmega328P Clone (5V, 16MHz)
* **Sensor Array:** Dual Hall-Effect Sensors (Axle Speed & Engine RPM), MAX6675 Cold-Junction Thermocouple K-Type Converter
* **User Interface:** Dual High-Output LED Warning Array (Yellow/Red state alerts)
* **Storage & Telemetry:** MicroSD Card Module (SPI Interface), 115200 Baud Live Serial Stream

---

## Why I Built It
I wanted to understand how the machine behaved rather than relying only on intuition while driving it. I also wanted to ensure that while driving my go-kart I was safe.
---

## What Problem It Solves
1. **Engine Protection:** Prevents catastrophic engine failure by monitoring head/exhaust temperatures and alerting the driver instantly via a tiered visual LED state machine before critical thresholds are reached.
2. **Deterministic Data Acquisition:** Captures synchronized pulse timing and thermal data without missing interrupt events or delaying execution.
3. **Hardware & Memory Efficiency:** Runs a fully integrated telemetry stack within 2KB of dynamic RAM (SRAM) without crashing or encountering memory heap collisions.

---

## Short Video
> **[Watch Demonstration & Bench Test Video Here]**


---
## System Architecture

### 1. Real-Time Physical Inputs → Microcontroller Processing
* **Wheel Speed Sensor** → Tracks wheel revolutions via magnetic pulses → Calculates real-time ground speed (MPH) based on 17" tire diameter.
* **Engine Speed Sensor** → Tracks crankshaft revolutions via magnetic pulses → Calculates live engine RPM.
* **Temperature Sensor** → Monitors engine head heat via digital probe → Prevents permanent thermal damage to the engine.

### 2. Embedded Safety Engine → Driver Alert Hardware
* **Drivetrain Analysis (RPM vs. MPH)** → Detects mechanical clutch slip (when the engine spins faster than the wheels can turn).
* **Multi-Tier Safety Logic** → Evaluates live temperature and sustained clutch slip (>2 seconds) → Triggers visual alerts instantly:
  * **Tier 1 Alert (Caution):** Engine hits 150°F OR clutch slips continuously → **Yellow LED turns ON**
  * **Tier 2 Alert (Warning):** Engine hits 180°F → **Red LED turns ON**
  * **Tier 3 Alert (Critical):** Engine hits 200°F → **Both LEDs turn ON** (Immediate driver shutdown signal)

### 3. Memory Optimization → High-Reliability Data Storage
* **Live Telemetry Data** → Queued in an optimized RAM Ring Buffer → Prevents system lag while saving to storage.
* **Buffered Data Queue** → Asynchronous SPI Flush → Saved to MicroSD Card (`LOG.CSV`) for post-run performance analysis.
* **Live Diagnostics** → High-Speed Serial Output → Transmitted to a laptop for real-time trackside tuning.
## Key Engineering Decisions

### 1. Multi-Rate Non-Blocking Task Scheduling
To accommodate the hardware constraints of the MAX6675 thermocouple converter—which requires a minimum $220\text{ ms}$ internal A/D conversion cycle—thermal reads were decoupled from the main telemetry loop. Telemetry calculations (MPH/RPM) and SD ring-buffer pushes execute strictly every $100\text{ ms}$, while thermal sampling is throttled to $200\text{ ms}$ using state counters. This eliminated sensor stalls while keeping high-frequency telemetry intact.

### 2. RAM Ring Buffer & Asynchronous SD Writing
Direct SPI writes to an SD card suffer from unpredictable flash write latencies (up to $100\text{ ms}$ per block flush). To prevent blocking the main loop, a 16-frame circular RAM buffer (ring buffer) was implemented. Telemetry frames are enqueued synchronously every $100\text{ ms}$, while background task loops drain the buffer to `LOG.CSV` and flush every 10 frames to protect flash endurance and ensure deterministic loop execution.

### 3. Memory Optimization under 2KB SRAM Limit
With SD card SPI libraries reserving 512 bytes for sector buffering, global variables caused memory collisions on the ATmega328P. Dynamic memory was reclaimed by wrapping static string literals in `F()` macros (moving string memory into Flash memory) and shrinking ring buffer allocation, maintaining dynamic memory usage below 50%.

### 4. Hardware Safety Triage
During bench testing, a short-circuit incident destroyed an I2C LCD display. Rather than delaying deployment, the display dependencies were removed. All visualization logic was shifted to a ultra-fast 3-tier LED warning state machine and live 115200-baud Serial output, stripping over 70 lines of library overhead and increasing code execution stability.
---
*For full schematics and visual flow diagrams, see [docs/architecture.md](docs/architecture.md).*
---

## Bench Mark Validation
**RPM sensing** Engine and axle Hall sensors successfully detected rotational speed.
**Clutch-slip calculation** The system successfully calculated slip from the measured speeds.
**Thermal monitoring** The MAX6675 successfully measured temperature and calculated temperature-rise rate.
**Warning system** The four-state LED logic responded to the programmed thermal thresholds.
**Data logging** Telemetry was successfully written to the MicroSD card through the buffering/logging system.
**Filtering** EMA filtering reduced the effect of observed thermal measurement noise.
