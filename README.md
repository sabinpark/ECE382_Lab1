ECE 382 Lab1
===========

## Purpose
The purpose of Lab 1 is to familiarize myself with the MSP430 and create my first assembly language program. The end objective is to solidify my understanding of assembly coding and become better at programming using higher level skills.

## Prelab

#### Flowchart
![alt test](https://raw.githubusercontent.com/sabinpark/ECE382_Lab1/master/images/flowchart.jpg "Lab 1 Flowchart")

#### Pseudo Code

*NOTE:* the following is pseudo code and is not meant to compile

```
set constant labels such as add, sub, mul, clr, end, max, and min

R7:  pointer
R8:  accumulator
R9:  RAM
R12: temporary holder (post-operation)

main:
  initialize R7 to beginning of ROM location where instructions are stored (0xC000)
  initialize R9 to RAM (0x0200)
  
  R8  <--  @R7+   ; put value at R7 into R8, increment R7 (R7 now points to an operation)
  go to "loop"
end main
  
loop:
  switch @R7
    11:
      increment R7
      R12  <--  @R7
      R8  <--  R8 + R12
      increment R7
      go to "bounds"
    22:
      increment R7
      R12  <--  @R7
      R8  <--  R8 - R12
      increment R7
      go to "bounds"
    33:
      increment R7
      R12  <--  @R7
      R8  <--  R8 * R12
      increment R7
      go to "bounds"
    44:
      increment R7
      R8  <--  @R7
      increment R7
      @R9+  <--  0
      go to "loop"
    55:
      infinite loop
  end switch-case
end loop

bounds:
  if(R8 > 255)
    R8  <--  255
  else if(R8 < 0 )
    R8  <--  0
  end if-else
  
  0(R9)  <--  R8  ; write down the value of R8 into R9
  increment R7    ; now points to another operation again
  increment R9
end bounds

infinite loop:
  infinite loop
end infinite loop
```

## Lab

### Update
*The .asm file has been completed and turned in with a final commit (for the code portion) at apx. 1638 on 10 September 2014.*

| Item | Status | Date |
|-------|-------|-------|
| Required Functionality | Complete | 10 September 14 |
| B Functionality | Complete | 10 September 14 |
| A Functionality | Complete | 10 September 14 |

### Required Functionality
The required functionality was to set the inputs and outputs of the calclator in memory locations. The input was in ROM, starting at the memory location of 0xc000. The output was stored in RAM, starting with the location, 0x0200. Furthermore, the input operands and output results were required to be within the range of 0 to 255 (unsigned byte).

In order to function as a calculator, the operations were assigned the following values:

| OPERATION | HEX VALUE | DESCRIPTION |
|-------|-------|-------|
| ADD | 0x11 | Adds two operands |
| SUB | 0x22 | Subtracts two operands |
| CLR | 0x44 | Clears the accumulator and stores next value as an operand |
| END | 0x55 | Ends the program by going to an infinite loop |

The required functionality was very easy to complete using the provided assembly instructions. 

It is important to note that initially, the program was designed to designate each pointer (pointer to RAM and to ROM), and also read in the first operand from the test string. Furthermore it is even more important to note that after reading the first operand, the pointer in ROM was left pointing at the operation. This detail is crucial for the proper running of the primary loop of this program.

I used the provided switch-case example to allow the program to know which operation is being used. The simple switch-case statement is as follows:

```
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
```

As we may see from above, the loop will always start by reading an operation, assuming that the first operand is already in the accumulator. The program will end when the switch-case reads the value 0x55.

### B Functionality
The B functionality was a little bit tricky at first due to the program neglecting the carry bit after adding two values over the cap of 255. However, the problem was soon fixed by reading the *word* of the answer instead of the *byte*. This accounted for the potential carry bit, and allowed the program to correctly saturate my values to be within the min and max limits.

Aside from that minor roadblock, the functionality was very easy to implement using jumps and loops.

```
bounds:
		cmp.w	#MIN, R8			; R8 - 0
		jl		setMin			; if R8 currently has a value less than 0, set R8 = 0
		cmp.w	#MAX_plus, R8		; R8 - 256
		jge		setMax			; else if R8 is greater than or equal to 256, set R8 = 255
```

As shown above, I simply compared the accumulator value with the constant min value (0x00), and if the value was less than 0, then the program would jump to a loop that would set R8 to 0. Likewise, if the value was greater than the constant max value (0xFF), then the program would jump to set R8 to 255.

### A Functionality
The A functionality consisted of creating a multiplication operation in the program. This extra detail seemed easy at first because I could have created a loop that multiplied A*B by adding A to itself in a loop that went through B number of iterations. However, the task was meant to be accomplished using O(log n) instead of O(n). And thus, I had to find a different method of multiplying two numbers. 

Eventually, I used a method called *shift and add*, which fulfilled the requirement of working at O(log n) time. This method takes in two values, A and B. The first value is shifted to the right by one bit. This basically divides the value (let us say A) in half. The other value is shifted to the left by one bit. As we know, this basically multiplies the value (let us say B) by 2. If A/2 leaves a carry bit, then the corresponding B value is added to the result. *NOTE:* the result is cleared to zero before the multiplication process begins. If A/2 does not leave a carry bit (even answer), then the corresponding B value is not added onto the final product. An example of this process is shown below where A = 11 and B = 3:

![alt test](https://raw.githubusercontent.com/sabinpark/ECE382_Lab1/master/images/shift_add.PNG "shift and add example")

*NOTE:* the value corresponding to this multiplication operation was set to the constant value of 0x33.

### Debugging
When testing the program in the debugging mode, there were no significant setbacks. Minor setbacks included things such as improperly using a mov.b when I should have used a mov.w instead. Another setback was the improper value being incremented. I quickly realized that I should be incrementing by words instead of bytes. Finally, as mentioned above, I had to read a word value to determine if my result was over the maximum value of 255. In the end, these problems were fixed promptly without too much trouble.

### Testing Methodology
To test the preliminary code, I ran through the class-given example (lecture handout from lesson 8):
```
0x21 0x22 0x01 0x44 0x14 0x11 0x12 0x55
```
*NOTE:* I added the 0x55 instruction to test the end of the program.
To test this program, I ran the debugger and first cleared my RAM memory values to 0x00. I then ran the program and kept track of the ROM pointer, the RAM pointer, and the appropriate registers. After each execution of an operation, I was able to see whether the correct value was being stored in RAM.

After each addition of functionality, I tested my program with the lab-provided test cases. These test cases are as follows:

* Required Functionality:

Input: 0x11, 0x11, 0x11, 0x11, 0x11, 0x44, 0x22, 0x22, 0x22, 0x11, 0xCC, 0x55

Result: 0x22, 0x33, 0x00, 0x00, 0xCC

* B Functionality:

Input: 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0xDD, 0x44, 0x08, 0x22, 0x09, 0x44, 0xFF, 0x22, 0xFD, 0x55

Result: 0x22, 0x33, 0x44, 0xFF, 0x00, 0x00, 0x00, 0x02

* A Functionality:

Input: 0x22, 0x11, 0x22, 0x22, 0x33, 0x33, 0x08, 0x44, 0x08, 0x22, 0x09, 0x44, 0xff, 0x11, 0xff, 0x44, 0xcc, 0x33, 0x02, 0x33, 0x00, 0x44, 0x33, 0x33, 0x08, 0x55

Result: 0x44, 0x11, 0x88, 0x00, 0x00, 0x00, 0xff, 0x00, 0xff, 0x00, 0x00, 0xff

### Conclusion
The simple calculator turned out to be a success. It properly read in values from ROM, performed the appropriate calculations, and finally stored the correct results in RAM. All parts of the functionality were met in this lab. I learned the importance of having solid pseudo code to help out with actual programming. Not having solid pseudo code in the beginning made it very confusing to follow my train of thought and complete the assignment. However, after reworking parts of my pseudo code, I was able to quickly accomplish the task and pick out the minor details that may haved resulted in bugs. This lab was also useful for me to understand the importance of using breakpoints while debugging my program.


## Documentation
I used Wikipedia to find information on how to efficiently do multiplication. I followed the example labeled as "peasant multiplication". Link is:  http://en.wikipedia.org/wiki/Multiplication_algorithm
I also received EI from Dr. Coulston to review the methodology needed for setting the pointer register. No other help received. *UPDATE:* Dr. Coulston assisted me in creating my folders (code and images). For some reason, parts of the readme file have been altered after this change; I have searched through the readme and corrected the unexpected changes.
