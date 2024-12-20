// Make sure the old bootloader is used

// COM_PIN is used for communication with the raspberry pi pico
#define COM_PIN 3
#define READ_PIN A2

const int max_error = 1;
int val;

void setup() {
  Serial.begin(115200);
  pinMode(COM_PIN, INPUT);
}

void loop() {
  if (digitalRead(COM_PIN) == HIGH) {
    val = analogRead(READ_PIN) >> 2;
//  if (val < 127 - max_error || val > 127 + max_error)
    Serial.write(val);
  }
}
