#include "pico/stdlib.h"
#include "hardware/pwm.h"

// IMPORTANT: make sure the CPU clock frequency is set to 128MHz
//
//int phase_shifts[10] =  {60,125,123,86,50,68,93,60,125,145};
//int phase_shifts2[10] = {16,7  ,8,  27,27,28,21,27,0,0};

// in us (microseconds)
float time_delays[10] = {0.67, 17.47, 16.65, 6.45, 1.21, 3.44, 7.04, 0.05, 0, 0};
float time_delays2[10] = {4.27, 0, 0, 0.82, 3.92, 3.38, 0.41, 5.56, 0, 0};

void setup() {
  // Set all GPIO pins to be PWM pins
  for (int i = 0; i <= 14; i += 2) 
    gpio_set_function(i, GPIO_FUNC_PWM);

  // disable all PWM channels
  pwm_set_mask_enabled(0);

  // Set period of 128 MHz / 40 kHz = 3200 cycles 
  for (int pwm_slice = 0; pwm_slice <= 7; pwm_slice++) {
    pwm_set_wrap(pwm_slice, 3199);

    // set control
    // one period is 25us
    int CC_shift = (int) (((time_delays[pwm_slice] + time_delays2[pwm_slice]) / 25) * 3200);
    pwm_set_counter(pwm_slice, CC_shift);
      
    // Set channel A output high for one cycle before dropping
    pwm_set_chan_level(pwm_slice, PWM_CHAN_A, 1599);
  }


  pwm_set_mask_enabled(-1);
//  pwm_set_counter(0, 1500);
}

void loop() {
  delay(1000);
}
