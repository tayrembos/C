//Taylor Rembos

#include <avr/io.h>
#include "DAC.h"
#include "Timer.h"
#include "DMA.h"

int main(void)
{
	DAC_init();
	
	Timer_init();
	
	Generate_Timer(200); //200Hz wave
	
	DMA_init();

    while (1) 
    {
		
    }

}







