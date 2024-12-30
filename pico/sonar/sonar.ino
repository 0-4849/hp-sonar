// IMPORTANT !!!: make sure the CPU clock frequency is set to 128MHz
// and microcontroller is Raspberry Pi Pico
// compile with -O3

#include "pico/stdlib.h"
#include "hardware/pwm.h"

// the pin used for communication with arduino
#define READ_PIN 27

// in us (microseconds)
const float time_delays[10] = {4.94,17.47,16.65,7.27,5.13,6.82,7.45,5.61,0.0,0.0};
const float max_distance_m = 3.0;
// multiplication by 2 because the signal travels forth and back before reaching
const unsigned long timeout_us = 2 * max_distance_m * 1000000.0 / 343.2;

const int buf_len = 24;
byte read_buf[buf_len];

unsigned long start_time;
unsigned long end_time;


void setup() {
  // Set all even-numbered GPIO pins to be PWM pins
  // (the reason only even-numbered one are used is because
  // there is only one PWM slice per 2 pins (though there are 2 channels))
  for (int i = 0; i <= 14; i += 2) 
    gpio_set_function(i, GPIO_FUNC_PWM);

  // disable all PWM channels
  pwm_set_mask_enabled(0);

  // Set period of 128 MHz / 40 kHz = 3200 cycles 
  for (int pwm_slice = 0; pwm_slice <= 7; pwm_slice++) {
    pwm_set_wrap(pwm_slice, 3199);

    // one period is 25us, so first normalize it to [0, 1), then multiply by 3200 
    int CC_shift = (int) ((time_delays[pwm_slice] / 25) * 3200);
    pwm_set_counter(pwm_slice, CC_shift);
      
    // Only use A channels (even-numbered pins)
    // we use a 50% duty cycle for optimal resonance
    pwm_set_chan_level(pwm_slice, PWM_CHAN_A, 1599);
  }

  // enable all PWM slices at once to ensure the set phase shift is accurately applied
  pwm_set_mask_enabled(-1);

  analogReadResolution(8);
  Serial.begin(12000000);
}

void loop() {
  if (Serial.available() >= 2) {
    unsigned int upper_byte = Serial.read();
    unsigned int lower_byte = Serial.read();

    double phase_shift = (((double) (upper_byte * 256 + lower_byte)) / 65536.0) * 360.0;

    // leaving this comment here, because these are not the same. WTF? bitshift leads to garbage, but why..?
//    Serial.println(upper_byte * 256 + lower_byte);
//    Serial.println(upper_byte << 8 + lower_byte);

    set_array_steering(phase_shift);
    
    pwm_set_mask_enabled(-1);
  
    sleep_us(400);
  
    pwm_set_mask_enabled(0);

    start_time = micros();
  
    while (micros() - start_time < timeout_us) {
      // take buf_len measurements (each ~2us apart) to ensure we always
      // measure the maximum of the sine wave (period is 25us, so we get pretty close)
      for (int i = 0; i < buf_len; i++) {
        read_buf[i] = analogRead(READ_PIN);
      }

      Serial.write(read_buf, buf_len);
    }
  }
}

// angle in degrees (note this is the phase difference between
// elements, NOT the actual steering angle (one is the tangent of the other (i think)))
void set_array_steering(float angle) {
  // Set period of 128 MHz / 40 kHz = 3200 cycles 
  for (int pwm_slice = 0; pwm_slice <= 7; pwm_slice++) {
    int CC_shift = (int) ((time_delays[pwm_slice] / 25 + (float) pwm_slice * angle / 360) * 3200);
    CC_shift %= 3200;
    CC_shift += 3200;
    CC_shift %= 3200;
    pwm_set_counter(pwm_slice, CC_shift);
  }
}
