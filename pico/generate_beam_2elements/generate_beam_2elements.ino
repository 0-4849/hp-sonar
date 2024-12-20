#define NOP __asm__ __volatile__ ("nop\n\t")

void setup() {
  for (int pin = 2; pin <= 12; pin++) 
    pinMode(pin, OUTPUT);
  
  // set register to control system clock
  TCCR1A = 0b00000000;

  // last 3 bits: prescalar, currently set to 1 (see datasheet for other values)
  TCCR1B = 0b00001001;
  // note that the timer mode is split across two registers

  // the output compare value; if timer hits this value, interrupt and reset
  // f_tone = f_clock / (prescalar * OCR1A * 2)
  // f_tone = 16MHz / (1 * 200 * 2) = 40kHz
  OCR1A = 199;

  // enable output compare mach interrupt A
  // lsb is for B, 2nd for A
  TIMSK1 = 0b00000010;
}

// interrupt service routine for generating a tone
ISR(TIMER1_COMPA_vect) {
   PORTB ^= B00011111;
   PORTD ^= B11111100;
  
//  PORTD ^= (1 << 2);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//  
//  PORTD ^= (1 << 3);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//  
//  PORTD ^= (1 << 4);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//  
//  PORTD ^= (1 << 5);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//  
//  PORTD ^= (1 << 6);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//  
//  PORTD ^= (1 << 7);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//
//  // port b's
//  
//  PORTB ^= (1 << 0);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//  
//  PORTB ^= (1 << 1);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//  
//  PORTB ^= (1 << 2);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//  
//  PORTB ^= (1 << 3);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;
//  
//  PORTB ^= (1 << 4);
//  NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;NOP;

  

}

void loop() {
  delay(1000);
}
