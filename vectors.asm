
;;; vector* vector_adds(vector* v, float f)
;;; gcc/SysV will pass f in XMM0
global vector_adds
vector_adds:
	movaps xmm2, [rdi]		; load v into XMM2
	shufps xmm0, xmm0, 0x80	; load all four positions with f except pad
	addps xmm2, xmm0 
	movaps [rdi], xmm2
	mov rax, rdi 
	ret

global vector_muls
vector_muls:
	movaps xmm2, [rdi]		; load v into XMM2
	shufps xmm0, xmm0, 0x80	; load all four positions with f except pad
	mulps xmm2, xmm0 
	movaps [rdi], xmm2
	mov rax, rdi 
	ret

global vector_divs
vector_divs:
	movaps xmm2, [rdi]		; load v into XMM2
	shufps xmm0, xmm0, 0x80	; load all four positions with f except pad
	divps xmm2, xmm0 
	movaps [rdi], xmm2
	mov rax, rdi 
	ret

global vector_subs
vector_subs:
	movaps xmm2, [rdi]		; load v into XMM2
	shufps xmm0, xmm0, 0x80	; load all four positions with f except pad
	subps xmm2, xmm0 
	movaps [rdi], xmm2
	mov rax, rdi 
	ret

global vector_add
vector_add:
	movaps xmm0, [rdi]
	addps xmm0, [rsi]
	movaps [rdi], xmm0 
	mov rax, rdi
	ret

global vector_mul
vector_mul:
	movaps xmm0, [rdi]
	mulps xmm0, [rsi] 
	movaps [rdi], xmm0 
	mov rax, rdi
	ret

global vector_div
vector_div:
	movaps xmm0, [rdi]
	divps xmm0, [rsi] 
	movaps [rdi], xmm0 
	mov rax, rdi
	ret


global vector_sq
vector_sq:
	movaps xmm0, [rdi]
	mulps xmm0, xmm0
	movaps [rdi], xmm0 
	mov rax, rdi
	ret

global vector_sqrt
vector_sqrt:
	sqrtps xmm0, [rdi]
	movaps [rdi], xmm0
	mov rax, rdi
	ret


global vector_magnitude
vector_magnitude:
	movaps xmm0, [rdi]
	mulps xmm0, xmm0		; xmm0 contains V.x^2, V.y^2, V.z^2
	haddps xmm0, xmm0 		; xmm0 V.x + V.y | V.z | V.x + V.y | V.z (V.z + padding)
	haddps xmm0, xmm0 		; xmm0 contains only V.x + V.y + V.z (+ padding?)
	sqrtps xmm0, xmm0 		; xmm0 = sqrt(xmm0)
	lea rax, [rsp - 8] 		; leaf function, so we just make space on the stack 
	movlps [rax], xmm0  	; load the two low floats from xmm0 into mem64 
	mov rax, [rax] 			; load value into rax 
	shr rax, 32				; clear the high floats 
	ret