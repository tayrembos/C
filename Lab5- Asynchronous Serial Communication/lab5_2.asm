/*******************************************************************************
*
* Lab #5,Sec 2: USART, Character Transmission
* Name:			Taylor Rembos
* Description:	This program configures the appropriate USART module within
*				the microcontroller and sends data to the computer via
*				the USB port.
*
*******************************************************************************/
;-------------------------------------------------------------------------------
; constant definitions
;-------------------------------------------------------------------------------
	.include "ATxmega128a1udef.inc"
	.equ stack_init = 0x3FFF	;init stack pointer for any code with ISR
	.equ output_U = 'U'			; ASCII char 'U'
	.equ BSCALE = -7			; 2 MHz, 57600 baud rate
	.equ BSEL = 150				; 34

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
	;ldi r19, output_U	;load ASCII U into r16 for OUT_CHAR
	;ldi r16, 0x55
	ldi r16, 'U'
	;ldi r16, output_U
	;rcall DELAY_1000us

	rcall OUT_CHAR		; call subroutine 
	rjmp REPEAT			; continuously output forever
		
/***********************************************************************************
*								SUBROUTINES
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
	;ldi r16, 0b00000011
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
	
;check if onogoing transmission in USART module
TX_POLL:
	lds r17, USARTD0_STATUS ; load status register 
	sbrs r17, 5				; proceed to write out char if the DREIF flag set
; if ongoing transmission...
	rjmp TX_POLL			; wait until completed - cont poll int flag
; else, transmit character
	sts USARTD0_DATA, r16	; send char out over the USART
	pop r17										
	ret						; return from subroutine

;-------------------------------------------------------------------------------	
;HELPFUL READING:
;	8331 SECTION 23 - USART
;	OOTB uPAD Schematic
;	SCI_Polling.asm