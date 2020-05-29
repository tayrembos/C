// Lab #7, Sec 1: Using the ADC System
// Name: Taylor Rembos
// Description: This program initializes the ADC system and tests it by starting an
		// ADC conversion on Channel 0, waiting for the ADC interrupt flag, and
		// storing the 12-bit signed conversion result into a signed 16-bit variable
 
//////////////////////////////////////INCLUDES///////////////////////////////////////
#include <avr/io.h>
//////////////////////////////////END OF INCLUDES////////////////////////////////////
//////////////////////////////////INITIALIZATIONS////////////////////////////////////

/////////////////////////////////////FUNCTIONS///////////////////////////////////////
/************************************************************************************
* Name:     adc_init
* Purpose:  Function to initialize ADCA module
* Inputs:
* Output:
************************************************************************************/
void adc_init(void)
{	
//initialize the ADCA module as follows:
	//12-bit signed, right-adjusted
	//Normal (NOT freerun mode)
	//Use a 2.5 V voltage reference
//!!Only enable module AFTER all ADC inits
//!!Do NOT start conversion within the init function

// [4] ADCA.CTRLB - SET MODE - 28.16.2
			//CONVMODE (signed/unsigned) //RESOLUTION (12-bit, right adjusted)
	ADCA.CTRLB =	ADC_CONMODE_bm		|		//signed (+ NOT freerun)
					ADC_RESOLUTION_12BIT_gc;	//12-bit signed res, right adjust
// [2] ADCA.REFCTRL - SET REFERENCE - 28.16.3
	ADCA.REFCTRL = ADC_REFSEL_AREFB_gc;			//ext ref port B

// [3] ADCA.PRESCALER - SET SAMPLE TIME - 28.16.5 
	ADCA.PRESCALER = ADC_PRESCALER_DIV512_gc;
	
// [5] PORTA.DIR - SET ADC PIN FOR INPUT - CDS+ and CDS- signals on Analog Backpack
	PORTA.DIRCLR = PIN1_bm | PIN6_bm;			//port a pin 1 and 6 are inputs

//Before a conversion is started...
//28.8.1(8331)- INPUT SOURCE SCAN
//In the MUXCTRL reg, select appro +/- inputs to measure V of CdS cell
	ADCA_CH0_MUXCTRL = ADC_CH_MUXPOS_PIN1_gc |		//cds+
						//ADC_CH_MUXNEG_PIN6_gc;	//gnd?
						ADC_CH_MUXNEG_INTGND_MODE3_gc; //cds- = gnd input mode 2

	// [1] ADCA.CTRLA - enable ADC
	ADCA.CTRLA = ADC_DMASEL_CH01_gc | ADC_ENABLE_bm;	//adc channel 0&1, enable AFTER all init, do not start!
}
//////////////////////////////////END OF FUNCTIONS////////////////////////////////////
////////////////////////////////////MAIN PROGRAM//////////////////////////////////////
int main(void)
{	
	
//1.4 Within an infinite while loop in main:
	while (1) 
	{
	volatile uint16_t ch0_out; //signed 16-bit int var
	//read_16 = *ptr_12;	//read LSB 12-bit value into read_16;
	
	adc_init();	// call ADC init function
	
//1.4 Within an infinite while loop:
//1.4.1 Start ADC conversion on proper ADC channel (Channel 0)

//single-ended or diff
//ADC Channel Control Register - 28.17.1
// [6] ADCA.CH0.CTRL - start the scan
	ADCA.CH0.CTRL = ADC_CH_START_bm | ADC_CH_INPUTMODE_DIFF_gc; //start conv on CH0, diff input

//ADC Interrupt Flag reg - 28.16.6
// [7] ADCA.CH0.INTFLAGS - wait for result or use interrupts
	while (ADCA_CH0_INTFLAGS != ADC_CH0IF_bm)
	{
		//do nothing
		// Note: flag auto clear when ADC channel int vector is executed
	}
	

	if ( (ADCA.CH0.INTFLAGS = ADC_CH0IF_bm) ) //channel 0 interrupt flag set when conversion complete
	{
//Get result: ADCA_CH0_RES - might be *2 bytes* depending on right or left adjusted.
		ch0_out = ADCA.CH0.RES;	//get result - 12 bit right adjusted, 1.4.3 Store 12-bit signed conversion into signed 16-bit variable
		;//nop
	}
	//verify results by placing breakpoint after save conversion result
		//view contents in Watch window   
}
}
//////////////////////////////////END OF MAIN PROGRAM////////////////////////////////////
/*
HELPFUL READING:
	Sec 28 (8331) – ADC
	AVR1300 – Using the Xmega ADC
*/