/*
 * asm.s
 *
 * author: Furkan Cayci and Ugur kilinc
 *
 * description: Added the necessary stuff for turning on the green LED on the 
 *   G031K8 Nucleo board. Mostly for teaching.
 */


.syntax unified
.cpu cortex-m0plus
.fpu softvfp
.thumb


/* make linker see this */
.global Reset_Handler

/* get these from linker script */
.word _sdata
.word _edata
.word _sbss
.word _ebss


/* define peripheral addresses from RM0444 page 57, Tables 3-4 */
.equ RCC_BASE,         (0x40021000)          // RCC base address
.equ RCC_IOPENR,       (RCC_BASE   + (0x34)) // RCC IOPENR register offset

.equ GPIOA_BASE,       (0x50000000)          // GPIOA base address
.equ GPIOA_MODER,      (GPIOA_BASE + (0x00)) // GPIOA MODER register offset
.equ GPIOA_ODR,        (GPIOA_BASE + (0x14)) // GPIOA ODR register offset




/* vector table, +1 thumb mode */
.section .vectors
vector_table:
	.word _estack             /*     Stack pointer */
	.word Reset_Handler +1    /*     Reset handler */
	.word Default_Handler +1  /*       NMI handler */
	.word Default_Handler +1  /* HardFault handler */
	/* add rest of them here if needed */


/* reset handler */
.section .text
Reset_Handler:
	/* set stack pointer */
	ldr r0, =_estack
	mov sp, r0

	/* initialize data and bss 
	 * not necessary for rom only code 
	 * */
	bl init_data
	/* call main */
	bl main
	/* trap if returned */
	b .


/* initialize data and bss sections */
.section .text
init_data:

	/* copy rom to ram */
	ldr r0, =_sdata
	ldr r1, =_edata
	ldr r2, =_sidata
	movs r3, #0
	b LoopCopyDataInit

	CopyDataInit:
		ldr r4, [r2, r3]
		str r4, [r0, r3]
		adds r3, r3, #4

	LoopCopyDataInit:
		adds r4, r0, r3
		cmp r4, r1
		bcc CopyDataInit

	/* zero bss */
	ldr r2, =_sbss
	ldr r4, =_ebss
	movs r3, #0
	b LoopFillZerobss

	FillZerobss:
		str  r3, [r2]
		adds r2, r2, #4

	LoopFillZerobss:
		cmp r2, r4
		bcc FillZerobss

	bx lr


/* default handler */
.section .text
Default_Handler:
	b Default_Handler


/* main function */
.section .text
main:
	/* enable GPIOA clock, bit2 on IOPENR */
	ldr r6, =RCC_IOPENR
	ldr r5, [r6]
	/* movs expects imm8, so this should be fine */
	movs r4, 0x1
	orrs r5, r5, r4
	str r5, [r6]

	/* setup PA0-1-4-5-6-7-11-12 for leds 1-8 for bits from 0 to  in MODER */
	ldr r6, =GPIOA_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =#0xFF00	  // 	0011 1100 0000 1111 1111 0000 1111  //  4 led için FF00 -> 1111 1111 0000 0000 ( 4-5-6-7 pin)
	movs r4,r4
	bics r5,r5,r4        // r4'= 1100 0011 1111 0000 0000 1111 0000   r5 = r5 & r4' ( r4 ün tersini alıyor)

    // kullanacagımız bütün pinleri 00 yaptıktan sonra istediğimiz modu seçebiliriz
	ldr r4, =#0x5500  // 	0001 0100 0000 0101 0101 0000 0101  //            5500 ->  0101 0101 0000 0000
	movs r4,r4
	orrs r5,r5,r4
	str r5, [r6]

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =#0xF0  // 0001 1000 1111 0011  // 4 pin için F0 -> 1111 0000
	movs r4, r4
	orrs r5, r5, r4
	str r5, [r6]

				//  If r1 is 0 , return bl (142) and (153)


	/* this should never get executed */
	nop

