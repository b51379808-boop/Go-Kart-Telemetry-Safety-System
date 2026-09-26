# Go-Kart Telemetry & Thermal Safety System

An embedded, real-time telemetry and safety logging engine . Built on an Arduino microcontroller, this system processes multi-sensor inputs, drives active thermal warning alerts, and logs high-frequency data to an SD card.
---

## what is it?
A device that simultaneously calculates live ground speed and engine rotational velocity, executes a 3-tier active thermal safety state machine, and logs data to a micro-SD card. 

### Core Hardware & Firmware 
* **Microcontroller:** ATmega328P Clone (5V, 16MHz)
* **Sensor Array:** Dual Hall-Effect Sensors (Axle Speed & Engine RPM), MAX6675 Cold-Junction Thermocouple K-Type Converter
* **User Interface:** Dual High-Output LED Warning Array (Yellow/Red state alerts)
* **Storage & Telemetry:** MicroSD Card Module (SPI Interface), 115200 Baud Live Serial Stream

---

## Why I Built It
Overheating can prove dangerous to the driver, I wanted to ensure the safety of not only myself when driving, but anyone else riding the go-kart. Furthermore, I wanted to the ensure the optimization of the go kart through calculating slip 

---

## What Problem It Solves
1. **Engine Protection:** Prevents catastrophic engine failure by monitoring head/exhaust temperatures and alerting the driver instantly via a tiered visual LED state machine before critical thresholds are reached.
2. **Deterministic Data Acquisition:** Captures synchronized pulse timing and thermal data without missing interrupt events or delaying execution.
3. **Hardware & Memory Efficiency:** Runs a fully integrated telemetry stack within 2KB of dynamic RAM (SRAM) without crashing or encountering memory heap collisions.

---

## Short Video
> **[Watch Demonstration & Bench Test Video Here]**


---

## System Diagram

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

## Results
* **Deterministic Execution:** Stable $100\text{ ms}$ main execution loop with zero dropped Hall-effect interrupt counts.
* **Thermal Safety Response:** Demonstrated reliable state transitions across 3 temperature tiers (Tier 1: $150^\circ\text{F}$, Tier 2: $180^\circ\text{F}$, Tier 3: $200^\circ\text{F}+$).
* **Reliable Black-Box Logging:** Verified multi-hour continuous logging to `LOG.CSV` on MicroSD card powered by 6V battery source.
