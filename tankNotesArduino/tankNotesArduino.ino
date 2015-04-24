#include <spi4teensy3.h>
#include <EEPROM.h>
#include <M3T3.h>

// Tanks
int tank1AnglePin = A2; // short wires cannon // left
int tank2AnglePin = A3; // long wires cannon // right

int tank1AngleValue, tank1AngleValueOld;
int tank2AngleValue, tank2AngleValueOld;

boolean tank1AngleSent = false;
boolean tank2AngleSent = false;

boolean tank1Fired = false;
boolean tank2Fired = false;

boolean tank1Sent = false;
boolean tank2Sent = false;

long tank1LastDebounceTime = 0;
long tank2LastDebounceTime = 0;
long debounceDelay = 20;

// Slider
int tank1PosRead = 0;
int tank2PosRead = 0;

int tank1PosSaved = 1025;
int tank2PosSaved = 1025;

int tank1Velocity = -1;
int tank2Velocity = -1;

// Global

void setup() {
  Serial.begin(9600);
  MotorA.init();   // cannon 1 (left)
  MotorB.init();   // cannon 2 (right)
  pinMode(tank1AnglePin, INPUT);
  pinMode(tank2AnglePin, INPUT);
  tank1AngleValueOld = constrain(map(analogRead(tank1AnglePin), 0, 300, 0, 90), 0, 90);
  tank2AngleValueOld = constrain(map(analogRead(tank2AnglePin), 1023, 318, 0, 90), 0, 90);
}

void loop() {
  // Read position of the two sliders
  tank1PosRead = analogRead(A1);
  if (tank1PosSaved > tank1PosRead) {
    tank1PosSaved = tank1PosRead;
  }

  tank2PosRead = analogRead(A9);
  if (tank2PosSaved > tank2PosRead) {
    tank2PosSaved = tank2PosRead;
  }

  // Get angle from the cannons
  tank1AngleValue = constrain(map(analogRead(tank1AnglePin), 0, 300, 0, 90), 0, 90);
  tank2AngleValue = constrain(map(analogRead(tank2AnglePin), 1023, 318, 0, 90), 0, 90);

  // Print angle when changed
  if (tank1AngleValue != tank1AngleValueOld) {
    Serial.print(55551);
    Serial.print(",");
    Serial.println(tank1AngleValue);
    tank1AngleValueOld = tank1AngleValue;
  }

  // Print angle when changed
  if (tank2AngleValue != tank2AngleValueOld) {
    Serial.print(66661);
    Serial.print(",");
    Serial.println(tank2AngleValue);
    tank2AngleValueOld = tank2AngleValue;
  }

  // Tank 1 fiering + haptic feedback
  if (!tank1Fired && tank1PosRead < 1015) {
    int t = map(tank1PosRead, 1, 1017, 512, 300);
    MotorA.torque(t);
  } else if (!tank1Fired && tank1PosRead > 1015) {
    if (tank1PosSaved < tank1PosRead) {
      tank1Velocity = tank1PosSaved;
      tank1Fired = true;
    }
    if (tank1Fired == true && tank1Velocity >= 0) {
      if (tank1Velocity < 980) {
        Serial.print(55552);
        Serial.print(",");
        Serial.print(tank1Velocity);
        Serial.print(",");
        Serial.println(tank1AngleValue);
      }
      tank1Fired = false;
    }
    tank1PosSaved = 1025;
  }

  // Tank 2 fiering + haptic feedback
  if (!tank2Fired && tank2PosRead < 1020) {
    int t = map(tank2PosRead, 1, 1023, 512, 300);
    MotorB.torque(t);
  } else if (!tank2Fired && tank2PosRead > 1020) {
    if (tank2PosSaved < tank2PosRead) {
      tank2Velocity = tank2PosSaved;
      tank2Fired = true;
    }
    if (tank2Fired == true && tank2Velocity >= 0) {
      if (tank2Velocity < 1000) {
        Serial.print(66662);
        Serial.print(",");
        Serial.print(tank2Velocity);
        Serial.print(",");
        Serial.println(tank2AngleValue);
      }
      tank2Fired = false;
    }
    tank2PosSaved = 1025;
  }
}

// Function to give haptic feedback on various events
// Shake all:       shake(true, 0, 1-3);
// Shake specific:  shake(false, 1-2, 1-3);
void shake(boolean all, int cannon, int shakeLevel) {
  // Shake all
  if (all) {
    shakeCannon1(shakeLevel);
    shakeCannon2(shakeLevel);
  } else {
    // Shake specific
    if (cannon == 1) {
      shakeCannon1(shakeLevel);
    } else if (cannon == 2) {
      shakeCannon2(shakeLevel);
    }
  }
}

// Haptic feedback cannon 1
void shakeCannon1(int shakeLevel) {
  switch (shakeLevel) {
    case 1:
      if (tank1PosRead <= 500) {
        MotorA.torque(400);
      } else if (tank1PosRead >= 520) {
        MotorA.torque(-400);
      }
      break;
    case 2:
      if (tank1PosRead > 600) {
        MotorA.torque(-400);
      }
      else if (tank1PosRead < 400) {
        MotorA.torque(400);
      }
      break;
    case 3:
      if (tank1PosRead > 700) {
        MotorA.torque(-500);
      }
      else if (tank1PosRead < 400) {
        MotorA.torque(500);
      }
      break;
  }
}

// Haptic feedback cannon 2
void shakeCannon2(int shakeLevel) {
  switch (shakeLevel) {
    case 1:
      if (tank2PosRead <= 500) {
        MotorB.torque(400);
      } else if (tank2PosRead >= 520) {
        MotorB.torque(-400);
      }
      break;
    case 2:
      if (tank2PosRead > 600) {
        MotorB.torque(-400);
      }
      else if (tank2PosRead < 400) {
        MotorB.torque(400);
      }
      break;
    case 3:
      if (tank2PosRead > 700) {
        MotorB.torque(-500);
      }
      else if (tank2PosRead < 400) {
        MotorB.torque(500);
      }
      break;
  }
}
