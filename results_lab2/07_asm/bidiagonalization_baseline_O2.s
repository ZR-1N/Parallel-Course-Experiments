	.arch armv8.2-a+crypto+crc+dotprod+fp16fml
	.file	"bidiagonalization.cpp"
	.text
	.section	.text._ZNSt12_Vector_baseIdSaIdEED2Ev,"axG",@progbits,_ZNSt12_Vector_baseIdSaIdEED5Ev,comdat
	.align	2
	.p2align 4,,11
	.weak	_ZNSt12_Vector_baseIdSaIdEED2Ev
	.type	_ZNSt12_Vector_baseIdSaIdEED2Ev, %function
_ZNSt12_Vector_baseIdSaIdEED2Ev:
.LFB3968:
	.cfi_startproc
	mov	x2, x0
	ldr	x0, [x0]
	cbz	x0, .L1
	ldr	x1, [x2, 16]
	sub	x1, x1, x0
	b	_ZdlPvm
	.p2align 2,,3
.L1:
	ret
	.cfi_endproc
.LFE3968:
	.size	_ZNSt12_Vector_baseIdSaIdEED2Ev, .-_ZNSt12_Vector_baseIdSaIdEED2Ev
	.weak	_ZNSt12_Vector_baseIdSaIdEED1Ev
	.set	_ZNSt12_Vector_baseIdSaIdEED1Ev,_ZNSt12_Vector_baseIdSaIdEED2Ev
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align	3
.LC0:
	.string	"to_bidiagonal: requires m >= n"
	.align	3
.LC1:
	.string	"cannot create std::vector larger than max_size()"
	.text
	.align	2
	.p2align 4,,11
	.global	_Z13to_bidiagonalRK6MatrixRS_S2_
	.type	_Z13to_bidiagonalRK6MatrixRS_S2_, %function
_Z13to_bidiagonalRK6MatrixRS_S2_:
.LFB3680:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA3680
	stp	x29, x30, [sp, -320]!
	.cfi_def_cfa_offset 320
	.cfi_offset 29, -320
	.cfi_offset 30, -312
	mov	x29, sp
	stp	x19, x20, [sp, 16]
	.cfi_offset 19, -304
	.cfi_offset 20, -296
	mov	x19, x0
	stp	x21, x22, [sp, 32]
	.cfi_offset 21, -288
	.cfi_offset 22, -280
	ldp	w21, w0, [x0]
	stp	x23, x24, [sp, 48]
	stp	x25, x26, [sp, 64]
	stp	d8, d9, [sp, 96]
	stp	d10, d11, [sp, 112]
	str	w0, [sp, 132]
	stp	x2, x1, [sp, 152]
	cmp	w0, w21
	.cfi_offset 23, -272
	.cfi_offset 24, -264
	.cfi_offset 25, -256
	.cfi_offset 26, -248
	.cfi_offset 72, -224
	.cfi_offset 73, -216
	.cfi_offset 74, -208
	.cfi_offset 75, -200
	bgt	.L199
	stp	x27, x28, [sp, 80]
	.cfi_offset 28, -232
	.cfi_offset 27, -240
	add	x28, x8, 8
	ldr	w0, [sp, 132]
	ldr	x20, [x19, 16]
	stp	w21, w0, [x8]
	ldr	x0, [x19, 8]
	str	xzr, [x8, 8]
	stp	xzr, xzr, [x28, 8]
	mov	x27, x8
	subs	x20, x20, x0
	beq	.L144
	mov	x0, 9223372036854775800
	cmp	x20, x0
	bhi	.L200
	mov	x0, x20
.LEHB0:
	bl	_Znwm
.LEHE0:
	mov	x3, x0
.L6:
	str	x3, [x27, 8]
	add	x20, x3, x20
	stp	x3, x20, [x28, 8]
	ldp	x1, x0, [x19, 8]
	sub	x19, x0, x1
	cmp	x1, x0
	beq	.L9
	mov	x0, x3
	mov	x2, x19
	bl	memmove
	mov	x3, x0
.L9:
	mul	w0, w21, w21
	add	x3, x3, x19
	str	x3, [x28, 8]
	cbz	w0, .L145
	sbfiz	x19, x0, 3, 32
	mov	x0, x19
.LEHB1:
	bl	_Znwm
	mov	x2, x19
	mov	x20, x0
	add	x19, x0, x19
	mov	w1, 0
	bl	memset
.L10:
	ldr	x2, [sp, 160]
	add	x1, x2, 8
	mov	x3, x1
	str	x3, [sp, 176]
	ldr	x0, [x2, 8]
	ldr	x1, [x1, 16]
	stp	w21, w21, [x2]
	str	x20, [x2, 8]
	stp	x19, x19, [x3, 8]
	cbz	x0, .L11
	sub	x1, x1, x0
	bl	_ZdlPvm
.L11:
	cmp	w21, 0
	ble	.L15
	ldr	x0, [sp, 160]
	mov	w1, 0
	fmov	d0, 1.0e+0
	ldrsw	x2, [x0, 4]
	ldr	x0, [x0, 8]
	add	x2, x2, 1
	lsl	x2, x2, 3
	.p2align 3,,7
.L16:
	add	w1, w1, 1
	str	d0, [x0]
	add	x0, x0, x2
	cmp	w1, w21
	bne	.L16
.L15:
	ldr	w0, [sp, 132]
	mov	x20, 0
	mov	x19, 0
	mul	w0, w0, w0
	cbz	w0, .L14
	sbfiz	x19, x0, 3, 32
	mov	x0, x19
	bl	_Znwm
	mov	x2, x19
	mov	x20, x0
	add	x19, x0, x19
	mov	w1, 0
	bl	memset
.L14:
	ldr	x2, [sp, 152]
	ldr	w3, [sp, 132]
	add	x1, x2, 8
	str	x1, [sp, 168]
	stp	w3, w3, [x2]
	mov	x3, x1
	ldr	x0, [x2, 8]
	ldr	x1, [x1, 16]
	str	x20, [x2, 8]
	stp	x19, x19, [x3, 8]
	cbz	x0, .L17
	sub	x1, x1, x0
	bl	_ZdlPvm
.L17:
	ldr	w0, [sp, 132]
	cmp	w0, 0
	ble	.L4
	ldr	x0, [sp, 152]
	mov	w1, 0
	fmov	d0, 1.0e+0
	ldrsw	x2, [x0, 4]
	ldr	x0, [x0, 8]
	add	x2, x2, 1
	lsl	x2, x2, 3
	.p2align 3,,7
.L20:
	ldr	w3, [sp, 132]
	add	w1, w1, 1
	str	d0, [x0]
	add	x0, x0, x2
	cmp	w1, w3
	bne	.L20
	sxtw	x0, w21
	mov	x1, x0
	str	x1, [sp, 192]
	mov	x0, 1152921504606846975
	cmp	x1, x0
	bhi	.L137
	ldr	x25, [sp, 192]
	mov	w19, w21
	mov	x22, 0
	mov	w26, 0
	fmov	d11, 2.0e+0
	lsl	x0, x25, 3
	str	x0, [sp, 208]
	ldr	w0, [sp, 132]
	mov	w24, w0
	sub	w20, w0, #1
	sbfiz	x1, x0, 3, 32
	str	x1, [sp, 216]
	adrp	x1, .LC2
	sub	w0, w0, #2
	str	w0, [sp, 184]
	ldr	d9, [x1, #:lo12:.LC2]
	sub	w1, w21, #1
	str	w1, [sp, 188]
	adrp	x1, .LC3
	ldr	d10, [x1, #:lo12:.LC3]
	.p2align 3,,7
.L21:
	lsl	x2, x25, 3
	str	x2, [sp, 136]
	stp	xzr, xzr, [sp, 224]
	str	xzr, [sp, 240]
	cbz	x25, .L22
	mov	x0, x2
	bl	_Znwm
.LEHE1:
	ldr	x2, [sp, 136]
	str	x0, [sp, 224]
	mov	x23, x0
	add	x3, x0, x2
	str	x3, [sp, 240]
	cmp	x3, x0
	beq	.L23
	mov	w1, 0
	str	x3, [sp, 144]
	bl	memset
	ldr	x3, [sp, 144]
	str	x3, [sp, 232]
	cmp	w19, 0
	ble	.L24
.L25:
	ldr	w1, [x27, 4]
	mov	x0, 0
	ldr	x4, [x28]
	sbfiz	x2, x1, 3, 32
	mul	w1, w1, w26
	add	x1, x22, x1, sxtw
	add	x1, x4, x1, lsl 3
	.p2align 3,,7
.L28:
	ldr	d0, [x1]
	add	x1, x1, x2
	str	d0, [x23, x0, lsl 3]
	add	x0, x0, 1
	cmp	w19, w0
	bgt	.L28
	cmp	x3, x23
	beq	.L154
.L24:
	movi	d8, #0
	mov	x0, x23
	.p2align 3,,7
.L29:
	ldr	d1, [x0], 8
	fmadd	d8, d1, d1, d8
	cmp	x3, x0
	bne	.L29
	fcmp	d8, #0.0
	bpl	.L26
	fmov	d0, d8
	bl	sqrt
	fmov	d8, d0
	b	.L32
	.p2align 2,,3
.L22:
	mov	x23, 0
	mov	x3, 0
	str	xzr, [sp, 224]
	str	xzr, [sp, 240]
.L23:
	str	x3, [sp, 232]
	cmp	w19, 0
	bgt	.L25
.L154:
	movi	d8, #0
	.p2align 3,,7
.L26:
	fsqrt	d8, d8
.L32:
	fcmpe	d8, d9
	bgt	.L163
.L33:
	add	w23, w26, 1
	cmp	w23, w21
	bge	.L76
	ldr	w0, [x27, 4]
	mov	w1, w23
	ldr	x3, [x28]
	sbfiz	x2, x0, 3, 32
	mul	w0, w23, w0
	add	x0, x22, x0, sxtw
	add	x0, x3, x0, lsl 3
	.p2align 3,,7
.L77:
	add	w1, w1, 1
	str	xzr, [x0]
	add	x0, x0, x2
	cmp	w1, w21
	bne	.L77
.L76:
	ldr	w0, [sp, 184]
	cmp	w0, w22
	bgt	.L201
.L75:
	ldr	x0, [sp, 224]
	cbz	x0, .L128
	ldr	x1, [sp, 240]
	sub	x1, x1, x0
	bl	_ZdlPvm
.L128:
	ldr	w0, [sp, 132]
	cmp	w23, w0
	beq	.L4
	sub	x25, x25, #1
	sub	w19, w19, #1
	add	x22, x22, 1
	sub	w24, w24, #1
	sub	w20, w20, #1
	mov	x0, 1152921504606846975
	cmp	x25, x0
	bhi	.L137
	mov	w26, w23
	b	.L21
	.p2align 2,,3
.L163:
	ldr	w0, [sp, 188]
	cmp	w0, w26
	ble	.L33
	ldp	x1, x0, [sp, 224]
	fneg	d0, d8
	ldr	d1, [x1]
	sub	x23, x0, x1
	str	x23, [sp, 144]
	stp	xzr, xzr, [sp, 272]
	fcmpe	d1, #0.0
	str	xzr, [sp, 288]
	fcsel	d8, d8, d0, ge
	cbz	x23, .L36
	mov	x0, 9223372036854775800
	cmp	x23, x0
	bhi	.L202
	mov	x0, x23
.LEHB2:
	bl	_Znwm
	mov	x3, x0
	add	x4, x0, x23
	ldp	x1, x0, [sp, 224]
	stp	x3, x3, [sp, 272]
	str	x4, [sp, 288]
	sub	x2, x0, x1
	cmp	x1, x0
	bne	.L141
.L38:
	ldr	d0, [x3]
	add	x2, x3, x2
	str	x2, [sp, 280]
	fadd	d0, d8, d0
	str	d0, [x3]
	cmp	x2, x3
	beq	.L39
	movi	d8, #0
	add	x1, x3, 8
	b	.L41
	.p2align 2,,3
.L203:
	ldr	d0, [x1], 8
.L41:
	fmadd	d8, d0, d0, d8
	cmp	x2, x1
	bne	.L203
	fcmpe	d8, d10
	bgt	.L164
.L39:
	ldr	x1, [sp, 144]
	mov	x0, x3
	bl	_ZdlPvm
	b	.L33
.L36:
	stp	xzr, xzr, [sp, 272]
	mov	x2, 0
	mov	x3, 0
	str	xzr, [sp, 288]
	cmp	x1, x0
	beq	.L204
.L141:
	mov	x0, x3
	str	x2, [sp, 200]
	bl	memmove
	mov	x3, x0
	ldr	x2, [sp, 200]
	b	.L38
	.p2align 2,,3
.L201:
	sxtw	x0, w20
	mov	x1, 1152921504606846975
	cmp	x0, x1
	bhi	.L205
	stp	xzr, xzr, [sp, 248]
	lsl	x2, x0, 3
	str	xzr, [sp, 264]
	cbz	x0, .L79
	mov	x0, x2
	str	x2, [sp, 144]
	bl	_Znwm
.LEHE2:
	ldr	x2, [sp, 144]
	str	x0, [sp, 248]
	mov	x3, x0
	add	x4, x0, x2
	str	x4, [sp, 264]
	cmp	x4, x0
	beq	.L80
	mov	w1, 0
	str	x4, [sp, 144]
	str	x0, [sp, 200]
	bl	memset
	ldr	x4, [sp, 144]
	str	x4, [sp, 256]
	cmp	w20, 0
	ldr	x3, [sp, 200]
	ble	.L81
.L82:
	ldr	w0, [x27, 4]
	mov	x1, 0
	ldr	x2, [x28]
	mul	w0, w26, w0
	add	x0, x22, x0, sxtw
	add	x0, x0, 1
	add	x0, x2, x0, lsl 3
	.p2align 3,,7
.L85:
	ldr	d0, [x0, x1, lsl 3]
	str	d0, [x3, x1, lsl 3]
	add	x1, x1, 1
	cmp	w20, w1
	bgt	.L85
	cmp	x4, x3
	beq	.L152
.L81:
	movi	d0, #0
	mov	x0, x3
	.p2align 3,,7
.L86:
	ldr	d1, [x0], 8
	fmadd	d0, d1, d1, d0
	cmp	x4, x0
	bne	.L86
	fcmp	d0, #0.0
	bpl	.L83
	bl	sqrt
	fmov	d8, d0
	b	.L89
	.p2align 2,,3
.L79:
	movi	d0, #0
	stp	xzr, xzr, [sp, 248]
	str	xzr, [sp, 264]
.L83:
	fsqrt	d8, d0
.L89:
	fcmpe	d8, d9
	bgt	.L165
.L90:
	ldr	w1, [sp, 132]
	add	w0, w26, 2
	cmp	w0, w1
	bge	.L127
	ldr	w3, [x27, 4]
	sxtw	x0, w0
	ldr	x4, [x28]
	sub	w2, w20, #2
	add	x2, x2, 1
	mov	w1, 0
	mul	w3, w26, w3
	lsl	x2, x2, 3
	add	x0, x0, x3, sxtw
	add	x0, x4, x0, lsl 3
	bl	memset
.L127:
	ldr	x0, [sp, 248]
	cbz	x0, .L75
	ldr	x1, [sp, 264]
	sub	x1, x1, x0
	bl	_ZdlPvm
	b	.L75
	.p2align 2,,3
.L4:
	mov	x0, x27
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldp	x25, x26, [sp, 64]
	ldp	x27, x28, [sp, 80]
	.cfi_remember_state
	.cfi_restore 28
	.cfi_restore 27
	ldp	d8, d9, [sp, 96]
	ldp	d10, d11, [sp, 112]
	ldp	x29, x30, [sp], 320
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 25
	.cfi_restore 26
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 19
	.cfi_restore 20
	.cfi_restore 74
	.cfi_restore 75
	.cfi_restore 72
	.cfi_restore 73
	.cfi_def_cfa_offset 0
	ret
.L165:
	.cfi_restore_state
	ldp	x1, x0, [sp, 248]
	fneg	d0, d8
	ldr	d1, [x1]
	sub	x2, x0, x1
	str	x2, [sp, 144]
	str	x2, [sp, 200]
	fcmpe	d1, #0.0
	stp	xzr, xzr, [sp, 272]
	str	xzr, [sp, 288]
	fcsel	d8, d8, d0, ge
	cbz	x2, .L93
	mov	x0, 9223372036854775800
	cmp	x2, x0
	bhi	.L206
	ldr	x0, [sp, 144]
.LEHB3:
	bl	_Znwm
.LEHE3:
	mov	x3, x0
	stp	x3, x3, [sp, 272]
	ldp	x1, x0, [sp, 248]
	ldr	x2, [sp, 144]
	add	x4, x3, x2
	str	x4, [sp, 288]
	sub	x2, x0, x1
	cmp	x1, x0
	bne	.L139
.L95:
	ldr	d0, [x3]
	add	x2, x3, x2
	str	x2, [sp, 280]
	fadd	d0, d8, d0
	str	d0, [x3]
	cmp	x3, x2
	beq	.L96
	movi	d8, #0
	add	x1, x3, 8
	b	.L98
	.p2align 2,,3
.L207:
	ldr	d0, [x1], 8
.L98:
	fmadd	d8, d0, d0, d8
	cmp	x2, x1
	bne	.L207
	fcmpe	d8, d10
	bgt	.L166
.L96:
	ldr	x1, [sp, 200]
	mov	x0, x3
	bl	_ZdlPvm
	b	.L90
.L93:
	stp	xzr, xzr, [sp, 272]
	mov	x2, 0
	mov	x3, 0
	str	xzr, [sp, 288]
	cmp	x0, x1
	beq	.L208
.L139:
	mov	x0, x3
	str	x2, [sp, 144]
	bl	memmove
	mov	x3, x0
	ldr	x2, [sp, 144]
	b	.L95
.L144:
	mov	x3, 0
	b	.L6
.L145:
	mov	x20, 0
	mov	x19, 0
	b	.L10
.L166:
	stp	xzr, xzr, [sp, 296]
	fdiv	d8, d11, d8
	str	xzr, [sp, 312]
	cbz	x25, .L100
	ldr	x0, [sp, 136]
.LEHB4:
	bl	_Znwm
.LEHE4:
	ldr	x2, [sp, 136]
	str	x0, [sp, 296]
	mov	x3, x0
	add	x4, x0, x2
	str	x4, [sp, 312]
	cmp	x4, x0
	beq	.L101
	mov	w1, 0
	stp	x0, x4, [sp, 136]
	bl	memset
	ldp	x3, x4, [sp, 136]
.L101:
	str	x4, [sp, 304]
	cmp	w19, 0
	ble	.L102
	ldr	x2, [sp, 272]
	mov	x4, 0
	.p2align 3,,7
.L105:
	cmp	w20, 0
	ble	.L106
	ldr	w6, [x27, 4]
	add	w1, w22, w4
	ldr	x5, [x28]
	mov	x0, 0
	ldr	d0, [x3, x4, lsl 3]
	mul	w1, w1, w6
	add	x1, x22, x1, sxtw
	add	x1, x1, 1
	add	x1, x5, x1, lsl 3
	.p2align 3,,7
.L107:
	ldr	d2, [x1, x0, lsl 3]
	ldr	d1, [x2, x0, lsl 3]
	add	x0, x0, 1
	fmadd	d0, d2, d1, d0
	str	d0, [x3, x4, lsl 3]
	cmp	w20, w0
	bgt	.L107
.L106:
	add	x4, x4, 1
	cmp	w19, w4
	bgt	.L105
	mov	x4, 0
	.p2align 3,,7
.L104:
	cmp	w20, 0
	ble	.L109
	ldr	w6, [x27, 4]
	add	w1, w22, w4
	ldr	x5, [x28]
	mov	x0, 0
	mul	w1, w1, w6
	add	x1, x22, x1, sxtw
	add	x1, x1, 1
	add	x1, x5, x1, lsl 3
	.p2align 3,,7
.L110:
	ldr	d1, [x3, x4, lsl 3]
	ldr	d2, [x2, x0, lsl 3]
	ldr	d0, [x1, x0, lsl 3]
	fmul	d1, d8, d1
	fmsub	d0, d1, d2, d0
	str	d0, [x1, x0, lsl 3]
	add	x0, x0, 1
	cmp	w20, w0
	bgt	.L110
.L109:
	add	x4, x4, 1
	cmp	w19, w4
	bgt	.L104
.L102:
	ldr	x0, [sp, 216]
.LEHB5:
	bl	_Znwm
.LEHE5:
	ldr	x2, [sp, 216]
	mov	w1, 0
	add	x4, x0, x2
	stp	x4, x0, [sp, 136]
	bl	memset
	ldp	x4, x3, [sp, 136]
	mov	x5, 0
	ldr	x2, [sp, 272]
	.p2align 3,,7
.L115:
	cmp	w20, 0
	ble	.L116
	ldr	x0, [sp, 152]
	ldr	x6, [sp, 168]
	ldr	w1, [x0, 4]
	mov	x0, 0
	ldr	d0, [x3, x5, lsl 3]
	ldr	x6, [x6]
	mul	w1, w1, w5
	add	x1, x22, x1, sxtw
	add	x1, x1, 1
	add	x1, x6, x1, lsl 3
	.p2align 3,,7
.L117:
	ldr	d2, [x1, x0, lsl 3]
	ldr	d1, [x2, x0, lsl 3]
	add	x0, x0, 1
	fmadd	d0, d2, d1, d0
	str	d0, [x3, x5, lsl 3]
	cmp	w20, w0
	bgt	.L117
.L116:
	ldr	w0, [sp, 132]
	add	x5, x5, 1
	cmp	w0, w5
	bgt	.L115
	mov	x5, 0
	.p2align 3,,7
.L114:
	cmp	w20, 0
	ble	.L120
	ldr	x0, [sp, 152]
	ldr	x6, [sp, 168]
	ldr	w1, [x0, 4]
	mov	x0, 0
	ldr	x6, [x6]
	mul	w1, w1, w5
	add	x1, x22, x1, sxtw
	add	x1, x1, 1
	add	x1, x6, x1, lsl 3
	.p2align 3,,7
.L121:
	ldr	d1, [x3, x5, lsl 3]
	ldr	d2, [x2, x0, lsl 3]
	ldr	d0, [x1, x0, lsl 3]
	fmul	d1, d8, d1
	fmsub	d0, d1, d2, d0
	str	d0, [x1, x0, lsl 3]
	add	x0, x0, 1
	cmp	w20, w0
	bgt	.L121
.L120:
	ldr	w0, [sp, 132]
	add	x5, x5, 1
	cmp	w0, w5
	bgt	.L114
	mov	x0, x3
	sub	x1, x4, x3
	bl	_ZdlPvm
	ldr	x0, [sp, 296]
	cbz	x0, .L122
	ldr	x1, [sp, 312]
	sub	x1, x1, x0
	bl	_ZdlPvm
.L122:
	ldr	x3, [sp, 272]
	cbz	x3, .L90
	ldr	x0, [sp, 288]
	sub	x0, x0, x3
	str	x0, [sp, 200]
	b	.L96
	.p2align 2,,3
.L164:
	sxtw	x0, w24
	mov	x1, 1152921504606846975
	fdiv	d8, d11, d8
	cmp	x0, x1
	bhi	.L209
	stp	xzr, xzr, [sp, 296]
	lsl	x23, x0, 3
	str	xzr, [sp, 312]
	cbz	x0, .L44
	mov	x0, x23
.LEHB6:
	bl	_Znwm
.LEHE6:
	add	x4, x0, x23
	str	x0, [sp, 296]
	str	x4, [sp, 312]
	mov	x3, x0
	cmp	x4, x0
	beq	.L45
	mov	x2, x23
	mov	w1, 0
	str	x4, [sp, 144]
	str	x0, [sp, 200]
	bl	memset
	ldr	x4, [sp, 144]
	ldr	x3, [sp, 200]
.L45:
	str	x4, [sp, 304]
	cmp	w24, 0
	ble	.L46
	ldr	x5, [sp, 272]
	mov	x2, 0
	.p2align 3,,7
.L48:
	cmp	w19, 0
	ble	.L52
	ldr	w4, [x27, 4]
	add	w1, w26, w2
	ldr	x7, [x28]
	mov	x0, 0
	ldr	d0, [x3, x2, lsl 3]
	mul	w6, w4, w26
	sbfiz	x4, x4, 3, 32
	sxtw	x6, w6
	add	x1, x6, x1, sxtw
	add	x1, x7, x1, lsl 3
	.p2align 3,,7
.L53:
	ldr	d2, [x5, x0, lsl 3]
	add	x0, x0, 1
	ldr	d1, [x1]
	add	x1, x1, x4
	fmadd	d0, d2, d1, d0
	str	d0, [x3, x2, lsl 3]
	cmp	w19, w0
	bgt	.L53
.L52:
	add	x2, x2, 1
	cmp	w24, w2
	bgt	.L48
.L46:
	cmp	w19, 0
	ble	.L55
	ldr	x4, [sp, 272]
	mov	x2, 0
	.p2align 3,,7
.L56:
	cmp	w24, 0
	ble	.L57
	ldr	w6, [x27, 4]
	add	w1, w26, w2
	ldr	x5, [x28]
	mov	x0, 0
	mul	w1, w1, w6
	add	x1, x22, x1, sxtw
	add	x1, x5, x1, lsl 3
	.p2align 3,,7
.L58:
	ldr	d1, [x4, x2, lsl 3]
	ldr	d2, [x3, x0, lsl 3]
	ldr	d0, [x1, x0, lsl 3]
	fmul	d1, d8, d1
	fmsub	d0, d1, d2, d0
	str	d0, [x1, x0, lsl 3]
	add	x0, x0, 1
	cmp	w24, w0
	bgt	.L58
.L57:
	add	x2, x2, 1
	cmp	w19, w2
	bgt	.L56
.L55:
	ldr	x0, [sp, 192]
	cbz	x0, .L51
	ldr	x0, [sp, 208]
.LEHB7:
	bl	_Znwm
.LEHE7:
	ldr	x1, [sp, 208]
	mov	x23, x0
	add	x1, x0, x1
	cmp	x0, x1
	beq	.L62
	ldr	x2, [sp, 208]
	mov	w1, 0
	bl	memset
.L62:
	cmp	w21, 0
	ble	.L60
	ldr	x2, [sp, 272]
	mov	x3, 0
	.p2align 3,,7
.L65:
	cmp	w19, 0
	ble	.L66
	ldr	x0, [sp, 160]
	ldr	x4, [sp, 176]
	ldr	w1, [x0, 4]
	mov	x0, 0
	ldr	d0, [x23, x3, lsl 3]
	ldr	x4, [x4]
	mul	w1, w1, w3
	add	x1, x22, x1, sxtw
	add	x1, x4, x1, lsl 3
	.p2align 3,,7
.L67:
	ldr	d2, [x1, x0, lsl 3]
	ldr	d1, [x2, x0, lsl 3]
	add	x0, x0, 1
	fmadd	d0, d2, d1, d0
	str	d0, [x23, x3, lsl 3]
	cmp	w19, w0
	bgt	.L67
.L66:
	add	x3, x3, 1
	cmp	w21, w3
	bgt	.L65
	mov	x3, 0
	.p2align 3,,7
.L64:
	cmp	w19, 0
	ble	.L69
	ldr	x0, [sp, 160]
	ldr	x4, [sp, 176]
	ldr	w1, [x0, 4]
	mov	x0, 0
	ldr	x4, [x4]
	mul	w1, w1, w3
	add	x1, x22, x1, sxtw
	add	x1, x4, x1, lsl 3
	.p2align 3,,7
.L70:
	ldr	d1, [x23, x3, lsl 3]
	ldr	d2, [x2, x0, lsl 3]
	ldr	d0, [x1, x0, lsl 3]
	fmul	d1, d8, d1
	fmsub	d0, d1, d2, d0
	str	d0, [x1, x0, lsl 3]
	add	x0, x0, 1
	cmp	w19, w0
	bgt	.L70
.L69:
	add	x3, x3, 1
	cmp	w21, w3
	bgt	.L64
.L60:
	ldr	x1, [sp, 208]
	mov	x0, x23
	bl	_ZdlPvm
.L51:
	ldr	x0, [sp, 296]
	cbz	x0, .L71
	ldr	x1, [sp, 312]
	sub	x1, x1, x0
	bl	_ZdlPvm
.L71:
	ldr	x3, [sp, 272]
	cbz	x3, .L33
	ldr	x0, [sp, 288]
	sub	x0, x0, x3
	str	x0, [sp, 144]
	b	.L39
	.p2align 2,,3
.L100:
	mov	x3, 0
	mov	x4, 0
	str	xzr, [sp, 296]
	str	xzr, [sp, 312]
	b	.L101
.L44:
	mov	x3, 0
	stp	xzr, xzr, [sp, 296]
	str	xzr, [sp, 312]
	b	.L46
.L204:
	ldr	d0, [x23]
	str	xzr, [sp, 280]
	fadd	d0, d0, d8
	str	d0, [x23]
	b	.L39
.L80:
	str	x4, [sp, 256]
	cmp	w20, 0
	bgt	.L82
.L152:
	movi	d0, #0
	b	.L83
	.p2align 2,,3
.L208:
	ldr	x0, [sp, 144]
	ldr	d0, [x0]
	str	xzr, [sp, 280]
	fadd	d0, d0, d8
	str	d0, [x0]
	b	.L96
.L202:
.LEHB8:
	bl	_ZSt17__throw_bad_allocv
.LEHE8:
.L209:
	adrp	x0, .LC1
	add	x0, x0, :lo12:.LC1
.LEHB9:
	bl	_ZSt20__throw_length_errorPKc
.LEHE9:
.L205:
	adrp	x0, .LC1
	add	x0, x0, :lo12:.LC1
.LEHB10:
	bl	_ZSt20__throw_length_errorPKc
.LEHE10:
.L200:
.LEHB11:
	bl	_ZSt17__throw_bad_allocv
.LEHE11:
	.p2align 2,,3
.L137:
	adrp	x0, .LC1
	add	x0, x0, :lo12:.LC1
.LEHB12:
	bl	_ZSt20__throw_length_errorPKc
.LEHE12:
.L206:
.LEHB13:
	bl	_ZSt17__throw_bad_allocv
.LEHE13:
.L162:
	mov	x19, x0
	add	x0, sp, 296
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L112:
	add	x0, sp, 272
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L135:
	add	x0, sp, 248
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L134:
	add	x0, sp, 224
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L136:
	mov	x0, x28
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
	mov	x0, x19
.LEHB14:
	bl	_Unwind_Resume
.LEHE14:
.L161:
	mov	x19, x0
	b	.L112
.L158:
	mov	x19, x0
	add	x0, sp, 296
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L133:
	add	x0, sp, 272
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
	b	.L134
.L157:
	mov	x19, x0
	b	.L133
.L156:
	mov	x19, x0
	b	.L136
.L160:
	mov	x19, x0
	b	.L135
.L159:
	mov	x19, x0
	b	.L134
.L199:
	.cfi_restore 27
	.cfi_restore 28
	mov	x0, 16
	bl	__cxa_allocate_exception
	adrp	x1, .LC0
	mov	x19, x0
	add	x1, x1, :lo12:.LC0
.LEHB15:
	bl	_ZNSt16invalid_argumentC1EPKc
.LEHE15:
	adrp	x2, _ZNSt16invalid_argumentD1Ev
	adrp	x1, _ZTISt16invalid_argument
	mov	x0, x19
	add	x2, x2, :lo12:_ZNSt16invalid_argumentD1Ev
	add	x1, x1, :lo12:_ZTISt16invalid_argument
	stp	x27, x28, [sp, 80]
	.cfi_remember_state
	.cfi_offset 28, -232
	.cfi_offset 27, -240
.LEHB16:
	bl	__cxa_throw
.L155:
	.cfi_restore_state
	mov	x1, x0
	mov	x0, x19
	mov	x19, x1
	stp	x27, x28, [sp, 80]
	.cfi_offset 28, -232
	.cfi_offset 27, -240
	bl	__cxa_free_exception
	mov	x0, x19
	bl	_Unwind_Resume
.LEHE16:
	.cfi_endproc
.LFE3680:
	.global	__gxx_personality_v0
	.section	.gcc_except_table,"a",@progbits
.LLSDA3680:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE3680-.LLSDACSB3680
.LLSDACSB3680:
	.uleb128 .LEHB0-.LFB3680
	.uleb128 .LEHE0-.LEHB0
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB1-.LFB3680
	.uleb128 .LEHE1-.LEHB1
	.uleb128 .L156-.LFB3680
	.uleb128 0
	.uleb128 .LEHB2-.LFB3680
	.uleb128 .LEHE2-.LEHB2
	.uleb128 .L159-.LFB3680
	.uleb128 0
	.uleb128 .LEHB3-.LFB3680
	.uleb128 .LEHE3-.LEHB3
	.uleb128 .L160-.LFB3680
	.uleb128 0
	.uleb128 .LEHB4-.LFB3680
	.uleb128 .LEHE4-.LEHB4
	.uleb128 .L161-.LFB3680
	.uleb128 0
	.uleb128 .LEHB5-.LFB3680
	.uleb128 .LEHE5-.LEHB5
	.uleb128 .L162-.LFB3680
	.uleb128 0
	.uleb128 .LEHB6-.LFB3680
	.uleb128 .LEHE6-.LEHB6
	.uleb128 .L157-.LFB3680
	.uleb128 0
	.uleb128 .LEHB7-.LFB3680
	.uleb128 .LEHE7-.LEHB7
	.uleb128 .L158-.LFB3680
	.uleb128 0
	.uleb128 .LEHB8-.LFB3680
	.uleb128 .LEHE8-.LEHB8
	.uleb128 .L159-.LFB3680
	.uleb128 0
	.uleb128 .LEHB9-.LFB3680
	.uleb128 .LEHE9-.LEHB9
	.uleb128 .L157-.LFB3680
	.uleb128 0
	.uleb128 .LEHB10-.LFB3680
	.uleb128 .LEHE10-.LEHB10
	.uleb128 .L159-.LFB3680
	.uleb128 0
	.uleb128 .LEHB11-.LFB3680
	.uleb128 .LEHE11-.LEHB11
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB12-.LFB3680
	.uleb128 .LEHE12-.LEHB12
	.uleb128 .L156-.LFB3680
	.uleb128 0
	.uleb128 .LEHB13-.LFB3680
	.uleb128 .LEHE13-.LEHB13
	.uleb128 .L160-.LFB3680
	.uleb128 0
	.uleb128 .LEHB14-.LFB3680
	.uleb128 .LEHE14-.LEHB14
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB15-.LFB3680
	.uleb128 .LEHE15-.LEHB15
	.uleb128 .L155-.LFB3680
	.uleb128 0
	.uleb128 .LEHB16-.LFB3680
	.uleb128 .LEHE16-.LEHB16
	.uleb128 0
	.uleb128 0
.LLSDACSE3680:
	.text
	.size	_Z13to_bidiagonalRK6MatrixRS_S2_, .-_Z13to_bidiagonalRK6MatrixRS_S2_
	.section	.text.startup,"ax",@progbits
	.align	2
	.p2align 4,,11
	.type	_GLOBAL__sub_I__Z13to_bidiagonalRK6MatrixRS_S2_, %function
_GLOBAL__sub_I__Z13to_bidiagonalRK6MatrixRS_S2_:
.LFB4403:
	.cfi_startproc
	stp	x29, x30, [sp, -32]!
	.cfi_def_cfa_offset 32
	.cfi_offset 29, -32
	.cfi_offset 30, -24
	mov	x29, sp
	str	x19, [sp, 16]
	.cfi_offset 19, -16
	adrp	x19, .LANCHOR0
	add	x19, x19, :lo12:.LANCHOR0
	mov	x0, x19
	bl	_ZNSt8ios_base4InitC1Ev
	mov	x1, x19
	adrp	x2, __dso_handle
	ldr	x19, [sp, 16]
	add	x2, x2, :lo12:__dso_handle
	ldp	x29, x30, [sp], 32
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 19
	.cfi_def_cfa_offset 0
	adrp	x0, _ZNSt8ios_base4InitD1Ev
	add	x0, x0, :lo12:_ZNSt8ios_base4InitD1Ev
	b	__cxa_atexit
	.cfi_endproc
.LFE4403:
	.size	_GLOBAL__sub_I__Z13to_bidiagonalRK6MatrixRS_S2_, .-_GLOBAL__sub_I__Z13to_bidiagonalRK6MatrixRS_S2_
	.section	.init_array,"aw"
	.align	3
	.xword	_GLOBAL__sub_I__Z13to_bidiagonalRK6MatrixRS_S2_
	.section	.rodata.cst8,"aM",@progbits,8
	.align	3
.LC2:
	.word	-2036257893
	.word	1023837339
	.align	3
.LC3:
	.word	-1102028775
	.word	975155446
	.bss
	.align	3
	.set	.LANCHOR0,. + 0
	.type	_ZStL8__ioinit, %object
	.size	_ZStL8__ioinit, 1
_ZStL8__ioinit:
	.zero	1
	.hidden	DW.ref.__gxx_personality_v0
	.weak	DW.ref.__gxx_personality_v0
	.section	.data.DW.ref.__gxx_personality_v0,"awG",@progbits,DW.ref.__gxx_personality_v0,comdat
	.align	3
	.type	DW.ref.__gxx_personality_v0, %object
	.size	DW.ref.__gxx_personality_v0, 8
DW.ref.__gxx_personality_v0:
	.xword	__gxx_personality_v0
	.hidden	__dso_handle
	.ident	"GCC: (GNU) 10.3.1"
	.section	.note.GNU-stack,"",@progbits
