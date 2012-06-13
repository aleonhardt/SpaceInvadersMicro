
;;;;;;;;;;;;;; PROGRAM DATA
INI_PROG  	EQU		0100H
INT_TIM0	EQU		000BH
INT_TIM1	EQU		001BH


;;;;;;;;;;; DISPLAY DATA
DATA_DISP	EQU	P1		; Porta onde esta colocado o barramento de dados do display
EN 			EQU P3.7	; Bit EN do Display		
RS 			EQU P3.6	; Bit R/S do Display

ORG 	0000H			; Vetor RESET
   	LJMP 	INICIO			; Pula para o inicio do programa principal

ORG INT_TIM0
	JMP TRATA_TIM0 ;ATUALIZA A TELA A CADA 0.1 SEGUNDOS. A CADA Y VEZES QUE ATUALIZOU A TELA FAZ COISAS COMO ANDAR OS INIMIGOS E OS TIROS. 
				 ;SEMPRE QUE ATUALIZA A TELA ANDA A NAVE OU ATIRA

ORG INI_PROG
INICIO:
	 CALL IMPRIME_TELA_INICIAL
	;;SETANDO O TIMER
	SETB EA
	SETB ET0
	MOV TMOD, #02H
	MOV TH0, #09BH ;100 VEZES
	MOV TL0,  #09BH
	MOV R7, #0H
	SETB TR0
	;;TIMER SETADO

MAIN_LOOP:
	 MOV R7, #0H

;;;BLABLABLA
	 RETI
;;;;;;;;;;;;;;;;;;;FIM DO MAIN LOOP



;;; FUNÇÃO QUE TRATA O TIMER 0
;QUANDO ELE CONTAR 100 VEZES, CHAMA O MAIN LOOP, QUE É O TEMPO CERTO DE ATUALIZAÇÃO
TRATA_TIM0:
	PUSH A
 	INC R7
	MOV A, R7
	SUBB A, #0100D
	JC VOLTA_TIM0
	JZ MAIN_LOOP
VOLTA_TIM0:
	POP A
	RETI


;;;;;;;;;;;;;;;;;;;;;; função de debounce
;; B-QUAL BUTTON  0-P0.0, 1-P0.1 ETC
;;RETURN B=00 SE BOTAO ESTÁ PRESSIONADO E B=FF SE NÃO ESTÁ
DEBOUNCE_BUTTON:
	PUSH A
	MOV A, B
	JZ BUTTON_0
	SUBB A, #2H
	JC BUTTON_1
	JZ BUTTON_2
	JMP BUTTON_3
	
BUTTON_0:
	MOV A, #0200H
BOUNCE_0:
	DEC A
	JZ BUTTON_IS_PRESSSED
	JB P0.0 ,BOUNCE_0

BUTTON_1:
	MOV A, #0200H
BOUNCE_1:
	DEC A
	JZ BUTTON_IS_PRESSSED
	JB P0.1 ,BOUNCE_1

BUTTON_2:
	MOV A, #0200H
BOUNCE_2:
	DEC A
	JZ BUTTON_IS_PRESSSED
	JB P0.2 ,BOUNCE_2

BUTTON_3:
	MOV A, #0200H
BOUNCE_3:
	DEC A
	JZ BUTTON_IS_PRESSSED
	JB P0.3 ,BOUNCE_3

BUTTON_IS_NOT_PRESSED:
	POP A
	MOV B, #0FFH
	RET

BUTTON_IS_PRESSED:
	POP A
	MOV B, #00H
	RET
;;;;;;;;;;;;; FIM DA FUNÇÃO DE DEBOUNCE 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;; ESCREVE A TELA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
 ;;FUNÇÃO PRECISA SER FEITA


 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 ;;;;;;;; CONTROLE DO DISPLAY ;;;;;;;;;;;;;;;;;;;;;;;

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 ; port 0 is used for data lines 
	; port 1 is used for control lines as listed below
	; P1.0 ---RS
	; P1.1 ---R / W 
	; P1.2 ---E 
	; P1.3 ---CS1 
	; P1.4 ---CS2  

;-- Gera atraso proporcionao ao valor de R7
;
ATRASO:
	PUSH 	06h			; Salva o valor de R6
DEL1:
	MOV		R6,#0FFh
	DJNZ	R6,$
	DJNZ	R7,DEL1		; Repeteo o DJNZ com R6 o numero de vezes de R7
	POP		06h			; Recupera Valor de R6
	RET					; Sai da Sub-rotina


;--------------------------------------------------------------------------------
;-- Envia (escreve) comando colocado em A para o LCD,  seleciona qual parte com o bit select
;

ESCREVE_COMANDO_LCD:
	     jb 	Select, Cs_2	;SELECT É UM BIT QUE DEFINE SE TU ESCREVE NO CS1 E O CS2
		clr	p1.4
  		setb 	p1.3               ;Chip select cs1 enabled 
 		jmp 	ESCREVE_INST
Cs_2:    clr	p1.3
		setb 	p1.4               ;Chip select cs2 enabled 
ESCREVE_INST:		
		nop
		mov	r0,  #10
		djnz	r0, $   ;GERA ATRASO
		clr 	p1.1               ;Write mode selected
  		clr 	p1.0               ;Instruction mode selected
 		mov 	p0, a            ;Place Instruction on bus
  		setb 	p1.2               ;Enable High
  		nop
  		clr 	p1.2               ;Enable Low
  		nop
  		clr 	p1.3               ;put cs1 in non select mode
  		clr 	p1.4               ;put cs2 in non select mode
  		ret

	
;--------------------------------------------------------------------------------
;-- Envia (escreve) dado colocado em A para o LCD , seleciona qual parte com o bit select
;
ESCREVE_DADO_LCD:
  	jb 	Select,Cs_2a   		;VER SE QUER ESCREVER NO CS1 OU NO CS2
	clr	p1.4
	setb 	p1.3               ;Chip select cs1 enabled 
	jmp 	ESCR_DADO
Cs_2a:    		
	clr	p1.3
	setb 	p1.4               ;Chip select cs2 enabled 

ESCR_DADO:		
	nop
	mov	r0,  #10
	djnz	r0, $	   ;CRIA UM ATRASO
	clr  	p1.1               ;Write mode selected
	setb 	p1.0               ;Data mode selected
	mov 	p0,A               ;Place data on bus
	setb 	p1.2               ;Enable High
	nop
	clr 	p1.2               ;Enable Low
	nop
	clr  	p1.3               ;put cs1 in non select mode
	clr  	p1.4               ;put cs2 in non select mode
   		ret
;--------------------------------------------------------------------------------
;-- Inicializa o Display: Envia comandos para configurar LCD
;
INICIO_LCD:   
mov 	a, #3eh            ; Display off 
        call 	ESCREVE_COMANDO_LCD                
  		mov 	r7, 0ffh
  		djnz 	r7, $			   ;GERA ATRASO
  		mov 	a,  #3fh          ; Display on
  		call 	ESCREVE_COMANDO_LCD               
  		mov 	r7, #0ffh
  		djnz 	r7,  $ 		;GERA ATRASO
  		mov 	a, #0c0h               	
  		call 	ESCREVE_COMANDO_LCD               
  		mov 	a, #40h            ; Y address counter at First column
  		call 	ESCREVE_COMANDO_LCD                
  		mov 	a,  #0b8h          ; X address counter at Starting point
  		call 	ESCREVE_COMANDO_LCD                
        ret






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;; DADOS NA MEMÓRIA;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIMIGOS:;X,Y
	DB 	96D, 63D
	DB	75D, 63D
	DB	54D, 63D
	DB	31D, 63D //PRIMEIRA LINHA
	DB 	96D, 43D
	DB	75D, 43D
	DB	54D, 43D
	DB	31D, 43D //SEGUNDA LINHA


NAVE:  ;X, Y, VIDAS
	DB 63D, 2D, 3D

TIROS:	;X,Y, DIREÇÃO
	DB 0FFH, 0FFH, 0FFH	  ;;COMO COLOCAR VÁRIOS TIROS NESSA MATRIX DEPOIS? OU JÁ DEIXAR A MATRIX COM UM TAMANHO GRANDE?


END