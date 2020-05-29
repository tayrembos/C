 /*******************************************************************************
* 
* Lab #5,Sec 6: USART, Character Input
* Name:			Taylor Rembos
* Description:	This program configures the appropriate USART module to input a
*				character string, name, of arbitrary length				
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
	.equ out_string_size = 0x0FFF		; out table size
	.equ out_copy_size = 0x0FFF
;-------------------------------------------------------------------------------
; DATA MEMORY SECTION -- allocate space in data memory
.DSEG				; data memory
.org 0x2000
OUTPUT_STRING: 
	.BYTE out_string_size	;0x2000-0x0FFF

.org 0x3000
OUT_COPY:
	.byte out_copy_size

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
	
	;setup Y pointer
		; config Y pointer to point to beginning of data mem - output table
	ldi YL, low(OUTPUT_STRING)	;low byte Y to data mem
	ldi YH, high(OUTPUT_STRING)	;high byte Y to data mem

	ldi ZL, low(OUTPUT_STRING)
	ldi ZH, high(OUTPUT_STRING)

	rcall USART_INIT	; init USART 
	nop
	;input complete name using IN_STRING
	; echo input into data memory using OUT_STRING

LOOP:
;continuously transmit any character received by microcontroller back to computer		
	rcall IN_STRING		; go to subroutine
	nop
	;rcall COPY_TABLE
	rcall OUT_STRING		
	rjmp LOOP			; loop forever
		
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
	;St X+, r17								
	ret						; return from subroutine

;copy table from Y into Z
COPY_TABLE:
	ld r18, X+
	st Z+, r18
	cpi r18, 0
	brne COPY_TABLE
	ret

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
JUMP_STRING:
	elpm r16, Z+		; read character pointed to by Z, increment pointer
	cpi r17, 0		; compare with NULL value
	brne SKIP		; if char is non-null, call OUT_CHAR subroutine
	ret				; else, if null, return from subroutine
	
SKIP:
	rcall OUT_CHAR
	rjmp JUMP_STRING	; return to beginning

/************************************************************************************
* Name:     IN_CHAR
* Purpose:  This subroutine will receive a single character within the USART module
*			and return the received character to the calling procedure via
*			general purpose regs r16/r17
* Inputs:   r17 (character saved) 
* Outputs:  None
* Affected: 
***********************************************************************************/
IN_CHAR:
/************************************************************************************/
RX_POLL: ;necessary?
	lds r17, USARTD0_STATUS		; check status register if character has been received
	sbrs r17, 7					; poll receive flag
	rjmp RX_POLL				; if not received (not set), loop
	lds r17, USARTD0_DATA 		; else, if set, read char from appropriate buffer
; return character to the calling procedure
	ret				; return from subroutine

/************************************************************************************
* Name:     IN_STRING
* Purpose:  This subroutine will receive a string of arbirary length within the USART module
*			and return the received string to the calling procedure via
*			general purpose regs r16/r17
* Inputs:   r16 (character saved) 
* Outputs:  None
* Affected: 
***********************************************************************************/
IN_STRING:
/************************************************************************************/

IN_STRING_LOOP:
rcall IN_CHAR

; cont read charcters from USART 
; if char != carriage return (CR, 0x0D) NOR backspace (BS, 0x08)
;lds r16, USARTD0_DATA ;!! check - read character from USART
;cpi r16, 0x08 	; check if backspace pressed
cpi r17, 0x7f ;backspace
breq PRESS_BACKSPACE ; if pressed, go to PRESS_BACKSPACE
cpi r17, 0x0D	; check if enter pressed
;cpi r16, 0x80
breq PRESS_ENTER	; if pressed, go to PRESS_ENTER

st Y+, r17			; if neither pressed, store in next data mem space with Y index
rjmp IN_STRING_LOOP					; return from subroutine

PRESS_BACKSPACE:
	st -Y, r17	; decrement Y for rewrite
	rjmp IN_STRING_LOOP

PRESS_ENTER:
	ldi r17, 0x00	; null
	st Y+, r17		; store null at end of input string
	ret

;-------------------------------------------------------------------------------	
;HELPFUL READING:
;	8331 SECTION 23 - USART
;	OOTB uPAD Schematic
;	SCI_Polling.asm
