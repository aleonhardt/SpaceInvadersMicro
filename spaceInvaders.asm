USING	0	;Register bank 0 is the current bank

;;;;;;;;;;;;;; PROGRAM DATA
INI_PROG  	EQU		0100H
INT_TIM0	EQU		000BH
INT_TIM1	EQU		001BH


;;;;;;;;;;; DISPLAY DATA
SELECT 		BIT		00H ;SELECIONA O LADO ESQUERDO OU DIREITO DO LCD (0/1)
BOTH		BIT		01H	;QUANDO ESTÁ EM UM INDICA QUE DEVE ESCREVER EM UM LADO DEPOIS NO OUTRO

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
 	INC R7
	MOV A, R7
	SUBB A, #0100D
	JC VOLTA_TIM0
	JZ MAIN_LOOP
VOLTA_TIM0:
	RETI


;;;;;;;;;;;;;;;;;;;;;; função de debounce
;; B-QUAL BUTTON  0-P0.0, 1-P0.1 ETC
;;RETURN B=00 SE BOTAO ESTÁ PRESSIONADO E B=FF SE NÃO ESTÁ
DEBOUNCE_BUTTON:
	MOV A, B
	JZ BUTTON_0
	SUBB A, #2H
	JC BUTTON_1
	JZ BUTTON_2
	JMP BUTTON_3
	
BUTTON_0:
	MOV A, #0FFH
BOUNCE_0:
	DEC A
	JZ BUTTON_IS_PRESSED
	JB P0.0 ,BOUNCE_0

BUTTON_1:
	MOV A, #0FFH
BOUNCE_1:
	DEC A
	JZ BUTTON_IS_PRESSED
	JB P0.1 ,BOUNCE_1

BUTTON_2:
	MOV A, #0FFH
BOUNCE_2:
	DEC A
	JZ BUTTON_IS_PRESSED
	JB P0.2 ,BOUNCE_2

BUTTON_3:
	MOV A, #0FFH
BOUNCE_3:
	DEC A
	JZ BUTTON_IS_PRESSED
	JB P0.3 ,BOUNCE_3

BUTTON_IS_NOT_PRESSED:
	MOV B, #0FFH
	RET

BUTTON_IS_PRESSED:
	MOV B, #00H
	RET
;;;;;;;;;;;;; FIM DA FUNÇÃO DE DEBOUNCE 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;; ESCREVE A TELA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; TRADUZ A POSIÇÃO X [DADA EM A] DE 0 A 127 PARA X DE 0 A 63 E QUAL DOS LADOS DO LCD USAR
TRADUZ_X:
		PUSH AR1	  ;SALVA O R1
		MOV R1, A
		 SUBB A, #64D
		 JC LADO_ESQUERDO
LADO_DIREITO:
		SETB SELECT
		POP AR1
		RET
LADO_ESQUERDO:
		MOV A, R1
		CLR SELECT
		POP AR1	;DEVOLVE O R1
		RET

		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;MUDA O LADO [ESQUERDO PARA O DIREITO] EM QUE ESTÁ SENDO ESCRITO ALGO NO LCD

MUDA_LADO:
			SETB SELECT		;ESCREVE NO LADO DIREITO
			MOV A, #40H
			CALL ESCREVE_COMANDO_LCD
			MOV A, #0B8H		   ;COMANDO PÁGINAS
			ADD A, #07H		;COLOCA NA PARTE DE BAIXO DA TELA  
			CALL ESCREVE_COMANDO_LCD
			RET
			
;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE MUDA O LADO	 NO LCD
	
 ;POSIÇÃO X DO INICIO DADA EM A E O SELECT DEFINE QUAL LADO
 ;USA O A E O B SEM SALVAR
LIMPA_NAVE:	 PUSH AR1
			JNB SELECT, LIMPA_DOIS_LADOS 	;ESCREVE A NAVE DO LADO ESQUERDO

SO_UM_LADO:
			ADD A, #40H		   ;DEFINE A POSIÇÃO x
			CALL ESCREVE_COMANDO_LCD
			MOV A, #0B8H		   ;COMANDO PÁGINAS
			ADD A, #07H		;COLOCA NA PARTE DE BAIXO DA TELA  
			CALL ESCREVE_COMANDO_LCD
			
			MOV R1, #11D
			MOV A, #0H
LIMPA_ET:
	 		 CALL ESCREVE_DADO_LCD
			 DJNZ R1, LIMPA_ET
			 POP AR1
			 RET
LIMPA_DOIS_LADOS:
 			MOV R1, A
			SUBB A, #52D
			MOV A, R1
			JC SO_UM_LADO
			MOV R1, #11D
			MOV B, A		  //MARCA A COLUNA QUE ESTA

LIMPA_ET2:	
			MOV A, #0H
			CALL ESCREVE_DADO_LCD
			INC B
			MOV A, B
			SUBB A, #63D
			JZ MUDA_LADO_LIMPAR
CLEANNING:	DJNZ R1, LIMPA_ET2
			POP AR1
			RET

MUDA_LADO_LIMPAR:
			CALL MUDA_LADO	
			MOV B, #0F0H	 ;QUALQUER COISA
			JMP CLEANNING
;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE LIMPA A NAVE


;; DESENHA A NAVE [SPACE INVADER] COM A POSIÇÃO X DO INÍCIO DADA EM A, E NA BASE DA TELA e o select define qual o lado	
 DESENHA_NAVE:
		  
			  ADD A, #40H		   ;DEFINE A POSIÇÃO x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO PÁGINAS
			  ADD A, #07H		;COLOCA NA PARTE DE BAIXO DA TELA  
			  CALL ESCREVE_COMANDO_LCD
			 	;DESENHAR O BIXINHO
			  MOV A, #70H
			  CALL ESCREVE_DADO_LCD
			  MOV A, #18H
			  CALL ESCREVE_DADO_LCD
			  MOV A, #7DH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #0B6H
			  CALL ESCREVE_DADO_LCD
			  MOV A, #0BCH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #3CH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #0BCH
			  CALL ESCREVE_DADO_LCD
			   MOV A, #0B6H
			  CALL ESCREVE_DADO_LCD
			   MOV A, #7DH
			  CALL ESCREVE_DADO_LCD
			   MOV A, #18H
			  CALL ESCREVE_DADO_LCD
			  MOV A, #70H
			  CALL ESCREVE_DADO_LCD
			  RET
;;FIM DA FUNÇÃO QUE DESENHA O MOSNTRINHO

;;;;;;;;;;;;;;;FUNÇÃO QUE DESENHA O INIMIGO, POSIÇÃO X DADA EM A, LINHA Y DADA EM B
DESENHA_INIMIGO:
		  
			  ADD A, #40H		   ;DEFINE A POSIÇÃO x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO PÁGINAS
			  ADD A, B		;COLOCA NO LUGAR CERTO DA TELA  
			  CALL ESCREVE_COMANDO_LCD
			 	;DESENHAR A NAVEZINHA DO INIMIGO
			  MOV A, #0FH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #7FH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #0FFH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #7FH
			  CALL ESCREVE_DADO_LCD
			   MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			   MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			   MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			  MOV A, #0FH
			  CALL ESCREVE_DADO_LCD
			  RET
 ;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE DESENHA O UM INIMIGO

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
		PUSH AR0
		mov	r0,  #10
		djnz	r0, $   ;GERA ATRASO
		POP AR0
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
	PUSH AR0
	mov	r0,  #10
	djnz	r0, $	   ;CRIA UM ATRASO
	POP AR0
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
		PUSH AR7              
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
		POP AR7               
        ret






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;; DADOS NA MEMÓRIA;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIMIGOS:;X,Y[lcd page]
	DB 	96D, 0D
	DB	75D, 0D
	DB	54D, 0D
	DB	31D, 0D //PRIMEIRA LINHA
	DB 	96D, 1D
	DB	75D, 1D
	DB	54D, 1D
	DB	31D, 1D //SEGUNDA LINHA


NAVE:  ;X, Y[lcd page], VIDAS
	DB 63D, 2D, 3D

TIROS:	;X,Y, DIREÇÃO
	DB 0FFH, 0FFH, 0FFH	  ;;COMO COLOCAR VÁRIOS TIROS NESSA MATRIX DEPOIS? OU JÁ DEIXAR A MATRIX COM UM TAMANHO GRANDE?


END