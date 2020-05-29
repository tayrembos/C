//Taylor Rembos

#include <avr/io.h>
#include "DAC.h"
#include "Timer.h"

int main(void)
{
	DAC_init();
	Timer_init();
	
	Generate_Timer(250000);

    while (1) 
    {
		
    }

}

