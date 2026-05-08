	.arch armv8.2-a+crypto+crc+dotprod+fp16fml
	.file	"bidiagonalization.cpp"
	.text
	.align	2
	.p2align 4,,11
	.type	_ZL22dot_product_contiguousPKdS0_i, %function
_ZL22dot_product_contiguousPKdS0_i:
.LFB7945:
	.cfi_startproc
	sub	sp, sp, #16
	.cfi_def_cfa_offset 16
	cmp	w2, 1
	ble	.L6
	sub	w3, w2, #2
	add	x6, x0, 16
	movi	v0.2d, 0
	mov	x4, x0
	lsr	w3, w3, 1
	mov	x5, x1
	add	x6, x6, x3, uxtw 4
	.p2align 3,,7
.L3:
	ldr	q1, [x4], 16
	ldr	q2, [x5], 16
	fmla	v0.2d, v2.2d, v1.2d
	cmp	x4, x6
	bne	.L3
	add	w3, w3, 1
	lsl	w3, w3, 1
.L2:
	str	q0, [sp]
	ldp	d0, d1, [sp]
	fadd	d0, d0, d1
	cmp	w2, w3
	ble	.L1
	sxtw	x3, w3
	.p2align 3,,7
.L5:
	ldr	d2, [x0, x3, lsl 3]
	ldr	d1, [x1, x3, lsl 3]
	add	x3, x3, 1
	fmadd	d0, d2, d1, d0
	cmp	w2, w3
	bgt	.L5
.L1:
	add	sp, sp, 16
	.cfi_remember_state
	.cfi_def_cfa_offset 0
	ret
	.p2align 2,,3
.L6:
	.cfi_restore_state
	movi	v0.2d, 0
	mov	w3, 0
	b	.L2
	.cfi_endproc
.LFE7945:
	.size	_ZL22dot_product_contiguousPKdS0_i, .-_ZL22dot_product_contiguousPKdS0_i
	.align	2
	.p2align 4,,11
	.type	_ZL21add_scaled_contiguousPdPKddi, %function
_ZL21add_scaled_contiguousPdPKddi:
.LFB7946:
	.cfi_startproc
	sub	sp, sp, #16
	.cfi_def_cfa_offset 16
	uxtw	x6, w2
	str	w2, [sp, 12]
	cmp	w6, 1
	ble	.L18
	sub	w5, w6, #2
	add	x4, x0, 16
	dup	v3.2d, v0.d[0]
	mov	x2, x0
	lsr	w5, w5, 1
	mov	x3, x1
	add	x4, x4, x5, uxtw 4
	.p2align 3,,7
.L14:
	ldr	q2, [x3], 16
	ldr	q1, [x2]
	fmla	v1.2d, v3.2d, v2.2d
	str	q1, [x2], 16
	cmp	x2, x4
	bne	.L14
	add	w5, w5, 1
	lsl	w5, w5, 1
.L15:
	cmp	w5, w6
	bge	.L11
	sxtw	x5, w5
	ldr	d2, [x1, x5, lsl 3]
	ldr	d1, [x0, x5, lsl 3]
	fmadd	d0, d0, d2, d1
	str	d0, [x0, x5, lsl 3]
.L11:
	add	sp, sp, 16
	.cfi_remember_state
	.cfi_def_cfa_offset 0
	ret
	.p2align 2,,3
.L18:
	.cfi_restore_state
	mov	w5, 0
	b	.L15
	.cfi_endproc
.LFE7946:
	.size	_ZL21add_scaled_contiguousPdPKddi, .-_ZL21add_scaled_contiguousPdPKddi
	.section	.text._ZNSt12_Vector_baseIdSaIdEED2Ev,"axG",@progbits,_ZNSt12_Vector_baseIdSaIdEED5Ev,comdat
	.align	2
	.p2align 4,,11
	.weak	_ZNSt12_Vector_baseIdSaIdEED2Ev
	.type	_ZNSt12_Vector_baseIdSaIdEED2Ev, %function
_ZNSt12_Vector_baseIdSaIdEED2Ev:
.LFB8236:
	.cfi_startproc
	mov	x2, x0
	ldr	x0, [x0]
	cbz	x0, .L19
	ldr	x1, [x2, 16]
	sub	x1, x1, x0
	b	_ZdlPvm
	.p2align 2,,3
.L19:
	ret
	.cfi_endproc
.LFE8236:
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
.LFB7948:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA7948
	stp	x29, x30, [sp, -320]!
	.cfi_def_cfa_offset 320
	.cfi_offset 29, -320
	.cfi_offset 30, -312
	mov	x29, sp
	stp	x19, x20, [sp, 16]
	stp	x27, x28, [sp, 80]
	.cfi_offset 19, -304
	.cfi_offset 20, -296
	.cfi_offset 27, -240
	.cfi_offset 28, -232
	ldp	w19, w27, [x0]
	stp	d8, d9, [sp, 96]
	stp	d10, d11, [sp, 112]
	stp	x1, x2, [sp, 136]
	cmp	w27, w19
	.cfi_offset 72, -224
	.cfi_offset 73, -216
	.cfi_offset 74, -208
	.cfi_offset 75, -200
	bgt	.L181
	mov	x20, x0
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -280
	.cfi_offset 21, -288
	ldp	x0, x21, [x0, 8]
	stp	x25, x26, [sp, 64]
	.cfi_offset 26, -248
	.cfi_offset 25, -256
	add	x25, x8, 8
	stp	x23, x24, [sp, 48]
	.cfi_offset 24, -264
	.cfi_offset 23, -272
	mov	x23, x8
	stp	w19, w27, [x8]
	str	xzr, [x8, 8]
	subs	x21, x21, x0
	stp	xzr, xzr, [x25, 8]
	beq	.L126
	mov	x0, 9223372036854775800
	cmp	x21, x0
	bhi	.L182
	mov	x0, x21
.LEHB0:
	bl	_Znwm
.LEHE0:
	mov	x3, x0
.L23:
	str	x3, [x23, 8]
	add	x21, x3, x21
	stp	x3, x21, [x25, 8]
	ldp	x1, x0, [x20, 8]
	sub	x20, x0, x1
	cmp	x1, x0
	beq	.L26
	mov	x0, x3
	mov	x2, x20
	bl	memmove
	mov	x3, x0
.L26:
	mul	w0, w19, w19
	add	x3, x3, x20
	str	x3, [x25, 8]
	cbz	w0, .L127
	sbfiz	x20, x0, 3, 32
	mov	x0, x20
.LEHB1:
	bl	_Znwm
	mov	x2, x20
	mov	x21, x0
	add	x20, x0, x20
	mov	w1, 0
	bl	memset
.L27:
	ldr	x2, [sp, 136]
	add	x1, x2, 8
	mov	x3, x1
	str	x3, [sp, 152]
	ldr	x0, [x2, 8]
	ldr	x1, [x1, 16]
	stp	w19, w19, [x2]
	str	x21, [x2, 8]
	stp	x20, x20, [x3, 8]
	cbz	x0, .L28
	sub	x1, x1, x0
	bl	_ZdlPvm
.L28:
	cmp	w19, 0
	ble	.L32
	ldr	x0, [sp, 136]
	mov	w1, 0
	fmov	d0, 1.0e+0
	ldrsw	x2, [x0, 4]
	ldr	x0, [x0, 8]
	add	x2, x2, 1
	lsl	x2, x2, 3
	.p2align 3,,7
.L33:
	add	w1, w1, 1
	str	d0, [x0]
	add	x0, x0, x2
	cmp	w1, w19
	bne	.L33
.L32:
	mul	w0, w27, w27
	mov	x21, 0
	mov	x20, 0
	cbz	w0, .L31
	sbfiz	x20, x0, 3, 32
	mov	x0, x20
	bl	_Znwm
	mov	x2, x20
	mov	x21, x0
	add	x20, x0, x20
	mov	w1, 0
	bl	memset
.L31:
	ldr	x2, [sp, 144]
	add	x1, x2, 8
	mov	x3, x1
	str	x3, [sp, 160]
	ldr	x0, [x2, 8]
	ldr	x1, [x1, 16]
	stp	w27, w27, [x2]
	str	x21, [x2, 8]
	stp	x20, x20, [x3, 8]
	cbz	x0, .L34
	sub	x1, x1, x0
	bl	_ZdlPvm
.L34:
	cmp	w27, 0
	ble	.L21
	ldr	x0, [sp, 144]
	mov	w1, 0
	fmov	d0, 1.0e+0
	ldrsw	x2, [x0, 4]
	ldr	x0, [x0, 8]
	add	x2, x2, 1
	lsl	x2, x2, 3
	.p2align 3,,7
.L37:
	add	w1, w1, 1
	str	d0, [x0]
	add	x0, x0, x2
	cmp	w1, w27
	bne	.L37
	sxtw	x0, w19
	mov	x1, x0
	str	x1, [sp, 192]
	mov	x0, 1152921504606846975
	cmp	x1, x0
	bhi	.L123
	ldr	x26, [sp, 192]
	mov	w20, w19
	mov	x24, 0
	mov	w22, 0
	fmov	d11, 2.0e+0
	lsl	x0, x26, 3
	str	x0, [sp, 200]
	sbfiz	x0, x27, 3, 32
	str	x0, [sp, 208]
	adrp	x0, .LC2
	ldr	d9, [x0, #:lo12:.LC2]
	sub	w0, w19, #1
	str	w0, [sp, 180]
	adrp	x0, .LC3
	ldr	d10, [x0, #:lo12:.LC3]
	sub	w0, w27, #2
	str	w0, [sp, 176]
	.p2align 3,,7
.L38:
	lsl	x28, x26, 3
	str	x28, [sp, 168]
	stp	xzr, xzr, [sp, 224]
	str	xzr, [sp, 240]
	cbz	x26, .L39
	mov	x0, x28
	bl	_Znwm
.LEHE1:
	mov	x2, x28
	add	x28, x0, x28
	str	x0, [sp, 224]
	mov	x21, x0
	str	x28, [sp, 240]
	cmp	x28, x0
	beq	.L40
	mov	w1, 0
	bl	memset
	str	x28, [sp, 232]
	cmp	w20, 0
	ble	.L41
.L42:
	ldr	w1, [x23, 4]
	mov	x0, 0
	ldr	x3, [x25]
	sbfiz	x2, x1, 3, 32
	mul	w1, w1, w22
	add	x1, x24, x1, sxtw
	add	x1, x3, x1, lsl 3
	.p2align 3,,7
.L45:
	ldr	d0, [x1]
	add	x1, x1, x2
	str	d0, [x21, x0, lsl 3]
	add	x0, x0, 1
	cmp	w20, w0
	bgt	.L45
	cmp	x21, x28
	beq	.L133
.L41:
	movi	d8, #0
	mov	x0, x21
	.p2align 3,,7
.L46:
	ldr	d1, [x0], 8
	fmadd	d8, d1, d1, d8
	cmp	x28, x0
	bne	.L46
	fcmp	d8, #0.0
	bpl	.L43
	fmov	d0, d8
	bl	sqrt
	fmov	d8, d0
	b	.L49
	.p2align 2,,3
.L39:
	mov	x21, 0
	mov	x28, 0
	str	xzr, [sp, 224]
	str	xzr, [sp, 240]
.L40:
	str	x28, [sp, 232]
	cmp	w20, 0
	bgt	.L42
.L133:
	movi	d8, #0
	.p2align 3,,7
.L43:
	fsqrt	d8, d8
.L49:
	fcmpe	d8, d9
	bgt	.L142
.L50:
	add	w21, w22, 1
	cmp	w21, w19
	bge	.L77
	ldr	w0, [x23, 4]
	mov	w1, w21
	ldr	x3, [x25]
	sbfiz	x2, x0, 3, 32
	mul	w0, w21, w0
	add	x0, x24, x0, sxtw
	add	x0, x3, x0, lsl 3
	.p2align 3,,7
.L78:
	add	w1, w1, 1
	str	xzr, [x0]
	add	x0, x0, x2
	cmp	w1, w19
	bne	.L78
.L77:
	ldr	w0, [sp, 176]
	cmp	w0, w24
	bgt	.L183
.L76:
	ldr	x0, [sp, 224]
	cbz	x0, .L114
	ldr	x1, [sp, 240]
	sub	x1, x1, x0
	bl	_ZdlPvm
.L114:
	cmp	w21, w27
	beq	.L21
	sub	x26, x26, #1
	add	x24, x24, 1
	sub	w20, w20, #1
	mov	x0, 1152921504606846975
	cmp	x26, x0
	bhi	.L123
	mov	w22, w21
	b	.L38
	.p2align 2,,3
.L142:
	ldr	w0, [sp, 180]
	cmp	w0, w22
	ble	.L50
	ldp	x1, x0, [sp, 224]
	fneg	d0, d8
	ldr	d1, [x1]
	sub	x28, x0, x1
	stp	xzr, xzr, [sp, 272]
	mov	x21, x28
	fcmpe	d1, #0.0
	str	xzr, [sp, 288]
	fcsel	d8, d8, d0, ge
	cbz	x28, .L130
	mov	x0, 9223372036854775800
	cmp	x28, x0
	bhi	.L184
	mov	x0, x28
.LEHB2:
	bl	_Znwm
	mov	x3, x0
	ldp	x1, x0, [sp, 224]
	sub	x28, x0, x1
	mov	x2, x28
.L53:
	add	x21, x3, x21
	stp	x3, x3, [sp, 272]
	str	x21, [sp, 288]
	cmp	x0, x1
	beq	.L55
	mov	x0, x3
	str	x2, [sp, 184]
	bl	memmove
	mov	x3, x0
	ldr	x2, [sp, 184]
.L55:
	add	x4, x3, x2
	ldr	d0, [x3]
	ubfx	x2, x28, 3, 32
	mov	x1, x3
	mov	x0, x3
	str	x4, [sp, 280]
	fadd	d0, d0, d8
	str	d0, [x3]
	bl	_ZL22dot_product_contiguousPKdS0_i
	fcmpe	d0, d10
	bgt	.L143
.L56:
	ldr	x0, [sp, 272]
	cbz	x0, .L50
	ldr	x1, [sp, 288]
	sub	x1, x1, x0
	bl	_ZdlPvm
	b	.L50
	.p2align 2,,3
.L183:
	sub	w28, w27, w21
	mov	x1, 1152921504606846975
	sxtw	x0, w28
	cmp	x0, x1
	bhi	.L185
	stp	xzr, xzr, [sp, 248]
	lsl	x2, x0, 3
	str	xzr, [sp, 264]
	cbz	x0, .L80
	mov	x0, x2
	str	x2, [sp, 184]
	bl	_Znwm
.LEHE2:
	ldr	x2, [sp, 184]
	str	x0, [sp, 248]
	mov	x3, x0
	add	x4, x0, x2
	str	x4, [sp, 264]
	cmp	x4, x0
	beq	.L81
	mov	w1, 0
	str	x4, [sp, 184]
	str	x0, [sp, 216]
	bl	memset
	ldr	x4, [sp, 184]
	str	x4, [sp, 256]
	cmp	w28, 0
	ldr	x3, [sp, 216]
	ble	.L82
.L83:
	ldr	w0, [x23, 4]
	mov	x1, 0
	ldr	x2, [x25]
	mul	w0, w22, w0
	add	x0, x24, x0, sxtw
	add	x0, x0, 1
	add	x0, x2, x0, lsl 3
	.p2align 3,,7
.L86:
	ldr	d0, [x0, x1, lsl 3]
	str	d0, [x3, x1, lsl 3]
	add	x1, x1, 1
	cmp	w28, w1
	bgt	.L86
	cmp	x4, x3
	beq	.L132
.L82:
	movi	d0, #0
	mov	x0, x3
	.p2align 3,,7
.L87:
	ldr	d1, [x0], 8
	fmadd	d0, d1, d1, d0
	cmp	x0, x4
	bne	.L87
	fcmp	d0, #0.0
	bpl	.L84
	bl	sqrt
	fmov	d8, d0
	b	.L90
	.p2align 2,,3
.L80:
	movi	d0, #0
	stp	xzr, xzr, [sp, 248]
	str	xzr, [sp, 264]
.L84:
	fsqrt	d8, d0
.L90:
	fcmpe	d8, d9
	bgt	.L144
	b	.L91
	.p2align 2,,3
.L144:
	ldp	x1, x5, [sp, 248]
	fneg	d0, d8
	ldr	d1, [x1]
	sub	x4, x5, x1
	str	x4, [sp, 184]
	stp	xzr, xzr, [sp, 272]
	fcmpe	d1, #0.0
	str	xzr, [sp, 288]
	fcsel	d8, d8, d0, ge
	cbz	x4, .L131
	mov	x0, 9223372036854775800
	cmp	x4, x0
	bhi	.L186
	ldr	x0, [sp, 184]
.LEHB3:
	bl	_Znwm
.LEHE3:
	ldp	x1, x5, [sp, 248]
	mov	x3, x0
	sub	x4, x5, x1
	mov	x2, x4
.L94:
	ldr	x0, [sp, 184]
	stp	x3, x3, [sp, 272]
	add	x0, x3, x0
	str	x0, [sp, 288]
	cmp	x1, x5
	beq	.L96
	mov	x0, x3
	str	x2, [sp, 184]
	str	x4, [sp, 216]
	bl	memmove
	ldr	x2, [sp, 184]
	mov	x3, x0
	ldr	x4, [sp, 216]
.L96:
	add	x0, x3, x2
	ldr	d0, [x3]
	ubfx	x2, x4, 3, 32
	mov	x1, x3
	str	x0, [sp, 280]
	mov	x0, x3
	fadd	d0, d0, d8
	str	d0, [x3]
	bl	_ZL22dot_product_contiguousPKdS0_i
	fcmpe	d0, d10
	bgt	.L145
.L97:
	ldr	x0, [sp, 272]
	cbz	x0, .L91
	ldr	x1, [sp, 288]
	sub	x1, x1, x0
	bl	_ZdlPvm
.L91:
	add	w0, w22, 2
	cmp	w27, w0
	ble	.L113
	ldr	w3, [x23, 4]
	sxtw	x0, w0
	ldr	w1, [sp, 176]
	ldr	x4, [x25]
	sub	w2, w1, w21
	mul	w3, w22, w3
	add	x2, x2, 1
	mov	w1, 0
	lsl	x2, x2, 3
	add	x0, x0, x3, sxtw
	add	x0, x4, x0, lsl 3
	bl	memset
.L113:
	ldr	x0, [sp, 248]
	cbz	x0, .L76
	ldr	x1, [sp, 264]
	sub	x1, x1, x0
	bl	_ZdlPvm
	b	.L76
	.p2align 2,,3
.L21:
	mov	x0, x23
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	.cfi_remember_state
	.cfi_restore 22
	.cfi_restore 21
	ldp	x23, x24, [sp, 48]
	.cfi_restore 24
	.cfi_restore 23
	ldp	x25, x26, [sp, 64]
	.cfi_restore 26
	.cfi_restore 25
	ldp	x27, x28, [sp, 80]
	ldp	d8, d9, [sp, 96]
	ldp	d10, d11, [sp, 112]
	ldp	x29, x30, [sp], 320
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 27
	.cfi_restore 28
	.cfi_restore 19
	.cfi_restore 20
	.cfi_restore 74
	.cfi_restore 75
	.cfi_restore 72
	.cfi_restore 73
	.cfi_def_cfa_offset 0
	ret
	.p2align 2,,3
.L130:
	.cfi_restore_state
	mov	x2, 0
	mov	x3, 0
	b	.L53
.L143:
	sub	w28, w27, w22
	mov	w21, w22
	fdiv	d8, d11, d0
	mov	x1, 1152921504606846975
	sxtw	x0, w28
	cmp	x0, x1
	bhi	.L187
	stp	xzr, xzr, [sp, 296]
	lsl	x2, x0, 3
	str	xzr, [sp, 312]
	cbz	x0, .L59
	mov	x0, x2
	str	x2, [sp, 184]
.LEHB4:
	bl	_Znwm
.LEHE4:
	ldr	x2, [sp, 184]
	str	x0, [sp, 296]
	add	x3, x0, x2
	str	x3, [sp, 312]
	cmp	x3, x0
	beq	.L60
	mov	w1, 0
	str	x3, [sp, 184]
	bl	memset
	ldr	x3, [sp, 184]
.L60:
	str	x3, [sp, 304]
	add	w9, w22, w20
	mov	w7, w22
	mov	x8, 0
	cmp	w20, 0
	ble	.L65
	.p2align 3,,7
.L64:
	ldr	w1, [x23, 4]
	mov	w2, w28
	ldr	x4, [sp, 272]
	ldr	x3, [x25]
	madd	w1, w7, w1, w22
	ldr	x0, [sp, 296]
	add	w7, w7, 1
	ldr	d0, [x4, x8]
	add	x1, x3, x1, sxtw 3
	add	x8, x8, 8
	bl	_ZL21add_scaled_contiguousPdPKddi
	cmp	w9, w7
	bne	.L64
	fneg	d4, d8
	mov	x7, 0
	.p2align 3,,7
.L66:
	ldr	x3, [sp, 272]
	mov	w2, w28
	ldr	w0, [x23, 4]
	ldr	x1, [sp, 296]
	ldr	d0, [x3, x7]
	add	x7, x7, 8
	ldr	x3, [x25]
	madd	w0, w21, w0, w22
	fmul	d0, d4, d0
	add	w21, w21, 1
	add	x0, x3, x0, sxtw 3
	bl	_ZL21add_scaled_contiguousPdPKddi
	cmp	w9, w21
	bne	.L66
.L65:
	ldr	x0, [sp, 192]
	cbz	x0, .L63
	ldr	x28, [sp, 200]
	mov	x0, x28
.LEHB5:
	bl	_Znwm
.LEHE5:
	add	x1, x0, x28
	mov	x21, x0
	cmp	x0, x1
	beq	.L70
	ldr	x2, [sp, 200]
	mov	w1, 0
	bl	memset
.L70:
	cmp	w19, 0
	ble	.L68
	mov	x7, 0
	.p2align 3,,7
.L69:
	ldr	x0, [sp, 136]
	mov	w2, w20
	ldr	x3, [sp, 152]
	ldr	w0, [x0, 4]
	ldr	x1, [sp, 272]
	ldr	x3, [x3]
	madd	w0, w0, w7, w22
	add	x0, x3, x0, sxtw 3
	bl	_ZL22dot_product_contiguousPKdS0_i
	str	d0, [x21, x7, lsl 3]
	add	x7, x7, 1
	cmp	w19, w7
	bgt	.L69
	fneg	d8, d8
	mov	x7, 0
	.p2align 3,,7
.L71:
	ldr	x0, [sp, 136]
	mov	w2, w20
	ldr	x3, [sp, 152]
	ldr	w0, [x0, 4]
	ldr	d0, [x21, x7, lsl 3]
	ldr	x3, [x3]
	fmul	d0, d8, d0
	madd	w0, w0, w7, w22
	ldr	x1, [sp, 272]
	add	x7, x7, 1
	add	x0, x3, x0, sxtw 3
	bl	_ZL21add_scaled_contiguousPdPKddi
	cmp	w19, w7
	bgt	.L71
.L68:
	ldr	x1, [sp, 200]
	mov	x0, x21
	bl	_ZdlPvm
.L63:
	ldr	x0, [sp, 296]
	cbz	x0, .L56
	ldr	x1, [sp, 312]
	sub	x1, x1, x0
	bl	_ZdlPvm
	b	.L56
.L145:
	stp	xzr, xzr, [sp, 296]
	fdiv	d8, d11, d0
	str	xzr, [sp, 312]
	cbz	x26, .L99
	ldr	x0, [sp, 168]
.LEHB6:
	bl	_Znwm
.LEHE6:
	ldr	x2, [sp, 168]
	str	x0, [sp, 296]
	add	x3, x0, x2
	str	x3, [sp, 312]
	cmp	x3, x0
	beq	.L100
	mov	w1, 0
	str	x3, [sp, 168]
	bl	memset
	ldr	x3, [sp, 168]
.L100:
	str	x3, [sp, 304]
	cmp	w20, 0
	ble	.L101
	mov	w7, w24
	add	w10, w20, w24
	mov	w8, w24
	mov	x9, 0
	.p2align 3,,7
.L102:
	ldr	w0, [x23, 4]
	mov	w2, w28
	ldr	x3, [x25]
	ldr	x1, [sp, 272]
	madd	w0, w8, w0, w21
	ldr	x11, [sp, 296]
	add	w8, w8, 1
	add	x0, x3, x0, sxtw 3
	bl	_ZL22dot_product_contiguousPKdS0_i
	str	d0, [x11, x9]
	add	x9, x9, 8
	cmp	w8, w10
	bne	.L102
	fneg	d4, d8
	mov	x8, 0
	.p2align 3,,7
.L103:
	ldr	x3, [sp, 296]
	mov	w2, w28
	ldr	w0, [x23, 4]
	ldr	x1, [sp, 272]
	ldr	d0, [x3, x8]
	add	x8, x8, 8
	ldr	x3, [x25]
	madd	w0, w7, w0, w21
	fmul	d0, d4, d0
	add	w7, w7, 1
	add	x0, x3, x0, sxtw 3
	bl	_ZL21add_scaled_contiguousPdPKddi
	cmp	w10, w7
	bne	.L103
.L101:
	ldr	x0, [sp, 208]
.LEHB7:
	bl	_Znwm
.LEHE7:
	ldr	x2, [sp, 208]
	mov	w1, 0
	str	x0, [sp, 168]
	add	x3, x0, x2
	str	x3, [sp, 184]
	bl	memset
	mov	x7, 0
	.p2align 3,,7
.L106:
	ldr	x0, [sp, 144]
	mov	w2, w28
	ldr	x3, [sp, 160]
	ldr	w0, [x0, 4]
	ldr	x1, [sp, 272]
	ldr	x3, [x3]
	madd	w0, w0, w7, w21
	add	x0, x3, x0, sxtw 3
	bl	_ZL22dot_product_contiguousPKdS0_i
	ldr	x0, [sp, 168]
	str	d0, [x0, x7, lsl 3]
	add	x7, x7, 1
	cmp	w27, w7
	bgt	.L106
	fneg	d8, d8
	mov	x7, 0
	.p2align 3,,7
.L107:
	ldp	x3, x0, [sp, 160]
	mov	w2, w28
	ldr	x1, [sp, 272]
	ldr	d0, [x0, x7, lsl 3]
	ldr	x0, [sp, 144]
	fmul	d0, d8, d0
	ldr	x3, [x3]
	ldr	w0, [x0, 4]
	madd	w0, w0, w7, w21
	add	x7, x7, 1
	add	x0, x3, x0, sxtw 3
	bl	_ZL21add_scaled_contiguousPdPKddi
	cmp	w27, w7
	bgt	.L107
	ldr	x0, [sp, 168]
	ldr	x1, [sp, 184]
	sub	x1, x1, x0
	bl	_ZdlPvm
	ldr	x0, [sp, 296]
	cbz	x0, .L97
	ldr	x1, [sp, 312]
	sub	x1, x1, x0
	bl	_ZdlPvm
	b	.L97
.L131:
	mov	x2, 0
	mov	x3, 0
	b	.L94
.L127:
	mov	x21, 0
	mov	x20, 0
	b	.L27
.L126:
	mov	x3, 0
	b	.L23
.L59:
	mov	x3, 0
	str	xzr, [sp, 296]
	str	xzr, [sp, 312]
	b	.L60
.L99:
	mov	x3, 0
	str	xzr, [sp, 296]
	str	xzr, [sp, 312]
	b	.L100
.L81:
	str	x4, [sp, 256]
	cmp	w28, 0
	bgt	.L83
.L132:
	movi	d0, #0
	b	.L84
.L184:
.LEHB8:
	bl	_ZSt17__throw_bad_allocv
.LEHE8:
.L187:
	adrp	x0, .LC1
	add	x0, x0, :lo12:.LC1
.LEHB9:
	bl	_ZSt20__throw_length_errorPKc
.LEHE9:
	.p2align 2,,3
.L123:
	adrp	x0, .LC1
	add	x0, x0, :lo12:.LC1
.LEHB10:
	bl	_ZSt20__throw_length_errorPKc
.LEHE10:
.L182:
.LEHB11:
	bl	_ZSt17__throw_bad_allocv
.LEHE11:
.L185:
	adrp	x0, .LC1
	add	x0, x0, :lo12:.LC1
.LEHB12:
	bl	_ZSt20__throw_length_errorPKc
.LEHE12:
.L186:
.LEHB13:
	bl	_ZSt17__throw_bad_allocv
.LEHE13:
.L135:
	mov	x19, x0
.L122:
	mov	x0, x25
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
	mov	x0, x19
.LEHB14:
	bl	_Unwind_Resume
.LEHE14:
.L139:
	mov	x19, x0
.L121:
	add	x0, sp, 248
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L120:
	add	x0, sp, 224
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
	b	.L122
.L181:
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 25
	.cfi_restore 26
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
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -280
	.cfi_offset 21, -288
	stp	x23, x24, [sp, 48]
	.cfi_offset 24, -264
	.cfi_offset 23, -272
	stp	x25, x26, [sp, 64]
	.cfi_offset 26, -248
	.cfi_offset 25, -256
.LEHB16:
	bl	__cxa_throw
.L136:
	mov	x19, x0
.L119:
	add	x0, sp, 272
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
	b	.L120
.L134:
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 25
	.cfi_restore 26
	mov	x1, x0
	mov	x0, x19
	mov	x19, x1
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -280
	.cfi_offset 21, -288
	stp	x23, x24, [sp, 48]
	.cfi_offset 24, -264
	.cfi_offset 23, -272
	stp	x25, x26, [sp, 64]
	.cfi_offset 26, -248
	.cfi_offset 25, -256
	bl	__cxa_free_exception
	mov	x0, x19
	bl	_Unwind_Resume
.LEHE16:
.L138:
	mov	x19, x0
	b	.L120
.L141:
	mov	x19, x0
	add	x0, sp, 296
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L105:
	add	x0, sp, 272
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
	b	.L121
.L137:
	mov	x19, x0
	add	x0, sp, 296
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
	b	.L119
.L140:
	mov	x19, x0
	b	.L105
	.cfi_endproc
.LFE7948:
	.global	__gxx_personality_v0
	.section	.gcc_except_table,"a",@progbits
.LLSDA7948:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE7948-.LLSDACSB7948
.LLSDACSB7948:
	.uleb128 .LEHB0-.LFB7948
	.uleb128 .LEHE0-.LEHB0
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB1-.LFB7948
	.uleb128 .LEHE1-.LEHB1
	.uleb128 .L135-.LFB7948
	.uleb128 0
	.uleb128 .LEHB2-.LFB7948
	.uleb128 .LEHE2-.LEHB2
	.uleb128 .L138-.LFB7948
	.uleb128 0
	.uleb128 .LEHB3-.LFB7948
	.uleb128 .LEHE3-.LEHB3
	.uleb128 .L139-.LFB7948
	.uleb128 0
	.uleb128 .LEHB4-.LFB7948
	.uleb128 .LEHE4-.LEHB4
	.uleb128 .L136-.LFB7948
	.uleb128 0
	.uleb128 .LEHB5-.LFB7948
	.uleb128 .LEHE5-.LEHB5
	.uleb128 .L137-.LFB7948
	.uleb128 0
	.uleb128 .LEHB6-.LFB7948
	.uleb128 .LEHE6-.LEHB6
	.uleb128 .L140-.LFB7948
	.uleb128 0
	.uleb128 .LEHB7-.LFB7948
	.uleb128 .LEHE7-.LEHB7
	.uleb128 .L141-.LFB7948
	.uleb128 0
	.uleb128 .LEHB8-.LFB7948
	.uleb128 .LEHE8-.LEHB8
	.uleb128 .L138-.LFB7948
	.uleb128 0
	.uleb128 .LEHB9-.LFB7948
	.uleb128 .LEHE9-.LEHB9
	.uleb128 .L136-.LFB7948
	.uleb128 0
	.uleb128 .LEHB10-.LFB7948
	.uleb128 .LEHE10-.LEHB10
	.uleb128 .L135-.LFB7948
	.uleb128 0
	.uleb128 .LEHB11-.LFB7948
	.uleb128 .LEHE11-.LEHB11
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB12-.LFB7948
	.uleb128 .LEHE12-.LEHB12
	.uleb128 .L138-.LFB7948
	.uleb128 0
	.uleb128 .LEHB13-.LFB7948
	.uleb128 .LEHE13-.LEHB13
	.uleb128 .L139-.LFB7948
	.uleb128 0
	.uleb128 .LEHB14-.LFB7948
	.uleb128 .LEHE14-.LEHB14
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB15-.LFB7948
	.uleb128 .LEHE15-.LEHB15
	.uleb128 .L134-.LFB7948
	.uleb128 0
	.uleb128 .LEHB16-.LFB7948
	.uleb128 .LEHE16-.LEHB16
	.uleb128 0
	.uleb128 0
.LLSDACSE7948:
	.text
	.size	_Z13to_bidiagonalRK6MatrixRS_S2_, .-_Z13to_bidiagonalRK6MatrixRS_S2_
	.section	.text.startup,"ax",@progbits
	.align	2
	.p2align 4,,11
	.type	_GLOBAL__sub_I__Z13to_bidiagonalRK6MatrixRS_S2_, %function
_GLOBAL__sub_I__Z13to_bidiagonalRK6MatrixRS_S2_:
.LFB8673:
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
.LFE8673:
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
