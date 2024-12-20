#include "pico/stdlib.h"
#include "hardware/pwm.h"

// IMPORTANT: make sure the CPU clock frequency is set to 128MHz
//
//int phase_shifts[10] =  {60,125,123,86,50,68,93,60,125,145};
//int phase_shifts2[10] = {16,7  ,8,  27,27,28,21,27,0,0};
int phase_shifts[10] = {0,45,0,90,0,45,0,90,0,0};

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
    int CC_shift = ((phase_shifts[pwm_slice] /*+ phase_shifts2[pwm_slice]*/) * 3200) / 360;
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
