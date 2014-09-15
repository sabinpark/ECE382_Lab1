;-------------------------------------------------------------------------------
; Title:		Lab 1 - A Simple Calculator
; Name:			C2C Sabin Park, USAF
; Date:			8 September 2014
; Instructor:	Dr. Coulston and his pug
;
; This program acts as a simple calculator
;
; NOTE: This program has passed all of the provided test cases!  This code works!
;-------------------------------------------------------------------------------

	.cdecls C,LIST,"msp430.h"	; BOILERPLATE	Include device header file
 	.text						; BOILERPLATE	Assemble into program memory
	.retain						; BOILERPLATE	Override ELF conditional linking and retain current section
	.retainrefs					; BOILERPLATE	Retain any sections that have references to current section
	.global main				; BOILERPLATE	Project -> Properties and select the following in the pop-up
								; Build -> Linker -> Advanced -> Symbol Management
								;    enter main into the Specify program entry point... text box

	.data

; sets constant labels for each of the cases
ADD_OP:		.equ	0x11
SUB_OP:		.equ	0x22
MUL_OP:		.equ	0x33
CLR_OP:		.equ	0x44
END_OP:		.equ	0x55
; sets constant labels for other important values
MIN:		.equ	0
MAX:		.equ	255
MAX_plus:	.equ	256			; used for saturation

	.bss	store, 0x40
	.text

; change the input of ts with any of the three possible test cases commented below
; currently testing the A-functionality
ts:	.byte	0x22, 0x11, 0x22, 0x22, 0x33, 0x33, 0x08, 0x44, 0x08, 0x22, 0x09, 0x44, 0xff, 0x11, 0xff, 0x44, 0xcc, 0x33, 0x02, 0x33, 0x00, 0x44, 0x33, 0x33, 0x08, 0x55

	; (*) Required functionality
	;	input: 0x11, 0x11, 0x11, 0x11, 0x11, 0x44, 0x22, 0x22, 0x22, 0x11, 0xCC, 0x55
	;	output: 0x22, 0x33, 0x00, 0x00, 0xCC
	; (*) B functionality
	;	input: 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0xDD, 0x44, 0x08, 0x22, 0x09, 0x44, 0xFF, 0x22, 0xFD, 0x55
	;	output:	0x22, 0x33, 0x44, 0xFF, 0x00, 0x00, 0x00, 0x02
	; (*) A functionality
	;	input: 0x22, 0x11, 0x22, 0x22, 0x33, 0x33, 0x08, 0x44, 0x08, 0x22, 0x09, 0x44, 0xff, 0x11, 0xff, 0x44, 0xcc, 0x33, 0x02, 0x33, 0x00, 0x44, 0x33, 0x33, 0x08, 0x55
	;	output: 0x44, 0x11, 0x88, 0x00, 0x00, 0x00, 0xff, 0x00, 0xff, 0x00, 0x00, 0xff

;-------------------------------------------------------------------------------
;			Main
;-------------------------------------------------------------------------------

; run at the very beginning to initialize important registers
main:
		mov.w   #__STACK_END,SP			; BOILERPLATE	Initialize stackpointer
		mov.w   #WDTPW|WDTHOLD,&WDTCTL 	; BOILERPLATE	Stop watchdog timer

		mov.w	#store, R9		; R9 is the pointer to RAM
		mov.w	#ts, R7			; R7 is the pointer to the test string
								; will always point last to an operation
		mov.b	@R7+, R8		; R8 = value @ R7, then increment R7

; primary loop that starts off by reading an operation (add, sub, mul, clr, or end)
ADD:
		cmp.b	#ADD_OP, 0(R7)
		jnz		SUB
		inc.w	R7				; R7 now points to the second operand
		mov.b	@R7, R12		; store the 2nd operand in R12
		add.w	R12, R8			; R8  <--  R8 + R12
		jmp		bounds			; check the saturation (set min and max if outside the bounds)
SUB:
		cmp.b	#SUB_OP, 0(R7)
		jnz		MUL
		inc.w	R7
		mov.b	@R7, R12
		sub.w	R12, R8
		jmp		bounds
MUL:
		cmp.b	#MUL_OP, 0(R7)
		jnz		CLR
		inc.w	R7
		jmp		multiply
CLR:
		cmp.b	#CLR_OP, 0(R7)
		jnz		END
		inc.w	R7				; R7 points to the first operand
		mov.b	@R7, R8			; store value @ R7 into R8
		clr.b	0(R9)			; sets the value at R9 to 0
		inc.w	R9				; R9 points to the next place in RAM
		inc.w	R7				; R7 points to an operation
		jmp		ADD				; go back to the top
END:
		cmp.b	#END_OP, 0(R7)
		jmp		infinite		; infinite loop!

; the accumulator value (R8) is checked and made sure it is between 0 and 255 (inclusive)
bounds:
		cmp.w	#MIN, R8			; R8 - 0
		jl		setMin			; if R8 currently has a value less than 0, set R8 = 0
		cmp.w	#MAX_plus, R8		; R8 - 256
		jge		setMax			; else if R8 is greater than or equal to 256, set R8 = 255

; writes R8 into RAM, increments all pointers, and goes back into the primary loop
returnLoop:
		mov.b	R8, 0(R9)		; writes R8 into RAM
		inc.w	R9
		inc.w	R7
		jmp		ADD				; back to primary loop

; if R8 is less than 0, set R8 = 0
setMin:
		mov.b	#MIN, R8
		jmp		returnLoop
; if R8 is bigger than 255, set R8 = 255
setMax:
		mov.b	#MAX, R8
		jmp		returnLoop

; clears temp register and moves a copy of value at R7 into R11
multiply:
		clr.w	R12				; register that will hold the product
		mov.b	0(R7), R11		; R11 holds value at R7
								; r8 = 1st operand, R7 = 2nd operand

; uses the shift and add method to multiply two values
shift:
		cmp		#0, R8			; if R8 is less than 0, then jump to "setR8"
		jz		setR8			; sets value of R8
		rra		R8				; halves R8
		jnc		double			; if there is no carry, then double R11
		add		R11, R12		; R12 = R12 + R11
; doubles R11 using a left shift
double:
		rla		R11				; doubles R11
		jmp		shift			; jump back to "shift"

; at this point, set R8's value and check saturation
setR8:
		mov.w	R12, R8
		jmp		bounds

infinite:
		jmp infinite

;-------------------------------------------------------------------------------
;			System Initialization
;-------------------------------------------------------------------------------
	.global __STACK_END				; BOILERPLATE
	.sect 	.stack					; BOILERPLATE
	.sect   ".reset"				; BOILERPLATE		MSP430 RESET Vector
	.short  main					; BOILERPLATE
