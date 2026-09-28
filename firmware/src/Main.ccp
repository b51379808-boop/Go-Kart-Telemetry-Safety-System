#include <SPI.h>
#include <SD.h>
#include "max6675.h"

// --- PIN ALLOCATIONS ---
const byte PIN_SPEED_HALL = 2;   // INT0: Axle Speed Sensor
const byte PIN_RPM_HALL   = 3;   // INT1: Engine RPM Sensor
const byte PIN_MAX_SO     = 4;   // MAX6675 SPI Data Output
const byte PIN_MAX_CS     = 5;   // MAX6675 Chip Select
const byte PIN_MAX_SCK    = 6;   // MAX6675 Clock
const float GEAR_RATIO = 3.0; // 20T Clutch sprocket 60T axle sprocket
const byte PIN_LED_YELLOW = A0;  // Yellow LED (Replace A0 with your specific analog pin)
const byte PIN_LED_RED    = A1;  // Red LED  (Replace A1 with your specific analog pin)
const byte PIN_SD_CS      = 10;  // SD Card SPI Chip Select

// --- SYSTEM CONSTANTS ---
const float WHEEL_CIRCUMFERENCE_MILES = 0.0008428; // 17 Inches in diameter 
const float MAX_TEMP_TIER1 = 150.0; // °F - Yellow warning
const float MAX_TEMP_TIER2 = 180.0; // °F - Red warning
const float MAX_TEMP_TIER3 = 200.0; // °F - Critical alert

// --- INTERRUPT VARIABLES (VOLATILE) ---
volatile unsigned long speedPulseCount = 0;
volatile unsigned long rpmPulseCount   = 0;

// --- HARDWARE OBJECTS ---
MAX6675 thermocouple(PIN_MAX_SCK, PIN_MAX_CS, PIN_MAX_SO);

struct SystemFrame {
  unsigned long timestampMs;
  float mph;
  unsigned int rpm;
  float tempF;
  byte warningState;
};

// --- RAM RING BUFFER ---
const int BUFFER_SIZE = 16;
SystemFrame ringBuffer[BUFFER_SIZE];
int head = 0;
int tail = 0;

File logFile;
unsigned long lastProcessTime = 0;

// --- INTERRUPT SERVICE ROUTINES ---
void isrSpeed() { speedPulseCount++; }
void isrRpm()   { rpmPulseCount++;   }

// --- RING BUFFER ENQUEUE ---
void enqueueFrame(SystemFrame frame) {
  int nextHead = (head + 1) % BUFFER_SIZE;
  if (nextHead != tail) {
    ringBuffer[head] = frame;
    head = nextHead;
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(PIN_SPEED_HALL, INPUT_PULLUP);
  pinMode(PIN_RPM_HALL, INPUT_PULLUP);
  pinMode(PIN_LED_YELLOW, OUTPUT);
  pinMode(PIN_LED_RED, OUTPUT);

  attachInterrupt(digitalPinToInterrupt(PIN_SPEED_HALL), isrSpeed, FALLING);
  attachInterrupt(digitalPinToInterrupt(PIN_RPM_HALL), isrRpm, FALLING);

  Serial.print(F("Initializing SD System..."));
  if (SD.begin(PIN_SD_CS)) {
    logFile = SD.open("LOG.CSV", FILE_WRITE);
    if (logFile) {
      logFile.println(F("Timestamp_ms,MPH,RPM,Temp_F,Warning_State"));
      logFile.flush();
      Serial.println(F("OK!"));
    } else {
      Serial.println(F("File Open Error!"));
    }
  } else {
    Serial.println(F("SD Card Init Failed!"));
  }
}

void loop() {
  unsigned long currentMillis = millis();

 // -------------------------------------------------------------
  // TASK 1: Telemetry Processing & Thermal Safety (Every 100ms)
  // -------------------------------------------------------------
  if (currentMillis - lastProcessTime >= 100) {
    unsigned long timeDelta = currentMillis - lastProcessTime;
    lastProcessTime = currentMillis;

    // read and reset pulse counters
    noInterrupts();
    unsigned long currentSpeedPulses = speedPulseCount;
    unsigned long currentRpmPulses   = rpmPulseCount;
    speedPulseCount = 0;
    rpmPulseCount   = 0;
    interrupts();

    // Calculate Telemetry Data
    float revsSec = (float)currentSpeedPulses / (timeDelta / 1000.0);
    float currentMPH = revsSec * WHEEL_CIRCUMFERENCE_MILES * 3600.0;
    unsigned int currentRPM = (currentRpmPulses * 60000UL) / timeDelta;

    // Calculate Clutch Slip Ratio
    float axleRPM = (currentSpeedPulses * 60000.0) / timeDelta;
    float theoreticalEngineRPM = axleRPM * GEAR_RATIO;

    float slipRatio = 0.0;
    if (theoreticalEngineRPM > 0) {
      slipRatio = (float)currentRPM / theoreticalEngineRPM;
    } else {
      slipRatio = 0.0; // Idle / stopped condition
    }

    // Thermocouple Read (Throttled to 200ms)
    static byte tempTimer = 0;
    static float currentTempF = 85.6;

    tempTimer++;
    if (tempTimer >= 2) {
      currentTempF = thermocouple.readFahrenheit();
      tempTimer = 0;
    }


    static unsigned long slipStartTime = 0;
    static bool excessiveSlipActive = false;

    if (slipRatio > 1.3) {
      if (slipStartTime == 0) {
        slipStartTime = currentMillis; // Start timing slip duration
      } else if (currentMillis - slipStartTime >= 2000) { // 2.0 seconds threshold
        excessiveSlipActive = true;
      }
    } else {
      slipStartTime = 0; // Reset timer when slip drops back to normal
      excessiveSlipActive = false;
    }

    byte currentState = 0; // Normal

    // Tier 3: Critical Overheat
    if (currentTempF >= MAX_TEMP_TIER3) {
      currentState = 3;
      digitalWrite(PIN_LED_YELLOW, HIGH);
      digitalWrite(PIN_LED_RED, HIGH);
    } 
    // Tier 2: Thermal Warning
    else if (currentTempF >= MAX_TEMP_TIER2) {
      currentState = 2;
      digitalWrite(PIN_LED_YELLOW, LOW);
      digitalWrite(PIN_LED_RED, HIGH);
    } 
    // Tier 1: Caution (Thermal OR Sustained Clutch Slip)
    else if (currentTempF >= MAX_TEMP_TIER1 || excessiveSlipActive) {
      currentState = 1;
      digitalWrite(PIN_LED_YELLOW, HIGH);
      digitalWrite(PIN_LED_RED, LOW);
    } 
    // Normal Operation
    else {
      digitalWrite(PIN_LED_YELLOW, LOW);
      digitalWrite(PIN_LED_RED, LOW);
    }
    // =========================================================

    // Live Serial Output
    Serial.print(F("Speed: "));   Serial.print(currentMPH, 1);  Serial.print(F(" MPH | "));
    Serial.print(F("RPM: "));     Serial.print(currentRPM);     Serial.print(F(" | "));
    Serial.print(F("Slip: "));    Serial.print(slipRatio, 2);   Serial.print(F(" | "));
    Serial.print(F("Temp: "));    Serial.print(currentTempF, 1);Serial.print(F(" F | "));
    Serial.print(F("Status: "));  Serial.println(currentState);

    // Push Frame to RAM Buffer
    SystemFrame currentFrame = {currentMillis, currentMPH, currentRPM, currentTempF, currentState};
    enqueueFrame(currentFrame);
  }
}
