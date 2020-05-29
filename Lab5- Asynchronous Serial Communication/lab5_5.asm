/*******************************************************************************
* 
* Lab #5,Sec 5: USART, Character Input
* Name:			Taylor Rembos
* Description:	This program configures the appropriate USART module within
*				the microcontroller to receive serial data from the computer.
*
*******************************************************************************/
;-------------------------------------------------------------------------------
; constant definitions
;-------------------------------------------------------------------------------
	.include "ATxmega128a1udef.inc"
	.equ stack_init = 0x3FFF	;init stack pointer for any code with ISR
	.equ output_U = 'U'			; ASCII char 'U'
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
	ldi YL, low(stack_init)
	sts CPU_SPL, YL
	ldi YL, high(stack_init)
	sts CPU_SPH, YL

	rcall USART_INIT	; init USART 
	nop
	rcall IN_CHAR		; go to subroutine
	
	;output complete name
LOOP:
;continuously transmit any character received by microcontroller back to computer

	;rcall OUT_STRING	
	rcall OUT_CHAR	
	rjmp LOOP			; continuously transmit
		
/***********************************************************************************
*								SUBROUTINES
************************************************************************************
************************************************************************************
* Name:     USART_INIT
* Purpose:  This subroutine initializes the necessary USART module on Port D (PORTD0)
*			asynch, even parity, 8 data bits, 1 start 1 stop bit, 57,600 bps baud rate
* Inputs:   None			 
* Outputs:  None
* Affected: 
***********************************************************************************/
USART_INIT:
/************************************************************************************/
;GPIO
	ldi r16, 0b1000
	sts PORTD_OUTSET, r16	; set the TX line as default to 1
	
	ldi r16, 0b1000	
	sts PORTD_DIRSET, r16	; Must set PortD_PIN3 as output for TX pin
	
	ldi r16, 0b0100			; Set input values (RX pin) for input
	sts PORTD_DIRCLR, r16
;USART----------------------------------------------------------------
;USART init
	
	ldi r16, 0b00011000			; Set the lines for TXEN and RXEN to high - bits 3&4
	sts USARTD0_CTRLB, r16		; 23.15.4 CTRLB config
	
	ldi r16, 0b00100011		; Set 00 asynch, 10 parity even, 0 (1 stop bit), 011 (8 bit frame)
	sts USARTD0_CTRLC, r16		; 23.15.5 CTRLC config

	ldi r16, (BSEL & 0xFF) 		; select only the lower 8 bits of BSel
	sts USARTD0_BAUDCTRLA, r16		; setting the lower 8 bits of BSEL to baudctrla

	ldi r16, ((BSCALE << 4) & 0xF0) | ((BSEL >> 8) & 0x0F)
	sts USARTD0_BAUDCTRLB, r16 	; set baudctrlb to BScale | BSel
									; Lower 4 bits are upper 4 bits of BSel 
									; and upper 4 bits are the BScale.
	
	ret		; return from subroutine

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

TX_POLL:
	lds r17, USARTD0_STATUS ; load status register 
	sbrs r17, 5				; proceed to write out char if the DREIF flag set
; if ongoing transmission...
	rjmp TX_POLL			; wait until completed - cont poll int flag
; else, transmit character
	sts USARTD0_DATA, r16	; send char out over the USART
	pop r17										
	ret						; return from subroutine

/************************************************************************************
* Name:     OUT_STRING
* Purpose:  This subroutine will output a string of arbitrary length from program memory,
*			pointed to by Z pointer, to the transmit pin of a chosen USART mode
* Inputs:   r18 (character saved) 
* Outputs:  None
* Affected: 
***********************************************************************************/
OUT_STRING:
/************************************************************************************/

	elpm r16, Z+		; read character pointed to by Z, increment pointer
	cpi r16, 0		; compare with NULL value
	brne SKIP		; if char is non-null, call OUT_CHAR subroutine
	ret				; else, if null, return from subroutine

SKIP:
	rcall OUT_CHAR
	rjmp OUT_STRING	; return to beginning

/************************************************************************************
* Name:     IN_CHAR
* Purpose:  This subroutine will receive a single character within the USART module
*			and return the received character to the calling procedure via
*			general purpose regs r16/r17
* Inputs:   r16 (character saved) 
* Outputs:  None
* Affected: 
***********************************************************************************/
IN_CHAR:
/************************************************************************************/
RX_POLL: ;necessary?
	lds r16, USARTD0_STATUS		; check status register if character has been received
	sbrs r16, 7					; poll receive flag
	rjmp RX_POLL				; if not received (not set), loop
	lds r16, USARTD0_DATA 		; else, if set, read char from appropriate buffer
; return character to the calling procedure
	ret				; return from subroutine
;-------------------------------------------------------------------------------	
;HELPFUL READING:
;	8331 SECTION 23 - USART
;	OOTB uPAD Schematic
;	SCI_Polling.asm