/*******************************************************************************
*
* Lab #5,Sec 3: USART, Measuring Baud Rate
* Name:			Taylor Rembos
* Description:	This program configures a separate USART module to measure the
*				configured baud rate of the USART module in Part 2 to view the
*				transmission frame for the ASCII character 'U'.
*
*******************************************************************************/
;-------------------------------------------------------------------------------
; constant definitions
;-------------------------------------------- -----------------------------------
	.include "ATxmega128a1udef.inc"
	.equ stack_init = 0x3FFF	;init stack pointer for any code with ISR
	.equ output_U = 'U'			; ASCII ch ar 'U'
	.equ BSCALE = -7;	; 56000 Hz
	.equ BSEL = 150 ; 705
;-------------------------------------------------------------------------------
;PROGRAM MEMORY SECTION
;-------------------------------------------------------------------------------
.cseg					; exit data memory to program memory
.org 0x0000				; program memory starts at address zero
	rjmp MAIN			; jump to start of main program
;-------------------------------------------------------------------------------
; MAIN PROGRAM SECTION
;-------------------------------------------------------------------------------
.org 0x0200
MAIN:	
; continuously transmit ASCII character 'U'
	ldi YL, low(stack_init)	;init stack pointer
	sts CPU_SPL, YL
	ldi YL, high(stack_init)
	sts CPU_SPH, YL
	
	rcall USART_INIT	;init usart
	nop 

REPEAT:
	;ldi r16, 0x55	;load ASCII U into r16 for OUT_CHAR
	ldi r16, 'U'

	rcall OUT_CHAR		; call subroutine 
	rjmp REPEAT			; continuously output forever
		
		
/***********************************************************************************
*								SUBROUTINES
************************************************************************************
* Name:     USART_INIT
* Purpose:  This subroutine initializes the necessary USART module on Port E (PORTE0)
*			asynch, even parity, 8 data bits, 1 start 1 stop bit, 57,600 bps baud rate
* Inputs:   None			 
* Outputs:  None
* Affected: 
***********************************************************************************/
USART_INIT:
/************************************************************************************/
; Set data direction of USART transmit (Tx) pin
	ldi r16, 0b1000
	sts PORTC_OUTSET, r16		; Set the TX line as default to 1
	
	ldi r16, 0b1000
	sts PORTC_DIRSET, r16		; Set PortD_PIN3 as output for TX pin
	
	ldi r16, 0b0100				; Set input values (RX pin) for input
	sts PORTC_DIRCLR, r16

;basic breakdown - see SCI_Polling.asm
	ldi r16, 0b00011000			; Set the lines for TXEN and RXEN to high - bits 3&4
	sts USARTC0_CTRLB, r16		; 23.15.4 CTRLB config
	
	ldi r16, 0b00100011			; Set 00 asynch, 10 parity even, 0 (1 stop bit), 011 (8 bit frame)
	sts USARTC0_CTRLC, r16		; 23.15.5 CTRLC config

	ldi r16, (BSEL & 0xFF) 		; select only the lower 8 bits of BSel
	sts USARTC0_BAUDCTRLA, r16		; setting the lower 8 bits of BSEL to baudctrla

	ldi r16, ((BSCALE << 4) & 0xF0) | ((BSEL >> 8) & 0x0F)
	sts USARTC0_BAUDCTRLB, r16 	; Set baudctrlb to BScale | BSel
									; Lower 4 bits are upper 4 bits of BSel 
									; and upper 4 bits are the BScale.
	
	ret								; return from subroutine

/************************************************************************************
* Name:     OUT_CHAR
* Purpose:  This subroutine will output a single character in r16 to the transmit pin, SCI Tx,
*			of a chosen USART mode after checking if DREIF (Data reg empty flag) is empty. 
*			PC terminal prog will take received dta and put it on computer screen
* Inputs:   Data to be transmitted in r16
* Outputs:  Transmit the data 
* Affected: USARTD0_STATUS, USARTD0_DATA
***********************************************************************************/
OUT_CHAR:
/************************************************************************************/
	push r17  										
	
;check if onogoing transmission in USART module
TX_POLL:
	lds r17, USARTC0_STATUS		; load status register 
	sbrs r17, 5					; proceed to write out char if the DREIF flag set
	
	rjmp TX_POLL				; if ongoing trans, wait until completed = cont poll flag
	sts USARTC0_DATA, r16		; send char out over the USART
	pop r17										
	ret							; return from subroutine

;-------------------------------------------------------------------------------	
;HELPFUL READING:
;	8331 SECTION 23 - USART
;	OOTB uPAD Schematic
;	SCI_Polling.asm