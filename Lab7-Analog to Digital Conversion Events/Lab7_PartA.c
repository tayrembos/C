//Taylor Remos

#include <avr/io.h>
#include "DAC.h"

int main(void)
{
    
	DAC_init();
	DACB.CH0DATA = 0xFFF * (1/(5.0/3.0));
	
	asm volatile("nop");
	
    while (1) 
    {
		
	}
}








