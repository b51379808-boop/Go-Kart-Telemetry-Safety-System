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
