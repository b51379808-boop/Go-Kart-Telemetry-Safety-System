# Go-Kart Telemetry & Thermal Safety System

An embedded, real-time telemetry and safety logging engine designed for motorsport environments. Built on the ATmega328P microcontroller, this system processes multi-sensor inputs, drives active thermal warning alerts, and logs high-frequency diagnostic data to an SD card under strict hardware constraints.

---

## What I Built
A standalone, non-blocking telemetry engine for a high-performance go-kart that simultaneously calculates live ground speed and engine rotational velocity, executes a 3-tier active thermal safety state machine, and logs structured data to a micro-SD card. 

### Core Hardware & Firmware Architecture
* **Microcontroller:** ATmega328P (5V, 16MHz)
* **Sensor Array:** Dual Hall-Effect Sensors (Axle Speed & Engine RPM), MAX6675 Cold-Junction Thermocouple K-Type Converter
* **User Interface:** Dual High-Output LED Warning Array (Yellow/Red state alerts)
* **Storage & Telemetry:** MicroSD Card Module (SPI Interface), 115200 Baud Live Serial Stream

---

## Why I Built It
Karting engines operate under high heat and vibration with zero factory diagnostic infrastructure. Overheating can lead to total engine failure within seconds, while manual tuning without quantitative speed and RPM data relies purely on guesswork. I built this embedded system to provide real-time visual safety alerts on the track and high-resolution telemetry logging for post-run performance analysis.

---

## What Problem It Solves
1. **Engine Protection:** Prevents catastrophic engine failure by monitoring head/exhaust temperatures and alerting the driver instantly via a tiered visual LED state machine before critical thresholds are reached.
2. **Deterministic Data Acquisition:** Captures synchronized pulse timing and thermal data without missing interrupt events or delaying execution.
3. **Hardware & Memory Efficiency:** Runs a fully integrated telemetry stack within 2KB of dynamic RAM (SRAM) without crashing or encountering memory heap collisions.

---

## Short Video
> **[Watch Demonstration & Bench Test Video Here]** *(Link your YouTube / Loom video here)*
> 
> *Demonstrating dual-interrupt sensor logging, real-time Serial output, MAX6675 thermal state triggers, and SD card file writing.*

---

## System Diagram
