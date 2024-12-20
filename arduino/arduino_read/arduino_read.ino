// Make sure the old bootloader is used

// COM_PIN is used for communication with the raspberry pi pico
#define COM_PIN 3
#define READ_PIN A2

const int max_error = 1;
volatile bool reading = true;
int val;

void setup() {
  Serial.begin(115200);
  pinMode(COM_PIN, INPUT);

  attachInterrupt(digitalPinToInterrupt(COM_PIN), start_read, RISING);
  attachInterrupt(digitalPinToInterrupt(COM_PIN), end_read, FALLING);

//  attachInterrupt(digitalPinToInterrupt(COM_PIN), toggle_read, CHANGE);
}

void loop() {
  if (reading) {
    val = analogRead(READ_PIN) >> 2;
//  if (val < 127 - max_error || val > 127 + max_error)
    Serial.write(val);
  }
}

//void toggle_read() {
//  reading ^= true;
//}

void start_read() {
  reading = true;
}

void end_read() {
  reading = false;
}
