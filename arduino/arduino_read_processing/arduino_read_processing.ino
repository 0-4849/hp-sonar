// Make sure the old bootloader is used

// COM_PIN is used for communication with the raspberry pi pico
#define COM_PIN 3
#define READ_PIN A2

const int max_error = 30;

unsigned long start_time;
unsigned long end_time;
unsigned long duration;
unsigned long distance_um;
int val;

void setup() {
  Serial.begin(115200);
  pinMode(COM_PIN, INPUT);
}

void loop() {
  if (digitalRead(COM_PIN) == HIGH) {
    start_time = micros();
    delayMicroseconds(1749);

    do {
      val = analogRead(READ_PIN);
    } while (val >= 511 - max_error && val <= 511 + max_error);
    
    end_time = micros();

    duration = end_time - start_time;
    distance_um = duration * 343;
    
    // print distance in cm
    Serial.println((double) distance_um / 10000.0, 5);
    
//    Serial.println(val);
  }
}
