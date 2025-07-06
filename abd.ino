// Copyright © 2025 Yogesh R. Chauhan
// Project Synapse – Brainwave Decoder
// This project is licensed for personal and educational use only.
// Commercial use, resale, or modification for profit is strictly prohibited.
// Unauthorized use will result in legal action and takedown notices.


// EEG P300 Arduino v1.0 — sends raw samples at FS via Serial
#define EEG_PIN A0
#define FS 250
#define BUFFER_SIZE 128

volatile uint8_t buf[BUFFER_SIZE];
volatile int head = 0, tail = 0;

void setup() {
  Serial.begin(9600);
  // Timer1 setup
  noInterrupts();
  TCCR1A = 0;
  TCCR1B = 0;
  TCNT1 = 0;
  OCR1A = (16000000/(8*FS)) - 1;
  TCCR1B |= (1 << WGM12) | (1 << CS11);
  TIMSK1 |= (1 << OCIE1A);
  interrupts();
}

ISR(TIMER1_COMPA_vect) {
  int val = analogRead(EEG_PIN);
  uint8_t sample = val >> 2;         // 10-bit -> 8-bit
  buf[head] = sample | 0x80;         // set MSB to mark frame
  head = (head + 1) % BUFFER_SIZE;
}

void loop() {
  while (tail != head) {
    Serial.write(buf[tail]);
    tail = (tail + 1) % BUFFER_SIZE;
  }
}
