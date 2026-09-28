 # System Architecture & Engineering Specifications

This document details the software architecture, task scheduling, memory management, and hardware interfaces for the Go-Kart Telemetry and Safety System.

---

## 1. System Hardware & Data Flow

* **Sensors → Interrupters / Bus:**
  * **Wheel Hall Effect Sensor** → [Pin D2 / INT0] → Fires hardware interrupt on falling pulse edge to track wheel speed.
  * **Engine Hall Effect Sensor** → [Pin D3 / INT1] → Fires hardware interrupt on falling pulse edge to track engine RPM.
  * **MAX6675 Thermocouple Amp** → [SPI Bus (Pins D4–D6)] → K-Type probe sampled every 200ms by the non-blocking scheduler.

* **Processing Engine → Safety Output:**
  * **100ms Non-Blocking Task Scheduler** → Calculates ground speed (MPH) using 17" tire kinematics ($0.0008428\text{ miles/rev}$) and live clutch slip ratio ($3.0:1$ gear ratio).
  * **Dual-Safety State Machine** → Evaluates thermal limits ($150^\circ\text{F} / 180^\circ\text{F} / 200^\circ\text{F}$) and sustained slip ($>1.3$ for $2\text{s}$) → Triggers Yellow/Red alert LEDs.

* **Data Storage & Diagnostic Output:**
  * **Telemetry Frame** → Enqueued to a 16-frame SRAM Ring Buffer (`SystemFrame ringBuffer[16]`).
  * **Ring Buffer** → Flushed asynchronously over SPI → Saved to MicroSD Card (`LOG.CSV`).
  * **Live Stream** → Hardware UART at **115200 Baud** → Streams real-time diagnostics to trackside PC.

---

## 2. Multi-Rate Task Scheduler

To guarantee hard real-time pulse collection without blocking core execution, the firmware uses a two-tier non-blocking scheduler running on `millis()` timing loops:

* **Task 1: Telemetry & Safety Evaluation (10 Hz / 100ms Loop)**
  * Atomic read and reset of interrupt pulse counters (`noInterrupts()` / `interrupts()`).
  * Kinematic conversion of wheel pulse counts to ground speed (MPH) using a $17''$ tire diameter ($0.0008428\text{ miles/rev}$).
  * Calculation of engine RPM and theoretical drivetrain ratio ($3.0:1$ sprocket reduction).
  * Real-time clutch slip ratio computation ($\text{Actual Engine RPM} / \text{Theoretical Engine RPM}$).
  * Evaluation of thermal and slip thresholds to drive safety LED states.
  * Pushing formatted `SystemFrame` structs to the SRAM ring buffer.

* **Task 2: Thermal Sensor Throttling (5 Hz / 200ms Loop)**
  * Reads the MAX6675 K-Type thermocouple amplifier over SPI.
  * Throttles reads to every 200ms to allow cold-junction conversion without introducing processor stalls.

---

## 3. Interrupt Handling & Concurrency

Pulse detection for both wheel speed and engine RPM is offloaded to dedicated hardware interrupts on the ATmega328P:

* **INT0 (Pin D2):** Wheel speed Hall effect sensor. Fires on falling pulse edge.
* **INT1 (Pin D3):** Engine crankshaft Hall effect sensor. Fires on falling pulse edge.

All shared pulse counter variables are declared as `volatile unsigned long`. Critical sections in the 100ms scheduler briefly disable global interrupts (`noInterrupts()`) to copy and reset counts atomically, preventing race conditions or corrupted values during high-RPM reads.

---

## 4. Memory Optimization & SD Storage Pipeline

Writing directly to flash storage over SPI can introduce variable latencies up to several milliseconds, which threatens timing integrity. To decouple storage latency from real-time monitoring:

1. **RAM Ring Buffer:** Pushes telemetry data into a 16-frame circular queue in SRAM (`SystemFrame ringBuffer[16]`).
2. **Asynchronous SD Flush:** Telemetry data is held in memory and written in bursts to `LOG.CSV` on the MicroSD card, preventing disk I/O stalls from dropping pulse counts.
3. **High-Speed Serial Stream:** Outputs live telemetry over UART at **115200 baud**, spending only $\sim 6\text{ ms}$ per cycle to stream telemetry to trackside diagnostics.
