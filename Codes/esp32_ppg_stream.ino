// ESP32 + MAX30102 — Raw PPG Streamer
// This code does ONE thing: read the sensor and print values over USB
// All processing happens in MATLAB
//
// Library needed: "SparkFun MAX3010x Pulse and Proximity Sensor Library"
// Install via: Arduino IDE → Tools → Manage Libraries → search "MAX30105"

#include <Wire.h>
#include "MAX30105.h"

MAX30105 sensor;

void setup() {

  Serial.begin(115200);

  Wire.begin(4, 5);

  if (!sensor.begin(Wire, I2C_SPEED_STANDARD)) {

    while (1);

  }

  sensor.setup(
    20,     // lower brightness
    1,
    2,
    100,
    411,
    4096
  );
}

void loop() {

  long ir = sensor.getIR();

  Serial.println(ir);

  delay(10);
}