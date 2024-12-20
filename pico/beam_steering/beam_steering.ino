// IMPORTANT !!!: make sure the CPU clock frequency is set to 128MHz
// and microcontroller is Raspberry Pi Pico

#include "pico/stdlib.h"
#include "hardware/pwm.h"

// the pin used for communication with arduino
#define COM_PIN 22

// in us (microseconds)
float time_delays[10] = {4.94,17.47,16.65,7.27,5.13,6.82,7.45,5.61,0.0,0.0};

// angle in degrees
void set_array_steering(float angle) {
  // disable all PWM channels
  pwm_set_mask_enabled(0);

  // Set period of 128 MHz / 40 kHz = 3200 cycles 
  for (int pwm_slice = 0; pwm_slice <= 7; pwm_slice++) {
    int CC_shift = (int) ((time_delays[pwm_slice] / 25 + (float) pwm_slice * angle / 360) * 3200);
    CC_shift %= 3200;
    CC_shift += 3200;
    CC_shift %= 3200;
    pwm_set_counter(pwm_slice, CC_shift);
//    Serial.println((float) pwm_slice * angle / 360);
//    Serial.println(CC_shift);
  }

  // enable all PWM slices at once to ensure the set phase shift is accurately applied
  pwm_set_mask_enabled(-1);
}

void setup() {
  pinMode(COM_PIN, OUTPUT);
  
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
  
//  delay(500);
//  set_array_steering(180.0);
}

void loop() {
  delay(1000);
//  gpio_set_mask(1 << COM_PIN);
  digitalWrite(COM_PIN, HIGH);
  pwm_set_mask_enabled(-1);
  
  sleep_us(400);
  
  digitalWrite(COM_PIN, LOW);
  pwm_set_mask_enabled(0);
//  gpio_clr_mask(1 << COM_PIN);
  
//  set_array_steering(45.0);
}
