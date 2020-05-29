//Taylor Rembos

#include <avr/io.h>
#include "DAC.h"
#include "Timer.h"
#include "DMA.h"

void KEYPAD_init(void);
void Delay(void);
void KeyPadPolling(void);

int main(void)
{
	DAC_init();
	
	Timer_init();
	
	DMA_init();
	
	KEYPAD_init();
	
	//DACB.CTRLA = 0x05;

    while (1) 
    {
		KeyPadPolling();
    }

}

void KeyPadPolling(void){
	PORTF.OUT = 0x0E;
	Delay();
	uint8_t input = PORTF.IN;
	if(input == val1){
		DACB.CTRLA = 0x05;
		Generate_Timer(625);
	}
	
	else if(input == val4){
		DACB.CTRLA = 0x05;
		Generate_Timer(156.25);
	}
	else if (input == val7) {
		DACB.CTRLA = 0x05;
		Generate_Timer(89.285);
	}
	else if (input == val_Star){
		DMA.CH0.CTRLA = 0x00;
		DMA_init_tri();
	}
	
	PORTF.OUT = 0x0D;
	Delay();
	input = PORTF.IN;
	if(input == val2){
		DACB.CTRLA = 0x05;
		Generate_Timer(312.5);
	}
	else if(input == val5){
		DACB.CTRLA = 0x05;
		Generate_Timer(125);
	}
	else if (input == val8) {
		DACB.CTRLA = 0x05;
		Generate_Timer(78.125);
	}
	else if (input == val0){
		DACB.CTRLA = 0x00;
	}
	
	PORTF.OUT = 0x0B;
	Delay();
	input = PORTF.IN;
	if(input == val3){
		DACB.CTRLA = 0x05;
		Generate_Timer(208.333);
	}
	else if(input == val6){
		DACB.CTRLA = 0x05;
		Generate_Timer(104.166);
	}
	else if (input == val9) {
		DACB.CTRLA = 0x05;
		Generate_Timer(69.444);
	}
	else if (input == val_Pound){
		DMA.CH0.CTRLA = 0x00;
		DMA_init();
	}
	
	PORTF.OUT = 0x07;
	Delay();
	input = PORTF.IN;
	if(input == valA){
		Generate_Timer(62.5);
	}
	else if(input == valB){
		Generate_Timer(56.818);
	}
	else if (input == valC) {
		Generate_Timer(52.083);
	}
	else if (input == valD){
		Generate_Timer(48.076);
	}
	
}


void KEYPAD_init(void){
	PORTE.DIRSET = 0xFF;
	PORTF.DIRSET = 0x0F;
	PORTF.DIRCLR = 0xF0;
	PORTCFG.MPCMASK = 0XF0;
	PORTF.PIN0CTRL = 0x18;
}

void Delay(){
	for(int i=0; i < 50; i++){
		asm volatile("nop");
	}
}





