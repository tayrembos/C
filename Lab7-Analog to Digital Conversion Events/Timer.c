//Taylor Rembos

#include <avr/io.h>
#include <avr/interrupt.h>
#include "Timer.h"
#define F_CPU 2000000

void Timer_init(){
	
	TCC0.CTRLA |= 0x01;
	TCC0.CTRLB |= 0x00;
	TCC0.INTCTRLA = 0x01;
	PMIC.CTRL = PMIC_LOLVLEN_bm;
	
	sei();
}

void Generate_Timer(float value){
	//(F_CPU*(1/frequency))/64; -- (2000000*(1/200(Hz)))/64(data points) = 156.25
TCC0.PER = value;
	
}


ISR(TCC0_OVF_vect){
	
	TCC0.INTFLAGS = 0x01;
}

