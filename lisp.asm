;;; LISP in x86_64 assembly

[bits 64]
section .text


; r9 = heap pointer

NULL EQU 0
INTEGER EQU 1
STRING EQU 2
LIST EQU 3
HEAP_SIZE EQU 1<<20

EMPTY_LIST EQU 0xDEADBEEF

alloc:
	lea rax, [heap + HEAP_SIZE]
	cmp r9, rax
	jge .fail
	mov rax, r9
	add r9, 0x18
	ret

	.fail:
		mov rdi, msg_fail_heap
		call print_exp
		mov rdi, 0
		mov rax, 60
		syscall	

alloc_int:
	call alloc 
	mov qword [rax], INTEGER
	mov qword [rax+0x08], rdi 
	mov qword [rax+0x10], 0
	ret


alloc_string:
	call alloc 
	mov qword [rax], STRING
	mov qword [rax+0x8], rdi 
	mov qword [rax+0x10], 0
	ret	

;;; cons(rdi = ar, rsi = dr)
cons:
	call alloc 
	mov qword [rax], LIST 
	mov [rax + 0x8], rdi 
	mov [rax + 0x10], rsi
	ret

;;; car(rdi = cell)
car:
	test qword [rdi], LIST
	jz .fail
	mov rax, qword [rdi + 0x8]
	ret
	.fail:
		mov rax, 0
		ret
;;; cdr(rdi = cell)
cdr:
	test qword [rdi], LIST
	jz .fail
	mov rax, qword [rdi + 0x10]
	ret
	.fail:
		mov rax, 0
		ret

;;; strlen(rdi = string)
strlenSSE4:
	xor rax, rax 

	pxor xmm0, xmm0
	mov rax, -16
	.loop:
		; imm[1:0] = 0, source data is unsigned bytes
		; imm[3:2] = 2, equal each aggregation
		; imm[5:4] = 0, positive polarity, res2 = res1
		; imm[6] = 0, ecx is LS bit
		add rax, 16
		pcmpistri xmm0, [rdi + rax], 0001000b
		jnz .loop 
		; rcx contains offset from [rdi+rax] where NULL terminator 
		; is found
		add rax, rcx
		ret

;;; keep CAR=
;;; print_exp(rdi= address of object)
print_exp:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	mov [rsp + 0x08], rdi

	; mov doubleqword unaligned on 16 byte boundary
	; load data[0] and data[1] into xmm0
	movdqu xmm0, [rdi+8]

	;;; Test for print_exp(0)
	test rdi, rdi
	jz .null

	; switch(object->type)
	mov rax, [rdi]			; rax = type 
	cmp rax, 3
	ja .null

	; Load address of subroutine
	mov rax, [.switch + (rax * 8)]
	jmp rax

	; Table containing address of the switch statement
	.switch:
		dq .null
		dq .int 
		dq .str 
		dq .list

	; Print NULL, and exit
	.null:
		mov rsi, .LC_NULL	; ()\n
		mov rax, 3			; strlen
		jmp .print

	; entry point for printing a list
	.list:
		; Start off by printing the open parenthesis
		mov rsi, .LC_OPEN
		mov rdi, 1
		mov rdx, 1
		mov rax, 1
		syscall


		mov rdi, [rsp + 8] 			; restore rdi = exp
		mov rax, [rdi + 8]			; rax = car(exp)
		; while(!null(exp))
		.l1:
			
			; rdi = rax
			mov rdi, rax
			call print_exp

			; rdi = exp
			mov rdi, [rsp + 8]

			; rax = cdr(exp)
			mov rax, [rdi + 16]	

			; cdr(exp) == NULL?
			test rax, rax
			je .l3

		; cdr(exp) != NULL
		.l2:
			mov [rsp + 8], rax 	; exp = cdr(exp)

			; print " "
			mov rsi, .LC_SPACE
			mov rdi, 1
			mov rdx, 1
			mov rax, 1
			syscall

			; rax = exp
			mov rax, [rsp + 8]
			jmp .l1

		; cdr(exp) == NULL
		.l3:
			mov rsi, .LC_CLOSE
			mov rax, 1
			jmp .print

	.str:
		mov rsi, [rdi + 8] 		; rsi = rdi->data[0]
		mov rdi, rsi			; rdi = object->data[0]
		call strlenSSE4 		; rax = strlen 
		jmp .print 				; print and exit

	.int:
		mov rsi, itoa_buf
		mov rax, [rsp + 8]
		mov rcx, [rax + 8]
		add rcx, '0'
		mov byte [rsi], cl
		mov rax, 1

	.print:
		mov rdi, 1 				; rdi = stdin
		mov rdx, rax 			; rdx = rax = strlen 
		mov rax, 1				; rax = SYS_write
		syscall 
		; Fall through to exit
	.fin:
		mov rdi, [rsp + 8] 		; restore rdi to original called value 
		add rsp, 0x20			; clean up stack
		mov rsp, rbp
		pop rbp
		ret
.LC_NULL:
	db "'()"
.LC_OPEN:
	db "("
.LC_CLOSE:
	db ")"
.LC_SPACE:
	db " "

reverse:
	ret


read_string:
	push rbp 
	mov rbp, rsp 
	sub rsp, 128 	; allocate 128 byte buffer on stack
	mov r10, rsp

	.L1:
		mov rdi, 0		; read from stdin
		lea rsi, [r10] 	; read into buffer 
		mov rdx, 1 		; read one byte
		mov rax, 0		; SYS_read
		syscall

		mov rax, [r10]
	;	cmp rax, 

		; while n < buffer_size
		cmp r10, rbp 
		jb .L1
	.L2:


read_list:
	push rbp 
	mov rbp, rsp 
	sub rsp, 0x20 
	mov qword [rsp + 0], 0				; obj*
	mov rcx, EMPTY_LIST
	mov qword [rsp + 8], rcx 		; cell*

.L1:
	call read_exp
	mov [rsp + 0], rax
	mov rcx, EMPTY_LIST
	cmp rax, rcx
	jne .L2 

	; obj = EMPTY_LIST
	mov rdi, [rsp + 8]
	mov rsi, EMPTY_LIST
	call reverse
	jmp .DONE
.L2:
	mov rdi, [rsp]		; obj
	mov rsi, [rsp + 8]	; cell 
	call cons 
	mov [rsp + 8], rax 	; cell = cons(obj, cell)
	jmp .L1

.DONE:	
	mov rsp, rbp
	pop rbp
	ret

read_int:
	push rbp
	mov rbp, rsp
	sub rsp, 8
	xor rcx, rcx
	
.get:
	mov rdi, 0		; read from stdin
	lea rsi, [rsp] 	; read into [rsp]
	mov rdx, 1 		; read one byte
	mov rax, 0		; SYS_read
	syscall

	mov rax, [rsp]
	cmp al, '0'
	jb .exit		; rax < 0, error
	cmp al, '9'
	ja .exit


	sub rax, '0'
	push rcx 
	mov rcx, 10
	mul rcx 
	pop rcx
	add rcx, rax

	jmp .get

.exit:
	mov rdi, rcx 
	call alloc_int
	mov rsp, rbp
	pop rbp
	ret

read_exp:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20

;; essentially getc()
;; we allocate a space on the stack to read a byte
.getc:
	mov rdi, 0		; read from stdin
	lea rsi, [rsp] 	; read into [rsp]
	mov rdx, 1 		; read one byte
	mov rax, 0		; SYS_read
	syscall
	cmp rax, 0
	js .exit		; rax < 0, error

	mov rax, [rsp]
	test rax, rax 
	je .exit

	test rax, 10
	je .exit


	mov rdi, 1
	lea rsi, [rsp]
	mov rdx, 1
	mov rax, 1
	syscall
	jmp .getc

.exit:


	mov rsp, rbp
	pop rbp
	ret



global _start
_start:

	push rbp
	mov rbp, rsp
	sub rsp, 0x20


	;call read_exp

	;call read_string

	;mov rdi, rax 
	;call print_exp
	;int 3

	mov r9, heap

	mov rdi, msg_test 		; string value = msg test
	call alloc_string		; rax = object
	mov [rsp+8], rax 		; store object* in stack

	mov rdi, 8 				; integer value = 8
	call alloc_int 			; rax = object
	mov [rsp+16], rax 		; store object* in stack


	mov rdi, [rsp+8]
	mov rsi, [rsp+16]

	call cons 
	test rax, rax
	je .fail
	mov rdi, rax

	push rdi 
	mov rdi, 9
	call alloc_int 
	mov rsi, rax 
	pop rdi
	call cons
	mov rdi, rax

	; push rdi 
	; mov rdi, msg 
	; call alloc_string
	; mov rdi, rax 
	; pop rsi
	; call cons
	; mov rdi, rax

	call print_exp



.exit:
	mov rdi, 0
	mov rax, 60
	syscall

.fail:
	mov rsi, msg_fail 
	mov rdx, 5
	mov rdi, 1
	mov rax, 1
	syscall 
	jmp .exit


section .data
msg_fail:
	db "FAIL", 10, 0
msg_test:
	db "Test", 0
msg:
	db "Hello, world my name is michael!", 0
msg_fail_heap:
	db "No more memory in heap, restart!!!", 10, 0
msg_int:
	db "Integer!", 10, 0
msg_cons:
	db "LIST", 10, 0


section .bss
itoa_buf:
	resb 32
buf:
	resb 32
heap:
	resb HEAP_SIZE 	; Resb 1 mb of heap