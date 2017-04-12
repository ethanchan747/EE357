
// Place static data declarations/directives here
  		.data
 		risc_code:	.long 0x0810000a, 0x04040000, 0x08300000, 0x084000ff
					.long 0x0dd00000,0x12c00008, 0x09200001, 0x20900001
					.long 0x09b00004,0x108fffec,0x81000000

		registers:	.long 0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0
		memory:		.long 0x0,0xff,0x1,0x2,0xff,0xff,0x0,0xf,0xff,0xa,0xff

// Replace declaration below.
mybuf:	.space 80
mymsg:  .asciz "ASM template for EE 357\n"  // Remember to put and get
prmpt0: .asciz "Here is an integer:\n"		// strings terminated with
prmpt1: .asciz "Enter a string:\n"          // newline characters
prmpt2: .asciz "Enter an integer:\n"
  		.text
		.global _main
		.global main
		.global mydat
		.include "../Project_Headers/ee357_asm_lib_hdr.s"

_main:
main:
BSR GPIO_SETUP
BSR ADDRESS_REGISTER_SETUP
Loop:
BSR STORE_VALUES
BSR COMPARE_OPCODES
BSR COMPARE_a0
BNE.s Loop
BEQ.w Loop2

GPIO_SETUP:
//Setting up GPIO
move.l #0x00000000, d0
move.b d0, 0x4010006F // Set pins to be used as GPIO
move.b d0, 0x40100074 // Set pins to be used as GPIO
move.b d0, 0x4010002C // Set DIP switches as input
move.l #0xFFFFFFF, d0
move.b d0, 0x40100027 // Set LED's as output

move.b #0x00000000, d1
move.b d1, 0x4010000F // Light up the LED's as the byte in d1
//Finish setting up GPIO
RTS

ADDRESS_REGISTER_SETUP:
movea.l #risc_code,a0 //a0 for the PC (Program Counter)
movea.l #registers,a1 // a1 for the registers, R0 ~ R7
movea.l #memory,a2 // a2 for the (data) memory
RTS

STORE_VALUES:
//initialize registers
move.l #0x00000000, d0
move.l d0, d1
move.l d0, d2
move.l d0, d3
move.l d0, d4
move.l d0, d5
move.l d0, d6
move.l d0, d7

move.b (a0), d1 // captures the first 8 bts of the risc_code
LSR.l #2, d1 // shifts 8 bits to the right two so gets rid of last two bits.
// d1 now contains the opcode
// DEFINITOIN: d1 = opcode, d2 = rs(3 bits), d3 = rt(3bits), d4 = #Imm., d5 = rd(3 bits)
//obtained by shifting left
move.l (a0), d2
LSL.l #6 ,d2 // first 3 bits of d2 is rs(3 bits)
move.l d2, d3
LSL.l #3, d3 // first 3 bits of d3 is rt(3bits)
move.l d3, d4
LSL.l #3, d4 // first 20 bits of d4 is #Imm.
move.l d4, d5 // If using ADD first 3 bits of d5 is rd(3 bits)
// Okay now shift right accordingly
LSR.l #8, d2
LSR.l #8, d2
LSR.l #8, d2
LSR.l #5, d2

LSR.l #8, d3
LSR.l #8, d3
LSR.l #8, d3
LSR.l #5, d3

LSR.l #8, d4
LSR.l #4, d4

LSR.l #8, d5
LSR.l #8, d5
LSR.l #8, d5
LSR.l #5, d5
// Now d1 = opcode, d2 = rs(3 bits), d3 = rt(3bits), d4 = #Imm., d5 = rd(3 bits)
RTS

COMPARE_OPCODES:
// Compare opcodes
CMPI.l #0x00000001, d1 // ADD operation decimal may or may not work (000001)
BEQ.s ADDop
CMPI.l #0x00000002, d1 //ADDI operation (000010)
BEQ.s ADDIop
CMPI.l #0x00000003, d1 // LOAD operation (000011)
BEQ.s LOADop
CMPI.l #0x00000004, d1 // BNE operation (000100)
BEQ.s BNEop
CMPI.l #0x00000008, d1 // SUBI operation (001000)
BEQ.w SUBIop
CMPI.l #0x00000020, d1 // DISP.B operation (100000)
BEQ.w DISPop

ADDop:
move.l a1, d6
LSL.l #2, d2
ADD.l d2, d6
movea.l d6, a3
move.l (a3), d6

move.l a1, d7
LSL.l #2, d3
ADD.l d3, d7
movea.l d7, a3
move.l (a3), d7

ADD.l d6, d7

move.l a1, d6
LSL.l #2, d5
ADD.l d5, d6
movea.l d6, a3
move.l d7, (a3)
moveq.l #4, d6 // puts #4 into d6
ADDA.l d6, a0 // increments a0
RTS

ADDIop:
move.l a1, d6
LSL.l #2, d2
ADD.l d2, d6
movea.l d6, a3
move.l (a3), d7

ADD.l d4, d7

move.l a1, d6
LSL.l #2, d3
ADD.l d3, d6
movea.l d6, a3
move.l d7, (a3)
moveq.l #4, d6 // puts #4 into d6
ADDA.l d6, a0 // increments a0
RTS

LOADop: // ASKI WHAT STARTING ADDRESS OF MEMORY MEANS FOR NOW IT a2
move.l a2, d6
ADD.l d4, d6	//no need to multiply by 4 SANG byte addressable

move.l a1, d7
LSL.l #2, d2
ADD.l d2, d7
movea.l d7, a3
move.l (a3), d7

ADD.l d6, d7
movea.l d7, a4

move.l a1, d6
LSL.l #2, d3
ADD.l d3, d6
movea.l d6, a3

move.l (a4), (a3)
moveq.l #4, d6 // puts #4 into d6
ADDA.l d6, a0 // increments a0
RTS

BNEop: // is there a special case for negative numbers? YES
move.l a1, d6
LSL.l #2, d2
ADD.l d2, d6
movea.l d6, a3
move.l (a3), d6

move.l a1, d7
LSL.l #2, d3
ADD.l d3, d7
movea.l d7, a3
move.l (a3), d7

CMP.l d6, d7
BEQ.s SKIP
move.l d4, d6
LSR.l #8, d6
LSR.l #8, d6
LSR.l #3, d6
CMPI.l #0x00000000, d6
BEQ.s POSITIVE
ADDI.l #0xFFF00000, d4
POSITIVE:
ADDA.l d4, a0
RTS
SKIP:
moveq.l #4, d6 // puts #4 into d6
ADDA.l d6, a0 // increments a0
RTS

SUBIop:
move.l a1, d6
LSL.l #2, d2
ADD.l d2, d6
movea.l d6, a3
move.l (a3), d6

SUB.l d4, d6

move.l a1, d7
LSL.l #2, d3
ADD.l d3, d7
movea.l d7, a3
move.l d6, (a3)

moveq.l #4, d6 // puts #4 into d6
ADDA.l d6, a0 // increments a0
RTS

DISPop:
move.l a1, d6
LSL.l #2, d2
ADD.l d2, d6
movea.l d6, a3
move.l (a3), d7
move.b d7, 0x4010000F // Light up the LED's as the byte in (a1)
moveq.l #4, d6 // puts #4 into d6
ADDA.l d6, a0 // increments a0
moveq.l #1, d0
RTS

COMPARE_a0:
CMPI.l #0x00000001, d0
RTS

Loop2:
moveq.l #0x00000001, d0 // dummy task. Program is finished
//done

//------- Template Test: Replace Me ----- //
		// Prints welcome message
		movea.l	#mymsg,a1
		jsr		ee357_put_str
		// Prints a string and an integer to the screen
		movea.l	#prmpt0,a1
		jsr		ee357_put_str
		move.l  #357,d1
		jsr		ee357_put_int

//======= Let the following few lines always end your main routing ===//
//------- No OS to return to so loop ---- //
//------- infinitely...Never hits rts --- //
inflp:	bra.s	inflp
		rts

//------ Defines subroutines here ------- //
//------  Replace sub1 definition ------- //
sub1:	clr.l d0
		rts
