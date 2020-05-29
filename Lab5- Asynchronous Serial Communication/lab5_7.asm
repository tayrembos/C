
 /*******************************************************************************
* 
* Lab #5,Sec 7: USART, Interrupt-Based Receiving
* Name:			Taylor Rembos
* Description:	This program configures the appropriate USART module within
*				the microcontroller and creates and interrupt driven echo program
*				and toggles the Green LED
*******************************************************************************/
;-------------------------------------------------------------------------------
; constant definitions
;-------------------------------------------------------------------------------
	.include "ATxmega128a1udef.inc"
	.equ stack_init = 0x3FFF	;init stack pointer for any code with ISR
	.equ out_string_size = 0x1FFF		; out table size
	.equ base_add =	0x300000
	.equ bsel = 150
	.equ bscale = -7
	.equ bit456 = 0x70
	.equ BIT5 = 0b00100000
	.equ GREEN = ~(BIT5)
	.equ BLACK		= 0xFF
;-------------------------------------------------------------------------------
;PROGRAM MEMORY SECTION
;-------------------------------------------------------------------------------
.cseg					; exit data memory to program memory
.org 0x0000				; program memory starts at address zero
	rjmp MAIN			; jump to start of main program

;-------------------------------------------------------------------------------
; INPUT TABLE SECTION
.cseg				; program memory
; interrupt vector location
.org USARTD0_RXC_vect
	jmp RXC_Interrupt
;-------------------------------------------------------------------------------
; MAIN PROGRAM SECTION
;-------------------------------------------------------------------------------
.org 0x0200
MAIN:	
	;setup stack pointer
	ldi YL, low(stack_init)
	sts CPU_SPL, YL
	ldi YL, high(stack_init)
	sts CPU_SPH, YL

;	rcall EBI_INIT
	rcall INTERRUPT_INIT 
	rcall USART_INIT
	nop

	ldi R22, green			;load a four bit value (PORTD is only four bits)
	sts PORTD_DIRSET, R22	;set all the GPIO's in the four bit PORTD as outputs

	;;turn off all for black
	;ldi	R22, BLACK
	;sts PORTD_OUT, R22

	ldi r22, BIT5
	sts PORTD_OUT, r22


LOOP:
;continuously transmit any character received by microcontroller back to computer		
	; init USART		;go to subroutines
	; init EBI 
	; call interrupt

	;load green LED
	;toggle
	sts PORTD_OUTTGL, r22

	rjmp LOOP		;loop forever
		
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
	; Configure USART mode
		; asynch, even parity, 8 data bits, 1 start 1 stop bit, 57,600 bps baud rate
	; Set baud rate
;basic init without external out/in
	
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
************************************************************************************
* Name:     INTERRUPT_INIT
* Purpose:  This subroutine initializes the interrupt and PMIC
* Inputs:   None			 
* Outputs:  None
* Affected: 
***********************************************************************************/
INTERRUPT_INIT:
/************************************************************************************/
	;23.15
	ldi r16, 0x04							;	Specify source of interrupt pin
	sts PORTE_INT0MASK, r16 							;	Mask the pin with value from equate statement
	;sts usartd0_

	ldi r16, 0x04
	sts PORTE_OUT, r16

	ldi r16, 0x04
	sts PORTE_DIRCLR, r16
	
	ldi r16, 0x01 							;	Sets the level of the interrupt
	sts PORTE_INTCTRL, r16								;	Stores low level interrupt signal into PORTE USART

	ldi r16, 0x03									;	Sets the detection of the change
	sts PORTE_PIN0CTRL, r16 							;	Set the specifications to a rising edge detection

	ldi r16, 0x01						;	Initializes the PMIC controller values
	sts PMIC_CTRL, r16 
	
	sei 												;	Set Global Interrupt Flag
	ret

	;sei
	;ret
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
	push r16
RX_POLL: ;necessary?
	lds r16, USARTD0_STATUS		; check status register if character has been received
	sbrs r16, 7					; poll receive flag
	rjmp RX_POLL				; if not received (not set), loop
	lds r16, USARTD0_DATA 		; else, if set, read char from appropriate buffer
; return character to the calling procedure
	pop r16
	ret				; return from subroutine


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

/************************************************************************************
* Name:     OUT_STRING
* Purpose:  This subroutine will output a string of arbitrary length from program memory,
*			pointed to by Z pointer, to the transmit pin of a chosen USART mode
* Inputs:   r16 (character saved) 
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

/************************************************************************************/
/**********************************INTERRUPTS****************************************/
/************************************************************************************
* Name:     RXC_INTERRUPT
* Purpose:  This interrupt will retransmit characters received by microcontroller 
*			back to the computer.
* Inputs:   r16 (character saved) 
* Outputs:  None
* Affected: 
***********************************************************************************/
RXC_INTERRUPT: 
/************************************************************************************/
	;retransmit characters received by microcontroller back to the computer
	push r16
	lds r16, CPU_SREG
	push r16

	rcall IN_CHAR	;change to port d?
	rcall OUT_CHAR

	pop r16
	sts CPU_SREG, r16
	pop r16
	reti
;-------------------------------------------------------------------------------	
;HELPFUL READING:
;	8331 SECTION 23 - USART
;	OOTB uPAD Schematic
;	SCI_Polling.asm
