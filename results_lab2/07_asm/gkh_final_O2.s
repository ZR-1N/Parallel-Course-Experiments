	.arch armv8.2-a+crypto+crc+dotprod+fp16fml
	.file	"gkh.cpp"
	.text
	.align	2
	.p2align 4,,11
	.type	_ZN12_GLOBAL__N_1L15apply_left_rowsER6Matrixiidd, %function
_ZN12_GLOBAL__N_1L15apply_left_rowsER6Matrixiidd:
.LFB3895:
	.cfi_startproc
	ldr	w7, [x0, 4]
	ldr	x0, [x0, 8]
	mul	w1, w1, w7
	mul	w2, w2, w7
	add	x3, x0, x1, sxtw 3
	add	x4, x0, x2, sxtw 3
	cmp	w7, 3
	ble	.L11
	sub	w5, w7, #4
	mov	w6, 32
	mov	x0, x3
	mov	x1, x4
	lsr	w5, w5, 2
	umaddl	x6, w5, w6, x3
	.p2align 3,,7
.L4:
	ldp	d3, d2, [x1]
	cmp	x6, x0
	ldp	d4, d7, [x0]
	fmul	d17, d3, d1
	fmul	d5, d3, d0
	fmul	d16, d2, d1
	fmadd	d17, d4, d0, d17
	fmsub	d5, d1, d4, d5
	fmul	d4, d2, d0
	fmadd	d16, d7, d0, d16
	ldp	d3, d2, [x1, 16]
	fmsub	d4, d1, d7, d4
	ldp	d6, d18, [x0, 16]
	add	x1, x1, 32
	fmul	d7, d3, d1
	fmul	d3, d3, d0
	add	x0, x0, 32
	fmadd	d7, d6, d0, d7
	fmsub	d3, d1, d6, d3
	fmul	d6, d2, d1
	fmul	d2, d2, d0
	fmadd	d6, d18, d0, d6
	fmsub	d2, d1, d18, d2
	str	d17, [x0, -32]
	str	d5, [x1, -32]
	str	d16, [x0, -24]
	str	d4, [x1, -24]
	str	d7, [x0, -16]
	str	d3, [x1, -16]
	str	d6, [x0, -8]
	str	d2, [x1, -8]
	bne	.L4
	add	w1, w5, 1
	lsl	w1, w1, 2
.L5:
	sxtw	x0, w1
	cmp	w7, w1
	ble	.L1
.L7:
	ldr	d2, [x4, x0, lsl 3]
	ldr	d4, [x3, x0, lsl 3]
	fmul	d3, d1, d2
	fmul	d2, d0, d2
	fmadd	d3, d0, d4, d3
	fmsub	d2, d1, d4, d2
	str	d3, [x3, x0, lsl 3]
	str	d2, [x4, x0, lsl 3]
	add	x0, x0, 1
	cmp	w7, w0
	bgt	.L7
.L1:
	ret
	.p2align 2,,3
.L11:
	mov	w1, 0
	b	.L5
	.cfi_endproc
.LFE3895:
	.size	_ZN12_GLOBAL__N_1L15apply_left_rowsER6Matrixiidd, .-_ZN12_GLOBAL__N_1L15apply_left_rowsER6Matrixiidd
	.align	2
	.p2align 4,,11
	.type	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd, %function
_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd:
.LFB3896:
	.cfi_startproc
	ldr	w5, [x0]
	cmp	w5, 0
	ble	.L12
	ldr	x6, [x0, 8]
	sxtw	x2, w2
	ldrsw	x4, [x0, 4]
	sub	x3, x2, x1, sxtw
	mov	w2, 0
	add	x0, x6, x1, sxtw 3
	lsl	x1, x4, 3
	.p2align 3,,7
.L14:
	ldr	d2, [x0, x3, lsl 3]
	add	w2, w2, 1
	ldr	d4, [x0]
	fmul	d3, d2, d1
	fmul	d2, d2, d0
	fnmsub	d3, d4, d0, d3
	fmadd	d2, d4, d1, d2
	str	d3, [x0]
	str	d2, [x0, x3, lsl 3]
	add	x0, x0, x1
	cmp	w2, w5
	bne	.L14
.L12:
	ret
	.cfi_endproc
.LFE3896:
	.size	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd, .-_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	.align	2
	.p2align 4,,11
	.type	_ZN12_GLOBAL__N_1L18cleanup_bidiagonalER6Matrixd, %function
_ZN12_GLOBAL__N_1L18cleanup_bidiagonalER6Matrixd:
.LFB3899:
	.cfi_startproc
	ldr	w8, [x0]
	cmp	w8, 0
	ble	.L16
	ldr	w5, [x0, 4]
	mov	w4, 0
	mov	w3, 0
	mov	w7, 0
	.p2align 3,,7
.L19:
	add	w7, w7, 1
	mov	w1, 0
	cmp	w5, 0
	ble	.L23
	.p2align 3,,7
.L18:
	add	w2, w1, w4
	cmp	w3, w1
	beq	.L21
	sxtw	x2, w2
	cmp	w1, w7
	beq	.L21
	ldr	x6, [x0, 8]
	ldr	d1, [x6, x2, lsl 3]
	fabs	d1, d1
	fcmpe	d1, d0
	bls	.L25
.L21:
	add	w1, w1, 1
	cmp	w1, w5
	bne	.L18
.L23:
	add	w3, w3, 1
	add	w4, w4, w5
	cmp	w8, w7
	bne	.L19
.L16:
	ret
	.p2align 2,,3
.L25:
	str	xzr, [x6, x2, lsl 3]
	b	.L21
	.cfi_endproc
.LFE3899:
	.size	_ZN12_GLOBAL__N_1L18cleanup_bidiagonalER6Matrixd, .-_ZN12_GLOBAL__N_1L18cleanup_bidiagonalER6Matrixd
	.align	2
	.p2align 4,,11
	.type	_ZNSt6vectorIdSaIdEEaSERKS1_.isra.0, %function
_ZNSt6vectorIdSaIdEEaSERKS1_.isra.0:
.LFB4877:
	.cfi_startproc
	cmp	x1, x0
	beq	.L49
	stp	x29, x30, [sp, -80]!
	.cfi_def_cfa_offset 80
	.cfi_offset 29, -80
	.cfi_offset 30, -72
	mov	x29, sp
	stp	x21, x22, [sp, 32]
	stp	x23, x24, [sp, 48]
	.cfi_offset 21, -48
	.cfi_offset 22, -40
	.cfi_offset 23, -32
	.cfi_offset 24, -24
	ldr	x22, [x0]
	stp	x19, x20, [sp, 16]
	.cfi_offset 19, -64
	.cfi_offset 20, -56
	mov	x19, x0
	ldr	x23, [x1]
	mov	x20, x1
	ldr	x24, [x0, 16]
	str	x25, [sp, 64]
	.cfi_offset 25, -16
	ldr	x25, [x1, 8]
	sub	x24, x24, x22
	sub	x21, x25, x23
	cmp	x21, x24
	bhi	.L53
	ldr	x0, [x0, 8]
	sub	x2, x0, x22
	cmp	x21, x2
	bhi	.L37
	cmp	x25, x23
	beq	.L52
	mov	x0, x22
	mov	x1, x23
	mov	x2, x21
	bl	memmove
	ldr	x22, [x19]
.L52:
	add	x21, x22, x21
	ldp	x23, x24, [sp, 48]
	ldr	x25, [sp, 64]
	str	x21, [x19, 8]
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x29, x30, [sp], 80
	.cfi_remember_state
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 25
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 19
	.cfi_restore 20
	.cfi_def_cfa_offset 0
	ret
	.p2align 2,,3
.L53:
	.cfi_restore_state
	cbz	x21, .L41
	mov	x0, 9223372036854775800
	cmp	x21, x0
	bhi	.L54
	mov	x0, x21
	bl	_Znwm
	ldr	x22, [x19]
	mov	x20, x0
	ldr	x24, [x19, 16]
	sub	x24, x24, x22
.L32:
	cmp	x25, x23
	beq	.L34
	mov	x1, x23
	mov	x2, x21
	mov	x0, x20
	bl	memcpy
.L34:
	cbz	x22, .L35
	mov	x1, x24
	mov	x0, x22
	bl	_ZdlPvm
.L35:
	add	x21, x20, x21
	str	x20, [x19]
	str	x21, [x19, 16]
	ldp	x23, x24, [sp, 48]
	ldr	x25, [sp, 64]
	str	x21, [x19, 8]
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x29, x30, [sp], 80
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 25
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 19
	.cfi_restore 20
	.cfi_def_cfa_offset 0
	ret
	.p2align 2,,3
.L49:
	ret
	.p2align 2,,3
.L37:
	.cfi_def_cfa_offset 80
	.cfi_offset 19, -64
	.cfi_offset 20, -56
	.cfi_offset 21, -48
	.cfi_offset 22, -40
	.cfi_offset 23, -32
	.cfi_offset 24, -24
	.cfi_offset 25, -16
	.cfi_offset 29, -80
	.cfi_offset 30, -72
	cbz	x2, .L39
	mov	x1, x23
	mov	x0, x22
	bl	memmove
	ldp	x22, x0, [x19]
	ldp	x23, x25, [x20]
	sub	x2, x0, x22
.L39:
	add	x1, x23, x2
	cmp	x1, x25
	beq	.L52
	sub	x2, x25, x1
	bl	memmove
	ldr	x0, [x19]
	ldp	x23, x24, [sp, 48]
	add	x21, x0, x21
	ldr	x25, [sp, 64]
	str	x21, [x19, 8]
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x29, x30, [sp], 80
	.cfi_remember_state
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 25
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 19
	.cfi_restore 20
	.cfi_def_cfa_offset 0
	ret
	.p2align 2,,3
.L41:
	.cfi_restore_state
	mov	x20, 0
	b	.L32
.L54:
	bl	_ZSt17__throw_bad_allocv
	.cfi_endproc
.LFE4877:
	.size	_ZNSt6vectorIdSaIdEEaSERKS1_.isra.0, .-_ZNSt6vectorIdSaIdEEaSERKS1_.isra.0
	.align	2
	.p2align 4,,11
	.type	_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_, %function
_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_:
.LFB4693:
	.cfi_startproc
	cmp	x0, x1
	beq	.L72
	stp	x29, x30, [sp, -80]!
	.cfi_def_cfa_offset 80
	.cfi_offset 29, -80
	.cfi_offset 30, -72
	mov	x29, sp
	stp	x19, x20, [sp, 16]
	.cfi_offset 19, -64
	.cfi_offset 20, -56
	add	x20, x0, 4
	stp	x23, x24, [sp, 48]
	.cfi_offset 23, -32
	.cfi_offset 24, -24
	mov	x23, x0
	mov	x24, x1
	cmp	x20, x1
	beq	.L55
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -40
	.cfi_offset 21, -48
	mov	x21, x2
	mov	x22, 4
	str	x25, [sp, 64]
	.cfi_offset 25, -16
	add	x25, x2, 8
	.p2align 3,,7
.L65:
	ldr	w7, [x21, 4]
	mov	x2, x20
	ldr	w19, [x20]
	ldr	w3, [x23]
	ldr	x6, [x25]
	madd	w0, w19, w7, w19
	madd	w3, w3, w7, w3
	ldr	d0, [x6, w0, sxtw 3]
	ldr	d1, [x6, w3, sxtw 3]
	fcmpe	d0, d1
	bgt	.L66
	ldr	w4, [x20, -4]
	sub	x5, x20, #4
	madd	w7, w7, w4, w4
	ldr	d1, [x6, w7, sxtw 3]
	fcmpe	d0, d1
	bgt	.L64
	.p2align 3,,7
.L62:
	str	w19, [x2]
.L61:
	add	x20, x20, 4
	cmp	x20, x24
	bne	.L65
	ldp	x21, x22, [sp, 32]
	.cfi_restore 22
	.cfi_restore 21
	ldr	x25, [sp, 64]
	.cfi_restore 25
.L55:
	ldp	x19, x20, [sp, 16]
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 80
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 19
	.cfi_restore 20
	.cfi_def_cfa_offset 0
	ret
	.p2align 2,,3
.L64:
	.cfi_def_cfa_offset 80
	.cfi_offset 19, -64
	.cfi_offset 20, -56
	.cfi_offset 21, -48
	.cfi_offset 22, -40
	.cfi_offset 23, -32
	.cfi_offset 24, -24
	.cfi_offset 25, -16
	.cfi_offset 29, -80
	.cfi_offset 30, -72
	str	w4, [x5, 4]
	mov	x2, x5
	ldr	w4, [x5, -4]!
	ldr	w3, [x21, 4]
	madd	w7, w19, w3, w19
	madd	w3, w4, w3, w4
	ldr	d1, [x6, w7, sxtw 3]
	ldr	d0, [x6, w3, sxtw 3]
	fcmpe	d1, d0
	bgt	.L64
	b	.L62
	.p2align 2,,3
.L66:
	cmp	x23, x20
	beq	.L60
	sub	x2, x20, x23
	mov	x1, x23
	add	x0, x23, x22
	bl	memmove
.L60:
	str	w19, [x23]
	b	.L61
.L72:
	.cfi_def_cfa_offset 0
	.cfi_restore 19
	.cfi_restore 20
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 25
	.cfi_restore 29
	.cfi_restore 30
	ret
	.cfi_endproc
.LFE4693:
	.size	_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_, .-_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_
	.align	2
	.p2align 4,,11
	.type	_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_T0_SF_T1_T2_, %function
_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_T0_SF_T1_T2_:
.LFB4843:
	.cfi_startproc
	sub	x14, x2, #1
	and	x16, x2, 1
	add	x14, x14, x14, lsr 63
	asr	x14, x14, 1
	cmp	x1, x14
	bge	.L76
	ldr	x12, [x4, 8]
	mov	x10, x1
	.p2align 3,,7
.L79:
	add	x6, x10, 1
	ldr	w7, [x4, 4]
	lsl	x5, x6, 1
	lsl	x6, x6, 3
	sub	x8, x5, #1
	add	x11, x0, x6
	ldr	w6, [x0, x6]
	add	x15, x0, x8, lsl 2
	ldr	w9, [x0, x8, lsl 2]
	madd	w13, w6, w7, w6
	madd	w7, w9, w7, w9
	ldr	d1, [x12, w13, sxtw 3]
	ldr	d0, [x12, w7, sxtw 3]
	fcmpe	d1, d0
	bgt	.L87
.L77:
	str	w6, [x0, x10, lsl 2]
	mov	x10, x5
	cmp	x5, x14
	blt	.L79
	cbz	x16, .L84
.L80:
	sub	x6, x5, #1
	add	x6, x6, x6, lsr 63
	asr	x6, x6, 1
	cmp	x5, x1
	ble	.L81
	ldr	x9, [x4, 8]
	.p2align 3,,7
.L83:
	sub	x2, x6, #1
	ldr	w7, [x4, 4]
	add	x12, x0, x6, lsl 2
	ldr	w8, [x0, x6, lsl 2]
	add	x2, x2, x2, lsr 63
	add	x11, x0, x5, lsl 2
	asr	x2, x2, 1
	madd	w10, w8, w7, w8
	madd	w7, w3, w7, w3
	ldr	d1, [x9, w10, sxtw 3]
	ldr	d0, [x9, w7, sxtw 3]
	fcmpe	d1, d0
	bgt	.L88
.L81:
	str	w3, [x11]
	ret
	.p2align 2,,3
.L88:
	str	w8, [x0, x5, lsl 2]
	mov	x5, x6
	cmp	x1, x6
	bge	.L90
	mov	x6, x2
	b	.L83
	.p2align 2,,3
.L76:
	add	x11, x0, x1, lsl 2
	mov	x5, x1
	cbnz	x16, .L81
	.p2align 3,,7
.L84:
	sub	x2, x2, #2
	add	x2, x2, x2, lsr 63
	cmp	x5, x2, asr 1
	bne	.L80
	lsl	x5, x5, 1
	add	x5, x5, 1
	ldr	w2, [x0, x5, lsl 2]
	str	w2, [x11]
	add	x11, x0, x5, lsl 2
	b	.L80
	.p2align 2,,3
.L87:
	mov	x11, x15
	mov	w6, w9
	mov	x5, x8
	b	.L77
	.p2align 2,,3
.L90:
	mov	x11, x12
	str	w3, [x11]
	ret
	.cfi_endproc
.LFE4843:
	.size	_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_T0_SF_T1_T2_, .-_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_T0_SF_T1_T2_
	.align	2
	.p2align 4,,11
	.type	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_T1_, %function
_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_T1_:
.LFB4602:
	.cfi_startproc
	stp	x29, x30, [sp, -80]!
	.cfi_def_cfa_offset 80
	.cfi_offset 29, -80
	.cfi_offset 30, -72
	mov	x29, sp
	stp	x23, x24, [sp, 48]
	.cfi_offset 23, -32
	.cfi_offset 24, -24
	mov	x24, x0
	sub	x0, x1, x0
	cmp	x0, 64
	ble	.L91
	stp	x25, x26, [sp, 64]
	.cfi_offset 26, -8
	.cfi_offset 25, -16
	mov	x23, x1
	mov	x26, x2
	mov	x25, x3
	cbz	x2, .L93
	stp	x19, x20, [sp, 16]
	.cfi_offset 20, -56
	.cfi_offset 19, -64
	add	x20, x24, 8
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -40
	.cfi_offset 21, -48
	add	x22, x24, 4
	add	x21, x3, 8
.L95:
	sub	x0, x1, x24
	ldr	w3, [x25, 4]
	ldr	w5, [x1, -4]
	sub	x26, x26, #1
	lsr	x4, x0, 63
	add	x0, x4, x0, asr 2
	ldp	w10, w2, [x24]
	asr	x0, x0, 1
	madd	w6, w3, w5, w5
	ldr	x9, [x21]
	madd	w7, w2, w3, w2
	ldr	w4, [x24, x0, lsl 2]
	ldr	d2, [x9, w6, sxtw 3]
	ldr	d1, [x9, w7, sxtw 3]
	madd	w3, w4, w3, w4
	ldr	d0, [x9, w3, sxtw 3]
	fcmpe	d1, d0
	bgt	.L122
	fcmpe	d1, d2
	bgt	.L125
	fcmpe	d0, d2
	bgt	.L126
.L140:
	str	w4, [x24]
	str	w10, [x24, x0, lsl 2]
	ldr	w3, [x1, -4]
	ldp	w2, w10, [x24]
.L104:
	mov	x11, x20
	ldr	w7, [x25, 4]
	mov	x19, x22
	mov	x8, x1
	madd	w2, w2, w7, w2
	ldr	d1, [x9, w2, sxtw 3]
	.p2align 3,,7
.L111:
	madd	w0, w10, w7, w10
	mov	x23, x19
	ldr	d0, [x9, w0, sxtw 3]
	fcmpe	d0, d1
	bgt	.L114
	madd	w0, w3, w7, w3
	sub	x4, x8, #4
	sub	x5, x8, #8
	ldr	d0, [x9, w0, sxtw 3]
	fcmpe	d1, d0
	bgt	.L117
	mov	x8, x4
	cmp	x8, x19
	bls	.L145
	.p2align 3,,7
.L118:
	str	w3, [x19]
	str	w10, [x8]
	ldr	w3, [x8, -4]
	ldr	w0, [x24]
	ldr	w7, [x25, 4]
	madd	w0, w0, w7, w0
	ldr	d1, [x9, w0, sxtw 3]
.L114:
	ldr	w10, [x11], 4
	add	x19, x19, 4
	b	.L111
	.p2align 2,,3
.L117:
	mov	x8, x5
	ldr	w3, [x5], -4
	madd	w6, w3, w7, w3
	ldr	d0, [x9, w6, sxtw 3]
	fcmpe	d0, d1
	bmi	.L117
	cmp	x8, x19
	bhi	.L118
.L145:
	mov	x0, x19
	mov	x3, x25
	mov	x2, x26
	bl	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_T1_
	sub	x0, x19, x24
	cmp	x0, 64
	ble	.L146
	cbz	x26, .L143
	mov	x1, x19
	b	.L95
.L126:
	str	w5, [x24]
	mov	w3, w10
	str	w10, [x1, -4]
	ldp	w2, w10, [x24]
	b	.L104
.L122:
	fcmpe	d0, d2
	bgt	.L140
	fcmpe	d1, d2
	bgt	.L126
.L125:
	stp	w2, w10, [x24]
	ldr	w3, [x1, -4]
	b	.L104
.L146:
	ldp	x19, x20, [sp, 16]
	.cfi_restore 20
	.cfi_restore 19
	ldp	x21, x22, [sp, 32]
	.cfi_restore 22
	.cfi_restore 21
	ldp	x25, x26, [sp, 64]
	.cfi_restore 26
	.cfi_restore 25
.L91:
	ldp	x23, x24, [sp, 48]
	ldp	x29, x30, [sp], 80
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 23
	.cfi_restore 24
	.cfi_def_cfa_offset 0
	ret
.L143:
	.cfi_def_cfa_offset 80
	.cfi_offset 19, -64
	.cfi_offset 20, -56
	.cfi_offset 21, -48
	.cfi_offset 22, -40
	.cfi_offset 23, -32
	.cfi_offset 24, -24
	.cfi_offset 25, -16
	.cfi_offset 26, -8
	.cfi_offset 29, -80
	.cfi_offset 30, -72
	ldp	x19, x20, [sp, 16]
	.cfi_restore 20
	.cfi_restore 19
	ldp	x21, x22, [sp, 32]
	.cfi_restore 22
	.cfi_restore 21
.L93:
	asr	x18, x0, 2
	sub	x1, x18, #2
	asr	x1, x1, 1
	b	.L97
.L147:
	sub	x1, x1, #1
.L97:
	ldr	w3, [x24, x1, lsl 2]
	mov	x4, x25
	mov	x2, x18
	mov	x0, x24
	bl	_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_T0_SF_T1_T2_
	cbnz	x1, .L147
	sub	x23, x23, #4
	.p2align 3,,7
.L98:
	ldr	w3, [x23]
	sub	x18, x23, x24
	ldr	w0, [x24]
	mov	x4, x25
	str	w0, [x23]
	asr	x2, x18, 2
	mov	x0, x24
	mov	x1, 0
	bl	_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_T0_SF_T1_T2_
	sub	x23, x23, #4
	cmp	x18, 4
	bgt	.L98
	ldp	x25, x26, [sp, 64]
	.cfi_restore 26
	.cfi_restore 25
	b	.L91
	.cfi_endproc
.LFE4602:
	.size	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_T1_, .-_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_T1_
	.section	.text._ZNSt12_Vector_baseIdSaIdEED2Ev,"axG",@progbits,_ZNSt12_Vector_baseIdSaIdEED5Ev,comdat
	.align	2
	.p2align 4,,11
	.weak	_ZNSt12_Vector_baseIdSaIdEED2Ev
	.type	_ZNSt12_Vector_baseIdSaIdEED2Ev, %function
_ZNSt12_Vector_baseIdSaIdEED2Ev:
.LFB4207:
	.cfi_startproc
	mov	x2, x0
	ldr	x0, [x0]
	cbz	x0, .L148
	ldr	x1, [x2, 16]
	sub	x1, x1, x0
	b	_ZdlPvm
	.p2align 2,,3
.L148:
	ret
	.cfi_endproc
.LFE4207:
	.size	_ZNSt12_Vector_baseIdSaIdEED2Ev, .-_ZNSt12_Vector_baseIdSaIdEED2Ev
	.weak	_ZNSt12_Vector_baseIdSaIdEED1Ev
	.set	_ZNSt12_Vector_baseIdSaIdEED1Ev,_ZNSt12_Vector_baseIdSaIdEED2Ev
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align	3
.LC0:
	.string	"gkh_svd_from_bidiagonal_v2: requires m >= n"
	.align	3
.LC1:
	.string	"gkh_svd_from_bidiagonal_v2: U must be m x m"
	.align	3
.LC2:
	.string	"gkh_svd_from_bidiagonal_v2: V must be n x n"
	.align	3
.LC3:
	.string	"vector::_M_realloc_insert"
	.align	3
.LC4:
	.string	"cannot create std::vector larger than max_size()"
	.text
	.align	2
	.p2align 4,,11
	.global	_Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id
	.type	_Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id, %function
_Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id:
.LFB3926:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA3926
	stp	x29, x30, [sp, -288]!
	.cfi_def_cfa_offset 288
	.cfi_offset 29, -288
	.cfi_offset 30, -280
	mov	x29, sp
	stp	x19, x20, [sp, 16]
	.cfi_offset 19, -272
	.cfi_offset 20, -264
	mov	x19, x1
	ldr	w1, [x1]
	stp	x27, x28, [sp, 80]
	.cfi_offset 27, -208
	.cfi_offset 28, -200
	mov	x27, x0
	ldr	w0, [x19, 4]
	str	w0, [sp, 160]
	str	w3, [sp, 188]
	cmp	w1, w0
	blt	.L342
	ldr	w0, [x27]
	cmp	w0, w1
	bne	.L152
	ldr	w1, [x27, 4]
	cmp	w1, w0
	bne	.L152
	ldr	w0, [x2]
	ldr	w1, [sp, 160]
	stp	x25, x26, [sp, 64]
	.cfi_offset 26, -216
	.cfi_offset 25, -224
	mov	x26, x2
	cmp	w0, w1
	bne	.L155
	ldr	w0, [x2, 4]
	ldr	w1, [sp, 160]
	cmp	w0, w1
	bne	.L155
	ldr	w0, [sp, 160]
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -248
	.cfi_offset 21, -256
	sub	w20, w0, #1
	ldr	w0, [sp, 188]
	stp	x23, x24, [sp, 48]
	.cfi_offset 24, -232
	.cfi_offset 23, -240
	stp	d8, d9, [sp, 96]
	.cfi_offset 73, -184
	.cfi_offset 72, -192
	fmov	d8, d0
	str	wzr, [sp, 184]
	cmp	w0, 0
	ble	.L210
	mov	x1, 10
	mov	x0, -9223372036854775808
	movk	x1, 0x3ff0, lsl 48
	fmov	d9, x0
	stp	d10, d11, [sp, 112]
	.cfi_offset 75, -168
	.cfi_offset 74, -176
	fmov	d10, x1
	stp	d12, d13, [sp, 128]
	.cfi_offset 77, -152
	.cfi_offset 76, -160
	.p2align 3,,7
.L158:
	fmov	d0, d8
	mov	x0, x19
	add	x22, x19, 8
	mov	w25, 0
	bl	_ZN12_GLOBAL__N_1L18cleanup_bidiagonalER6Matrixd
	ldr	w21, [x19, 4]
	fmul	d13, d8, d10
	sub	w23, w21, #1
	cmp	w23, 0
	bgt	.L160
	b	.L171
	.p2align 2,,3
.L343:
	ldr	w21, [x19, 4]
	mov	w25, w28
.L160:
	mul	w0, w21, w25
	add	w24, w25, 1
	ldr	x1, [x22]
	add	w4, w0, w25
	mov	w28, w24
	ldr	d11, [x1, w4, sxtw 3]
	fabs	d0, d11
	fcmpe	d8, d0
	bge	.L292
.L163:
	cmp	w23, w28
	bne	.L343
.L171:
	cmp	w20, 0
	ble	.L161
	ldr	w3, [x19, 4]
	mov	w2, 0
	ldr	x1, [x19, 8]
	add	w3, w3, 1
	fmov	d3, 1.0e+0
	sbfiz	x3, x3, 3, 32
	add	x0, x1, 8
	add	x1, x1, x3
	.p2align 3,,7
.L162:
	ldp	d0, d1, [x0, -8]
	add	w2, w2, 1
	ldr	d2, [x1]
	fabs	d0, d0
	fabs	d1, d1
	fabs	d2, d2
	fadd	d0, d0, d2
	fadd	d0, d0, d3
	fmul	d0, d0, d8
	fcmpe	d0, d1
	bge	.L294
.L172:
	add	x1, x1, x3
	add	x0, x0, x3
	cmp	w2, w20
	bne	.L162
.L161:
	ldr	w0, [sp, 160]
	cmp	w0, 0
	ble	.L174
	mov	x3, 0
	mov	x22, 0
	mov	x24, 0
	mov	w23, 0
	.p2align 3,,7
.L188:
	mov	w21, w23
	.p2align 3,,7
.L176:
	cmp	w21, w20
	bge	.L175
	ldr	w0, [x19, 4]
	add	w1, w21, 1
	ldr	x2, [x19, 8]
	madd	w0, w21, w0, w1
	ldr	d0, [x2, w0, sxtw 3]
	fabs	d0, d0
	fcmpe	d0, #0.0
	bgt	.L270
.L175:
	sub	x0, x3, x24
	str	x0, [sp, 152]
	cmp	x3, x22
	beq	.L177
	stp	w23, w21, [x22]
	add	x22, x22, 8
.L178:
	ldr	w0, [sp, 160]
	add	w23, w21, 1
	cmp	w0, w23
	bgt	.L188
	cmp	x22, x24
	beq	.L191
	mov	x0, x24
	b	.L193
	.p2align 2,,3
.L344:
	add	x0, x0, 8
	cmp	x22, x0
	beq	.L191
.L193:
	ldp	w1, w2, [x0]
	cmp	w2, w1
	ble	.L344
	sub	x0, x22, x24
	asr	x0, x0, 3
	cmp	w0, 0
	ble	.L195
	sub	w2, w0, #1
	sbfiz	x0, x0, 3, 32
	sub	x21, x0, #8
	sub	x1, x24, #16
	sub	x0, x0, x2, uxtw 3
	add	x21, x24, x21
	add	x0, x0, x1
	fmov	d12, 2.5e-1
	str	x0, [sp, 168]
	b	.L196
	.p2align 2,,3
.L205:
	ldr	x0, [sp, 168]
	sub	x21, x21, #8
	cmp	x0, x21
	beq	.L195
.L196:
	ldp	w1, w23, [x21]
	cmp	w23, w1
	ble	.L205
	ldr	w0, [x19, 4]
	sub	w5, w23, #1
	ldr	x3, [x19, 8]
	movi	d1, #0
	add	x22, x19, 8
	mul	w2, w5, w0
	add	w4, w0, w2
	add	w7, w5, w2
	add	w6, w23, w4
	add	w2, w23, w2
	ldr	d0, [x3, w7, sxtw 3]
	ldr	d11, [x3, w6, sxtw 3]
	ldr	d2, [x3, w2, sxtw 3]
	cmp	w1, w5
	bge	.L197
	sub	w2, w4, w0, lsl 1
	add	w2, w2, w5
	ldr	d1, [x3, w2, sxtw 3]
	fmul	d1, d1, d1
.L197:
	fmul	d3, d2, d2
	fmadd	d1, d0, d0, d1
	fmadd	d11, d11, d11, d3
	fmul	d0, d0, d2
	fmul	d0, d0, d0
	fadd	d13, d1, d11
	fnmsub	d0, d1, d11, d0
	fmul	d1, d13, d12
	fnmsub	d0, d13, d1, d0
	fcmpe	d0, #0.0
	bmi	.L274
	fcmp	d0, #0.0
	bpl	.L198
	str	w1, [sp, 176]
	bl	sqrt
	ldr	w0, [x19, 4]
	ldr	w1, [sp, 176]
	ldr	x3, [x19, 8]
	b	.L201
	.p2align 2,,3
.L270:
	mov	w21, w1
	b	.L176
.L274:
	movi	d0, #0
.L198:
	fsqrt	d0, d0
.L201:
	fmov	d1, 5.0e-1
	mul	w0, w1, w0
	add	w28, w1, 1
	str	w1, [sp, 176]
	fmadd	d3, d13, d1, d0
	fnmsub	d0, d13, d1, d0
	add	w4, w1, w0
	add	w0, w0, w28
	ldr	d2, [x3, w4, sxtw 3]
	ldr	d13, [x3, w0, sxtw 3]
	fabd	d1, d3, d11
	fabd	d11, d0, d11
	fmul	d13, d2, d13
	fcmpe	d1, d11
	fmov	d1, d13
	fcsel	d3, d3, d0, ls
	fnmsub	d11, d2, d2, d3
	fmov	d0, d11
	bl	hypot
	fcmp	d0, #0.0
	fmov	d2, d0
	ldr	w1, [sp, 176]
	beq	.L275
	fdiv	d0, d11, d0
	fneg	d1, d13
	fdiv	d1, d1, d2
.L203:
	mov	w2, w28
	mov	x0, x19
	str	w1, [sp, 176]
	bl	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	ldr	w1, [sp, 176]
	mov	w2, w28
	mov	x0, x26
	str	w1, [sp, 176]
	bl	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	ldr	w1, [sp, 176]
	ldr	w0, [x19, 4]
	ldr	x4, [x19, 8]
	str	w1, [sp, 176]
	mul	w3, w1, w0
	add	w0, w0, w3
	add	w3, w1, w3
	add	w0, w0, w1
	ldr	d13, [x4, w3, sxtw 3]
	ldr	d11, [x4, w0, sxtw 3]
	fmov	d0, d13
	fmov	d1, d11
	bl	hypot
	fcmp	d0, #0.0
	ldr	w1, [sp, 176]
	beq	.L276
	fdiv	d1, d11, d0
	fdiv	d0, d13, d0
	fneg	d11, d1
.L204:
	mov	w2, w28
	mov	x0, x19
	str	w1, [sp, 176]
	bl	_ZN12_GLOBAL__N_1L15apply_left_rowsER6Matrixiidd
	ldr	w1, [sp, 176]
	fmov	d1, d11
	mov	w2, w28
	mov	x0, x27
	bl	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	cmp	w23, w28
	bgt	.L208
	b	.L205
	.p2align 2,,3
.L345:
	fdiv	d0, d13, d0
	fneg	d1, d11
	fdiv	d1, d1, d2
.L206:
	mov	w2, w28
	mov	w1, w25
	mov	x0, x19
	bl	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	mov	w2, w28
	mov	w1, w25
	mov	x0, x26
	bl	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	ldr	w0, [x19, 4]
	ldr	x4, [x22]
	mul	w3, w0, w25
	add	w0, w0, w3
	add	w3, w3, w25
	add	w0, w0, w25
	ldr	d13, [x4, w3, sxtw 3]
	ldr	d11, [x4, w0, sxtw 3]
	fmov	d0, d13
	fmov	d1, d11
	bl	hypot
	fcmp	d0, #0.0
	beq	.L278
	fdiv	d1, d11, d0
	fdiv	d0, d13, d0
	fneg	d11, d1
.L207:
	mov	w2, w28
	mov	w1, w25
	mov	x0, x19
	bl	_ZN12_GLOBAL__N_1L15apply_left_rowsER6Matrixiidd
	fmov	d1, d11
	mov	w2, w28
	mov	w1, w25
	mov	x0, x27
	bl	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	cmp	w23, w28
	beq	.L205
.L208:
	ldr	w4, [x19, 4]
	sub	w0, w28, #1
	mov	w25, w28
	ldr	x3, [x22]
	mul	w0, w0, w4
	add	w4, w0, w28
	add	w28, w28, 1
	add	w0, w0, w28
	ldr	d13, [x3, w4, sxtw 3]
	ldr	d11, [x3, w0, sxtw 3]
	fmov	d0, d13
	fmov	d1, d11
	bl	hypot
	fcmp	d0, #0.0
	fmov	d2, d0
	bne	.L345
	movi	d1, #0
	fmov	d0, 1.0e+0
	b	.L206
	.p2align 2,,3
.L294:
	str	xzr, [x0]
	b	.L172
	.p2align 2,,3
.L292:
	add	w0, w0, w24
	ldr	d12, [x1, w0, sxtw 3]
	fabs	d0, d12
	fcmpe	d13, d0
	bmi	.L293
	b	.L163
	.p2align 2,,3
.L293:
	sub	w21, w21, #1
	cmp	w21, w25
	ble	.L163
	fcmpe	d8, d0
	bge	.L163
	ldr	w0, [x19]
	str	w0, [sp, 152]
	b	.L166
	.p2align 2,,3
.L347:
	fdiv	d0, d11, d0
	fneg	d1, d12
	fdiv	d1, d1, d2
.L168:
	mov	w2, w24
	mov	w1, w25
	mov	x0, x19
	bl	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	mov	x0, x26
	mov	w2, w24
	mov	w1, w25
	bl	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	ldr	w0, [sp, 152]
	cmp	w0, w24
	bgt	.L346
	cmp	w21, w24
	beq	.L167
.L351:
	ldr	w0, [x19, 4]
	add	w1, w25, 2
	ldr	x4, [x22]
	mov	w25, w24
	mul	w0, w24, w0
	add	w1, w1, w0
	add	w0, w24, w0
	add	w24, w24, 1
	ldr	d11, [x4, w0, sxtw 3]
	ldr	d12, [x4, w1, sxtw 3]
.L166:
	fmov	d1, d12
	fmov	d0, d11
	bl	hypot
	fcmp	d0, #0.0
	fmov	d2, d0
	bne	.L347
	movi	d1, #0
	fmov	d0, 1.0e+0
	b	.L168
	.p2align 2,,3
.L278:
	movi	d1, #0
	fmov	d11, d9
	fmov	d0, 1.0e+0
	b	.L207
	.p2align 2,,3
.L177:
	ldr	x0, [sp, 152]
	mov	x1, 1152921504606846975
	asr	x0, x0, 3
	cmp	x0, x1
	beq	.L348
	cmp	x0, 0
	csinc	x1, x0, xzr, ne
	adds	x0, x0, x1
	bcs	.L181
	cbz	x0, .L349
	mov	x1, 1152921504606846975
	cmp	x0, x1
	csel	x0, x0, x1, ls
	lsl	x22, x0, 3
.L182:
	mov	x0, x22
.LEHB0:
	bl	_Znwm
.LEHE0:
	mov	x25, x22
	mov	x4, x0
	add	x3, x0, x22
.L183:
	ldr	x1, [sp, 152]
	add	x0, x4, x1
	add	x22, x1, 8
	str	w23, [x4, x1]
	add	x22, x4, x22
	str	w21, [x0, 4]
	cmp	x1, 0
	bgt	.L350
	cbnz	x24, .L185
.L186:
	mov	x24, x4
	str	x25, [sp, 152]
	b	.L178
	.p2align 2,,3
.L346:
	ldr	w0, [x19, 4]
	ldr	x4, [x22]
	mul	w1, w0, w25
	add	w0, w0, w1
	add	w1, w1, w25
	add	w0, w0, w25
	ldr	d12, [x4, w1, sxtw 3]
	ldr	d11, [x4, w0, sxtw 3]
	fmov	d0, d12
	fmov	d1, d11
	bl	hypot
	fcmp	d0, #0.0
	beq	.L269
	fdiv	d1, d11, d0
	fdiv	d0, d12, d0
	fneg	d11, d1
.L170:
	mov	w2, w24
	mov	w1, w25
	mov	x0, x19
	bl	_ZN12_GLOBAL__N_1L15apply_left_rowsER6Matrixiidd
	fmov	d1, d11
	mov	w2, w24
	mov	w1, w25
	mov	x0, x27
	bl	_ZN12_GLOBAL__N_1L16apply_right_colsER6Matrixiidd
	cmp	w21, w24
	bne	.L351
.L167:
	fmov	d0, d8
	mov	x0, x19
	bl	_ZN12_GLOBAL__N_1L18cleanup_bidiagonalER6Matrixd
	b	.L163
	.p2align 2,,3
.L195:
	cbz	x24, .L209
	ldr	x1, [sp, 152]
	mov	x0, x24
	bl	_ZdlPvm
.L209:
	ldp	w0, w1, [sp, 184]
	add	w0, w0, 1
	str	w0, [sp, 184]
	cmp	w1, w0
	bne	.L158
	ldp	d10, d11, [sp, 112]
	.cfi_restore 75
	.cfi_restore 74
	ldp	d12, d13, [sp, 128]
	.cfi_restore 77
	.cfi_restore 76
.L210:
	fmov	d0, d8
	mov	x0, x19
	mov	w24, 0
	bl	_ZN12_GLOBAL__N_1L18cleanup_bidiagonalER6Matrixd
	ldr	w21, [x19, 4]
	cmp	w20, 0
	ble	.L211
.L356:
	sxtw	x7, w21
	mov	w1, 0
	ldr	x0, [x19, 8]
	add	x2, x7, 1
	add	x0, x0, 8
	lsl	x2, x2, 3
	.p2align 3,,7
.L213:
	add	w1, w1, 1
	str	xzr, [x0]
	add	x0, x0, x2
	cmp	w1, w20
	bne	.L213
	ldr	w5, [x19]
	cmp	w21, 0
	ble	.L214
.L357:
	add	x6, x7, 1
	add	x22, x27, 8
	ldr	x3, [x19, 8]
	lsl	x6, x6, 3
	mov	x2, 0
	.p2align 3,,7
.L217:
	ldr	d0, [x3]
	fcmpe	d0, #0.0
	bmi	.L215
.L218:
	add	x2, x2, 1
	add	x3, x3, x6
	cmp	w21, w2
	bgt	.L217
.L216:
	lsl	x23, x7, 2
	cbz	x7, .L279
	mov	x0, x23
.LEHB1:
	bl	_Znwm
.LEHE1:
	add	x25, x0, x23
	mov	x20, x0
	cmp	x25, x0
	beq	.L221
	mov	x2, x23
	mov	w1, 0
	bl	memset
	cmp	w21, 0
	ble	.L222
.L265:
	mov	x0, 0
	.p2align 3,,7
.L223:
	str	w0, [x20, x0, lsl 2]
	add	x0, x0, 1
	cmp	w21, w0
	bgt	.L223
	cmp	x25, x20
	beq	.L220
.L222:
	asr	x0, x23, 2
	mov	w2, 63
	clz	x0, x0
	mov	x3, x19
	sub	w2, w2, w0
	mov	x1, x25
	mov	x0, x20
	sbfiz	x2, x2, 1, 32
	bl	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_T1_
	cmp	x23, 64
	ble	.L224
	add	x23, x20, 64
	mov	x2, x19
	mov	x1, x23
	mov	x0, x20
	bl	_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_
	cmp	x25, x23
	beq	.L220
	ldr	w4, [x19, 4]
	mov	x6, x23
	ldr	x3, [x19, 8]
.L230:
	mov	x1, x6
	ldr	w0, [x6, -4]
	mov	x5, x6
	ldr	w7, [x1], -4
	madd	w8, w0, w4, w0
	madd	w2, w7, w4, w7
	ldr	d0, [x3, w8, sxtw 3]
	ldr	d1, [x3, w2, sxtw 3]
	fcmpe	d1, d0
	bgt	.L229
	add	x6, x6, 4
	str	w7, [x5]
	cmp	x25, x6
	bne	.L230
.L220:
	ldp	x0, x1, [x27]
	stp	x0, xzr, [sp, 192]
	ldr	x0, [x22, 8]
	stp	xzr, xzr, [sp, 208]
	subs	x23, x0, x1
	beq	.L281
.L355:
	mov	x0, 9223372036854775800
	cmp	x23, x0
	bhi	.L352
	mov	x0, x23
.LEHB2:
	bl	_Znwm
.LEHE2:
	mov	x3, x0
	ldp	x1, x0, [x27, 8]
	sub	x28, x0, x1
.L232:
	add	x23, x3, x23
	stp	x3, x3, [sp, 200]
	str	x23, [sp, 216]
	cmp	x1, x0
	beq	.L234
	mov	x0, x3
	mov	x2, x28
	bl	memmove
	mov	x3, x0
.L234:
	mov	x23, x26
	add	x3, x3, x28
	ldr	x1, [x26, 8]
	str	x3, [sp, 208]
	ldr	x0, [x23], 8
	stp	x0, xzr, [sp, 224]
	stp	xzr, xzr, [sp, 240]
	ldr	x0, [x23, 8]
	subs	x28, x0, x1
	beq	.L282
	mov	x0, 9223372036854775800
	cmp	x28, x0
	bhi	.L353
	mov	x0, x28
.LEHB3:
	bl	_Znwm
.LEHE3:
	mov	x3, x0
	ldp	x1, x0, [x26, 8]
	sub	x2, x0, x1
.L235:
	add	x28, x3, x28
	stp	x3, x3, [sp, 232]
	str	x28, [sp, 248]
	cmp	x1, x0
	beq	.L237
	mov	x0, x3
	str	x2, [sp, 152]
	bl	memmove
	mov	x3, x0
	ldr	x2, [sp, 152]
.L237:
	add	x3, x3, x2
	ldp	w0, w1, [x19]
	str	w0, [sp, 256]
	str	x3, [sp, 240]
	mov	x2, 1152921504606846975
	str	w1, [sp, 260]
	mul	w0, w0, w1
	sxtw	x0, w0
	cmp	x0, x2
	bhi	.L354
	stp	xzr, xzr, [sp, 264]
	lsl	x28, x0, 3
	str	xzr, [sp, 280]
	cbz	x0, .L239
	mov	x0, x28
.LEHB4:
	bl	_Znwm
.LEHE4:
	add	x3, x0, x28
	str	x0, [sp, 264]
	str	x3, [sp, 280]
	mov	x9, x0
	cmp	x3, x0
	beq	.L240
	mov	x2, x28
	mov	w1, 0
	stp	x0, x3, [sp, 152]
	bl	memset
	ldp	x9, x3, [sp, 152]
.L240:
	str	x3, [sp, 272]
	ldr	w14, [sp, 196]
	cmp	w21, 0
	ble	.L245
	ldrsw	x12, [sp, 260]
	sbfiz	x7, x14, 3, 32
	ldrsw	x6, [sp, 228]
	mov	x8, 0
	add	x12, x12, 1
	ldr	w15, [x19, 4]
	ldr	w4, [x26]
	ldr	w5, [x27]
	lsl	x12, x12, 3
	ldr	x13, [x19, 8]
	lsl	x6, x6, 3
	ldr	x11, [sp, 200]
	ldr	x10, [sp, 232]
	.p2align 3,,7
.L246:
	ldr	w0, [x20, x8, lsl 2]
	madd	w1, w0, w15, w0
	ldr	d0, [x13, w1, sxtw 3]
	str	d0, [x9]
	cmp	w5, 0
	ble	.L248
	ldr	x1, [x22]
	mov	x3, x11
	ldrsw	x16, [x27, 4]
	mov	w2, 0
	add	x1, x1, x0, sxtw 3
	lsl	x16, x16, 3
	.p2align 3,,7
.L247:
	ldr	d0, [x1]
	add	w2, w2, 1
	add	x1, x1, x16
	str	d0, [x3]
	add	x3, x3, x7
	cmp	w5, w2
	bne	.L247
.L248:
	cmp	w4, 0
	ble	.L250
	ldr	x16, [x23]
	mov	x2, x10
	ldrsw	x3, [x26, 4]
	mov	w1, 0
	add	x0, x16, x0, sxtw 3
	lsl	x3, x3, 3
	.p2align 3,,7
.L249:
	ldr	d0, [x0]
	add	w1, w1, 1
	add	x0, x0, x3
	str	d0, [x2]
	add	x2, x2, x6
	cmp	w1, w4
	bne	.L249
.L250:
	add	x8, x8, 1
	add	x9, x9, x12
	add	x10, x10, 8
	add	x11, x11, 8
	cmp	w21, w8
	bgt	.L246
.L245:
	ldr	w0, [sp, 192]
	add	x21, sp, 192
	stp	w0, w14, [x27]
	add	x1, x21, 8
	mov	x0, x22
	add	x27, sp, 256
	add	x22, sp, 224
.LEHB5:
	bl	_ZNSt6vectorIdSaIdEEaSERKS1_.isra.0
	ldr	x0, [sp, 224]
	str	x0, [x26]
	add	x22, sp, 224
	add	x27, sp, 256
	add	x1, x22, 8
	mov	x0, x23
	bl	_ZNSt6vectorIdSaIdEEaSERKS1_.isra.0
	mov	x0, x19
	add	x1, x27, 8
	ldr	x2, [sp, 256]
	str	x2, [x0], 8
	bl	_ZNSt6vectorIdSaIdEEaSERKS1_.isra.0
.LEHE5:
	ldr	x0, [sp, 264]
	cbz	x0, .L251
	ldr	x1, [sp, 280]
	sub	x1, x1, x0
	bl	_ZdlPvm
.L251:
	ldr	x0, [sp, 232]
	cbz	x0, .L252
	ldr	x1, [sp, 248]
	sub	x1, x1, x0
	bl	_ZdlPvm
.L252:
	ldr	x0, [sp, 200]
	cbz	x0, .L253
	ldr	x1, [sp, 216]
	sub	x1, x1, x0
	bl	_ZdlPvm
.L253:
	cbz	x20, .L303
	sub	x1, x25, x20
	mov	x0, x20
	bl	_ZdlPvm
.L303:
	mov	w0, w24
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
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
	.cfi_restore 73
	.cfi_restore 72
	ldp	x29, x30, [sp], 288
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 27
	.cfi_restore 28
	.cfi_restore 19
	.cfi_restore 20
	.cfi_def_cfa_offset 0
	ret
.L350:
	.cfi_def_cfa_offset 288
	.cfi_offset 19, -272
	.cfi_offset 20, -264
	.cfi_offset 21, -256
	.cfi_offset 22, -248
	.cfi_offset 23, -240
	.cfi_offset 24, -232
	.cfi_offset 25, -224
	.cfi_offset 26, -216
	.cfi_offset 27, -208
	.cfi_offset 28, -200
	.cfi_offset 29, -288
	.cfi_offset 30, -280
	.cfi_offset 72, -192
	.cfi_offset 73, -184
	.cfi_offset 74, -176
	.cfi_offset 75, -168
	.cfi_offset 76, -160
	.cfi_offset 77, -152
	mov	x2, x1
	mov	x0, x4
	mov	x1, x24
	str	x3, [sp, 168]
	bl	memmove
	mov	x4, x0
	ldr	x3, [sp, 168]
.L185:
	mov	x0, x24
	ldr	x1, [sp, 152]
	stp	x4, x3, [sp, 168]
	bl	_ZdlPvm
	ldp	x4, x3, [sp, 168]
	b	.L186
.L349:
	mov	x25, 0
	mov	x3, 0
	mov	x4, 0
	b	.L183
.L276:
	movi	d1, #0
	fmov	d11, d9
	fmov	d0, 1.0e+0
	b	.L204
.L275:
	movi	d1, #0
	fmov	d0, 1.0e+0
	b	.L203
.L269:
	movi	d1, #0
	fmov	d11, d9
	fmov	d0, 1.0e+0
	b	.L170
.L215:
	.cfi_restore 74
	.cfi_restore 75
	.cfi_restore 76
	.cfi_restore 77
	fneg	d0, d0
	str	d0, [x3]
	cmp	w5, 0
	ble	.L218
	ldr	x0, [x22]
	mov	w1, 0
	ldrsw	x4, [x27, 4]
	add	x0, x0, x2, lsl 3
	lsl	x4, x4, 3
	.p2align 3,,7
.L219:
	ldr	d0, [x0]
	add	w1, w1, 1
	fneg	d0, d0
	str	d0, [x0]
	add	x0, x0, x4
	cmp	w5, w1
	bne	.L219
	b	.L218
.L224:
	mov	x1, x25
	mov	x0, x20
	mov	x2, x19
	bl	_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_comp_iterIZN12_GLOBAL__N_1L25make_nonnegative_and_sortER6MatrixSB_SB_EUliiE_EEEvT_SE_T0_
	ldp	x0, x1, [x27]
	stp	x0, xzr, [sp, 192]
	ldr	x0, [x22, 8]
	stp	xzr, xzr, [sp, 208]
	subs	x23, x0, x1
	bne	.L355
.L281:
	mov	x28, 0
	mov	x3, 0
	b	.L232
	.p2align 2,,3
.L229:
	mov	x5, x1
	str	w0, [x1, 4]
	ldr	w0, [x1, -4]!
	madd	w2, w0, w4, w0
	ldr	d0, [x3, w2, sxtw 3]
	fcmpe	d0, d1
	bmi	.L229
	add	x6, x6, 4
	str	w7, [x5]
	cmp	x25, x6
	bne	.L230
	b	.L220
.L279:
	mov	x25, 0
	mov	x20, 0
	b	.L220
.L191:
	.cfi_offset 74, -176
	.cfi_offset 75, -168
	.cfi_offset 76, -160
	.cfi_offset 77, -152
	cbz	x24, .L174
	ldr	x1, [sp, 152]
	mov	x0, x24
	bl	_ZdlPvm
.L174:
	fmov	d0, d8
	mov	x0, x19
	ldp	d10, d11, [sp, 112]
	.cfi_restore 75
	.cfi_restore 74
	mov	w24, 1
	ldp	d12, d13, [sp, 128]
	.cfi_restore 77
	.cfi_restore 76
	bl	_ZN12_GLOBAL__N_1L18cleanup_bidiagonalER6Matrixd
	ldr	w21, [x19, 4]
	cmp	w20, 0
	bgt	.L356
.L211:
	ldr	w5, [x19]
	sxtw	x7, w21
	cmp	w21, 0
	bgt	.L357
.L214:
	add	x22, x27, 8
	mov	x0, 2305843009213693951
	cmp	x7, x0
	bls	.L216
	adrp	x0, .LC4
	add	x0, x0, :lo12:.LC4
	stp	d10, d11, [sp, 112]
	.cfi_remember_state
	.cfi_offset 75, -168
	.cfi_offset 74, -176
	stp	d12, d13, [sp, 128]
	.cfi_offset 77, -152
	.cfi_offset 76, -160
.LEHB6:
	bl	_ZSt20__throw_length_errorPKc
.LEHE6:
	.p2align 2,,3
.L282:
	.cfi_restore_state
	mov	x2, 0
	mov	x3, 0
	b	.L235
.L239:
	mov	x9, 0
	mov	x3, 0
	str	xzr, [sp, 264]
	str	xzr, [sp, 280]
	b	.L240
.L221:
	cmp	w21, 0
	bgt	.L265
	b	.L220
.L353:
.LEHB7:
	bl	_ZSt17__throw_bad_allocv
.LEHE7:
	.p2align 2,,3
.L181:
	.cfi_offset 74, -176
	.cfi_offset 75, -168
	.cfi_offset 76, -160
	.cfi_offset 77, -152
	mov	x22, 9223372036854775800
	b	.L182
.L348:
	adrp	x0, .LC3
	add	x0, x0, :lo12:.LC3
.LEHB8:
	bl	_ZSt20__throw_length_errorPKc
.LEHE8:
.L352:
	.cfi_restore 74
	.cfi_restore 75
	.cfi_restore 76
	.cfi_restore 77
.LEHB9:
	bl	_ZSt17__throw_bad_allocv
.LEHE9:
.L354:
	adrp	x0, .LC4
	add	x0, x0, :lo12:.LC4
.LEHB10:
	bl	_ZSt20__throw_length_errorPKc
.LEHE10:
.L155:
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 72
	.cfi_restore 73
	mov	x0, 16
	bl	__cxa_allocate_exception
	adrp	x1, .LC2
	mov	x19, x0
	add	x1, x1, :lo12:.LC2
.LEHB11:
	bl	_ZNSt16invalid_argumentC1EPKc
.LEHE11:
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -248
	.cfi_offset 21, -256
	stp	x23, x24, [sp, 48]
	.cfi_offset 24, -232
	.cfi_offset 23, -240
.L338:
	adrp	x2, _ZNSt16invalid_argumentD1Ev
	adrp	x1, _ZTISt16invalid_argument
	mov	x0, x19
	add	x2, x2, :lo12:_ZNSt16invalid_argumentD1Ev
	add	x1, x1, :lo12:_ZTISt16invalid_argument
	stp	d8, d9, [sp, 96]
	.cfi_offset 73, -184
	.cfi_offset 72, -192
	stp	d10, d11, [sp, 112]
	.cfi_offset 75, -168
	.cfi_offset 74, -176
	stp	d12, d13, [sp, 128]
	.cfi_offset 77, -152
	.cfi_offset 76, -160
.LEHB12:
	bl	__cxa_throw
.LEHE12:
.L289:
	.cfi_restore 74
	.cfi_restore 75
	.cfi_restore 76
	.cfi_restore 77
	add	x21, sp, 192
	mov	x19, x0
	b	.L257
.L152:
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 25
	.cfi_restore 26
	.cfi_restore 72
	.cfi_restore 73
	mov	x0, 16
	bl	__cxa_allocate_exception
	adrp	x1, .LC1
	mov	x19, x0
	add	x1, x1, :lo12:.LC1
.LEHB13:
	bl	_ZNSt16invalid_argumentC1EPKc
.LEHE13:
.L337:
	stp	x21, x22, [sp, 32]
	.cfi_remember_state
	.cfi_offset 22, -248
	.cfi_offset 21, -256
	stp	x23, x24, [sp, 48]
	.cfi_offset 24, -232
	.cfi_offset 23, -240
	stp	x25, x26, [sp, 64]
	.cfi_offset 26, -216
	.cfi_offset 25, -224
	b	.L338
.L342:
	.cfi_restore_state
	mov	x0, 16
	bl	__cxa_allocate_exception
	adrp	x1, .LC0
	mov	x19, x0
	add	x1, x1, :lo12:.LC0
.LEHB14:
	bl	_ZNSt16invalid_argumentC1EPKc
.LEHE14:
	b	.L337
.L285:
.L341:
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -248
	.cfi_offset 21, -256
	stp	x23, x24, [sp, 48]
	.cfi_offset 24, -232
	.cfi_offset 23, -240
	stp	x25, x26, [sp, 64]
	.cfi_offset 26, -216
	.cfi_offset 25, -224
.L339:
	mov	x1, x0
	mov	x0, x19
	mov	x19, x1
	stp	d8, d9, [sp, 96]
	.cfi_offset 73, -184
	.cfi_offset 72, -192
	stp	d10, d11, [sp, 112]
	.cfi_offset 75, -168
	.cfi_offset 74, -176
	stp	d12, d13, [sp, 128]
	.cfi_offset 77, -152
	.cfi_offset 76, -160
	bl	__cxa_free_exception
.L340:
	mov	x0, x19
.LEHB15:
	bl	_Unwind_Resume
.LEHE15:
.L284:
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 25
	.cfi_restore 26
	.cfi_restore 72
	.cfi_restore 73
	.cfi_restore 74
	.cfi_restore 75
	.cfi_restore 76
	.cfi_restore 77
	b	.L341
.L291:
	.cfi_offset 21, -256
	.cfi_offset 22, -248
	.cfi_offset 23, -240
	.cfi_offset 24, -232
	.cfi_offset 25, -224
	.cfi_offset 26, -216
	.cfi_offset 72, -192
	.cfi_offset 73, -184
	mov	x19, x0
	add	x0, x27, 8
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L256:
	add	x0, x22, 8
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L257:
	add	x0, x21, 8
	bl	_ZNSt12_Vector_baseIdSaIdEED2Ev
.L258:
	stp	d10, d11, [sp, 112]
	.cfi_remember_state
	.cfi_offset 75, -168
	.cfi_offset 74, -176
	sub	x1, x25, x20
	stp	d12, d13, [sp, 128]
	.cfi_offset 77, -152
	.cfi_offset 76, -160
	cbz	x20, .L340
	mov	x0, x20
	bl	_ZdlPvm
	b	.L340
.L290:
	.cfi_restore_state
	add	x21, sp, 192
	mov	x19, x0
	add	x22, sp, 224
	b	.L256
.L287:
	.cfi_offset 74, -176
	.cfi_offset 75, -168
	.cfi_offset 76, -160
	.cfi_offset 77, -152
	mov	x19, x0
	cbz	x24, .L340
	ldr	x1, [sp, 152]
	mov	x0, x24
	bl	_ZdlPvm
	b	.L340
.L286:
	.cfi_restore 21
	.cfi_restore 22
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 72
	.cfi_restore 73
	.cfi_restore 74
	.cfi_restore 75
	.cfi_restore 76
	.cfi_restore 77
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -248
	.cfi_offset 21, -256
	stp	x23, x24, [sp, 48]
	.cfi_offset 24, -232
	.cfi_offset 23, -240
	b	.L339
.L288:
	.cfi_offset 72, -192
	.cfi_offset 73, -184
	mov	x19, x0
	b	.L258
	.cfi_endproc
.LFE3926:
	.global	__gxx_personality_v0
	.section	.gcc_except_table,"a",@progbits
.LLSDA3926:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE3926-.LLSDACSB3926
.LLSDACSB3926:
	.uleb128 .LEHB0-.LFB3926
	.uleb128 .LEHE0-.LEHB0
	.uleb128 .L287-.LFB3926
	.uleb128 0
	.uleb128 .LEHB1-.LFB3926
	.uleb128 .LEHE1-.LEHB1
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB2-.LFB3926
	.uleb128 .LEHE2-.LEHB2
	.uleb128 .L288-.LFB3926
	.uleb128 0
	.uleb128 .LEHB3-.LFB3926
	.uleb128 .LEHE3-.LEHB3
	.uleb128 .L289-.LFB3926
	.uleb128 0
	.uleb128 .LEHB4-.LFB3926
	.uleb128 .LEHE4-.LEHB4
	.uleb128 .L290-.LFB3926
	.uleb128 0
	.uleb128 .LEHB5-.LFB3926
	.uleb128 .LEHE5-.LEHB5
	.uleb128 .L291-.LFB3926
	.uleb128 0
	.uleb128 .LEHB6-.LFB3926
	.uleb128 .LEHE6-.LEHB6
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB7-.LFB3926
	.uleb128 .LEHE7-.LEHB7
	.uleb128 .L289-.LFB3926
	.uleb128 0
	.uleb128 .LEHB8-.LFB3926
	.uleb128 .LEHE8-.LEHB8
	.uleb128 .L287-.LFB3926
	.uleb128 0
	.uleb128 .LEHB9-.LFB3926
	.uleb128 .LEHE9-.LEHB9
	.uleb128 .L288-.LFB3926
	.uleb128 0
	.uleb128 .LEHB10-.LFB3926
	.uleb128 .LEHE10-.LEHB10
	.uleb128 .L290-.LFB3926
	.uleb128 0
	.uleb128 .LEHB11-.LFB3926
	.uleb128 .LEHE11-.LEHB11
	.uleb128 .L286-.LFB3926
	.uleb128 0
	.uleb128 .LEHB12-.LFB3926
	.uleb128 .LEHE12-.LEHB12
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB13-.LFB3926
	.uleb128 .LEHE13-.LEHB13
	.uleb128 .L285-.LFB3926
	.uleb128 0
	.uleb128 .LEHB14-.LFB3926
	.uleb128 .LEHE14-.LEHB14
	.uleb128 .L284-.LFB3926
	.uleb128 0
	.uleb128 .LEHB15-.LFB3926
	.uleb128 .LEHE15-.LEHB15
	.uleb128 0
	.uleb128 0
.LLSDACSE3926:
	.text
	.size	_Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id, .-_Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id
	.section	.text.startup,"ax",@progbits
	.align	2
	.p2align 4,,11
	.type	_GLOBAL__sub_I__Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id, %function
_GLOBAL__sub_I__Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id:
.LFB4872:
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
.LFE4872:
	.size	_GLOBAL__sub_I__Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id, .-_GLOBAL__sub_I__Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id
	.section	.init_array,"aw"
	.align	3
	.xword	_GLOBAL__sub_I__Z23gkh_svd_from_bidiagonalR6MatrixS0_S0_id
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
