//Taylor Rembos

#include <avr/io.h>
#include "DAC.h"

void DAC_init(){
	DACB.CTRLA |= 0x05;
	DACB.CTRLB |= 0x00;
	DACB.CTRLC |= 0x18;
}