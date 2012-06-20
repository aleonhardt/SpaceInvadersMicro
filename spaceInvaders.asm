USING	0	;Register bank 0 is the current bank

;;;;;;;;;;;;;; PROGRAM DATA
INI_PROG  	EQU		0100H
INT_TIM0	EQU		000BH
INT_TIM1	EQU		001BH


;;;;;;;;;;; DISPLAY DATA
SELECT 		BIT		00H ;SELECIONA O LADO ESQUERDO OU DIREITO DO LCD (0/1)
TODOS 		BIT		03H	;QUANDO ESTÁ EM UM INDICA QUE DEVE ESCREVER NOS DOIS LADOS

LCD_DATA	EQU 	P3
LCD_DI		EQU		P2.0					 ;;;;;;; COLOCAR ESSES DEFINES NOS LUGARES QUE ACESSA
LCD_RW		EQU		P2.1
LCD_E		EQU		P2.2
LCD_C1		EQU		P2.3
LCD_C2		EQU		P2.4

;;;;;;;;;;;;;;;;;;;;; BOTÕES
BOTAO_DIR	EQU		P1.3
BOTAO_ESQ	EQU		P1.2
BOTAO_TIRO	EQU		P1.0

;;;;;;;;; LEDS
LED1		EQU		P2.5
LED2		EQU		P2.6
LED3		EQU		P2.7


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


 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;; IMPRIME A TELA INICIAL, COM OS INIMIGOS E A NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 IMPRIME_TELA_INICIAL:
 	PUSH AR1
	PUSH AR2
 	MOV DPTR, #NAVE
	CLR A
	MOVC A, @A+DPTR	;;A FICA COM A POSIÇÃO x DA NAVE
	CALL TRADUZ_X	;;A FICA COM A POSIÇÃO X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL DESENHA_NAVE  ;; DESENHA A NAVE NO NOVO LUGAR DA TELA

	MOV R1, #8D	  ;;SÃO 8 INIMIGOS PARA DESENHAR
	MOV DPTR, #INIMIGOS
IMPRIME_INIMIGOS:

	MOVC  A, @A+DPTR ;;MOVE X DE UM  INIMIGO PARA O A
	CALL TRADUZ_X ;;A FICA COM O X CORRETO
	MOV B,A	  ;; SALVA O X NO B
	MOV A, R2
	INC A	  
	MOVC A, @A+DPTR ;;A TEM O Y AGORA
	MOV R3, A
	MOV A, B ;; A FICA COM O X
	MOV B, R3 ;; B FICA COM O Y
	CALL DESENHA_INIMIGO

	
;PROXIMO_INIMIGO:
	 INC R2
	 INC R2
	 MOV A, R2 	   ;; APONTA PARA O PRÓXIMO INIMIGO

	 DJNZ R1, IMPRIME_INIMIGOS 

	  POP AR2
	  POP AR1
	  RET
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE DESENHA A TELA INICIAL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; PEGA A POSIÇÃO DA MEMÓRIA E ESCREVE A NAVE, A POSIÇÃO X ANTIGA DA NAVE FICA EM B
MOVE_NAVE:
	MOV A, B	;;POSIÇÃO ANTIGA DA NAVE, PARA LIMPAR A NAVE
   	CALL TRADUZ_X	;;A FICA COM A POSIÇÃO X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL LIMPA_NAVE	 ;; LIMPA A NAVE DA TELA

	MOV DPTR, #NAVE
	CLR A
	MOVC A, @A+DPTR	;;A FICA COM A POSIÇÃO x DA NAVE
	CALL TRADUZ_X	;;A FICA COM A POSIÇÃO X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL DESENHA_NAVE  ;; DESENHA A NAVE NO NOVO LUGAR DA TELA
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE PEGA OS DADOS DA MEMÓRIA E DESENHA A NAVE NA TELA;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PEGA A POSIÇÃO DA MEMÓRIA E LIMPA A NAVE. DEPOIS DE UM TEMPO ESCREVE ELA DENOVO NO MEIO, X =59 D;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MATA_NAVE:
	PUSH AR1
	MOV DPTR, #NAVE
	CLR A
	MOVC A, @A+DPTR	;;A FICA COM A POSIÇÃO x DA NAVE
	CALL TRADUZ_X	;;A FICA COM A POSIÇÃO X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	MOV R1, A
	CALL LIMPA_NAVE	 ;; LIMPA A NAVE DA TELA
	MOV A, R1
	MOV R1, #0FH
	DJNZ R1, $
	CALL DESENHA_MORTE_NAVE	;DESENHA A MORTE E LIMPA DEPOIS DE UM TEMPO
	MOV	 A, #59D
	CLR SELECT
	CALL DESENHA_NAVE
	POP AR1
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE MATA A NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; MATA UM INIMIGO. QUAL INIMIGO É INDICADO POR A, AS POSIÇÕES DE MEMÓRIA DEVEM SER VÁLIDAS;;;;
;;;;;;;;;;;;;;;;;;;; SO DEPOIS ZERAR AS POSIÇÕES DE MEMÓRIA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MATA_UM_INIMIGO:
	PUSH AR1
	MOV DPTR, #INIMIGOS 
	MOV B, A
	ADD A, B ;;PARA APONTAR PARA O LUGAR CORRETO
	MOV R1, A ;;SALVA O LUGAR CORRETO
	MOVC A, @A+DPTR ;; A AGORA TEM O X DO INIMIGO
	CALL TRADUZ_X ;;A FICA COM O X CORRETO E O BIT SELECT FICA CERTO
	MOV B, A ;; SALVA O X CORRETO
	MOV A, R1;; VOLTA PARA O LUGAR CORRETO
	INC A ;;PEGAR O Y AGORA
	MOVC A, @A+DPTR	  ;;A COM O Y
	MOV R1, A
	MOV A, B	;;; A FICA COM O X CORRETO
	MOV B, R1 	;;;;;;;;;;;;;;;;; B FICA COM O Y CORRETO
	CALL LIMPA_INIMIGO
	POP AR1
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE PEGA OS DADOS DA MEMÓRIA DE UM INIMIGO E MATA ELE ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;LIMPA DUAS COLUNAS E ESCREVE NOVAMENTE OS INIMIGOS TODOS, NOS LUGARES ONDE A MEMÓRIA APONTA ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; A PRIMEIRA LINHA A LIMPAR DEVE SER INDICADA POR A ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_TODOS_OS_INIMIGOS_VIVOS:
	PUSH AR1
	PUSH AR2
	PUSH AR3
	CALL LIMPA_DUAS_LINHAS
	MOV DPTR, #INIMIGOS
	CLR A
	MOV R2, A  ;; SALVA EM QUAL INIMIGO ESTAMOS
	MOV R1, #8D	  ;;SÃO NO MÁXIMO 8 INIMIGOS PARA MOVER

MOVE:

	MOVC  A, @A+DPTR ;;MOVE X DE UM  INIMIGO PARA O A
	JZ PROXIMO
	;;;; SE O INIMIGO NÃO ESTA MORTO
	CALL TRADUZ_X ;;A FICA COM O X CORRETO
	MOV B,A	  ;; SALVA O X NO B
	MOV A, R2
	INC A	  
	MOVC A, @A+DPTR ;;A TEM O Y AGORA
	MOV R3, A
	MOV A, B ;; A FICA COM O X
	MOV B, R3 ;; B FICA COM O Y
	CALL DESENHA_INIMIGO

	
PROXIMO:
	 INC R2
	 INC R2
	 MOV A, R2 	   ;; APONTA PARA O PRÓXIMO INIMIGO

	 DJNZ R1, MOVE 
	 POP AR3
	 POP AR2
	 POP AR1
	 RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE MOVE TODOS OS INIMIGOS VIVOS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; escreve GAME OVER NA TELA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GAME_OVER:
PRIMEIRA_LINHA_ESQ:
		CLR SELECT
		MOV A, #40H
		ADD A, #43D ;DEFINE ONDE COMEÇA A ESCREVER
	   	CALL ESCREVE_COMANDO_LCD
		MOV A, #0B8H		   ;COMANDO PÁGINAS
		ADD A, #03H		;COLOCA NO LUGAR CERTO
		CALL ESCREVE_COMANDO_LCD
   ;;ESCREVE
		 MOV A, #3EH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #41H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #49H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #49H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #79H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #79H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #38H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #0H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7EH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #21H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #21H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
		  MOV A, #7EH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #0H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #1H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
PRIMEIRA_LINHA_DIR:
		SETB SELECT
		MOV A, #40H
	   	CALL ESCREVE_COMANDO_LCD
		MOV A, #0B8H		   ;COMANDO PÁGINAS
		ADD A, #03H		;COLOCA NO LUGAR CERTO
		CALL ESCREVE_COMANDO_LCD
		; ESCREVE

		MOV A, #7EH
		CALL ESCREVE_DADO_LCD
		MOV A, #7FH
		CALL ESCREVE_DADO_LCD
		MOV A, #1H
		CALL ESCREVE_DADO_LCD
		MOV A, #7FH
		CALL ESCREVE_DADO_LCD
		MOV A, #7FH 
		CALL ESCREVE_DADO_LCD
		MOV A, #0H
		CALL ESCREVE_DADO_LCD
		CALL ESCREVE_E
SEGUNDA_LINHA_ESQ:
		CLR SELECT
		MOV A, #40H
		ADD A, #43D ;DEFINE ONDE COMEÇA A ESCREVER
	   	CALL ESCREVE_COMANDO_LCD
		MOV A, #0B8H		   ;COMANDO PÁGINAS
		ADD A, #04H		;COLOCA NO LUGAR CERTO
		CALL ESCREVE_COMANDO_LCD
   ;;ESCREVE
		 MOV A, #3EH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD 
		 MOV A, #41H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #41H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #41H
		 CALL ESCREVE_DADO_LCD
		  MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD 
		 MOV A, #3EH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #0H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #1FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #3FH
		 CALL ESCREVE_DADO_LCD
		  MOV A, #3FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #60H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #40H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #60H
		 CALL ESCREVE_DADO_LCD
		 MOV A, #3FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #3FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #1FH
		 CALL ESCREVE_DADO_LCD
		 MOV A, #0H
		 CALL ESCREVE_DADO_LCD 
		 MOV A, #7FH
		 CALL ESCREVE_DADO_LCD
SEGUNDA_LINHA_DIR:
		SETB SELECT
		MOV A, #40H
		CALL ESCREVE_COMANDO_LCD
		MOV A, #0B8H		   ;COMANDO PÁGINAS
		ADD A, #04H		;COLOCA NO LUGAR CERTO
		CALL ESCREVE_COMANDO_LCD
   ;;ESCREVE
		CALL ESCREVE_E
		MOV A, #0H
		CALL ESCREVE_DADO_LCD
		MOV A, #7FH
		CALL ESCREVE_DADO_LCD
		MOV A, #7FH
		CALL ESCREVE_DADO_LCD
		MOV A, #9H
		CALL ESCREVE_DADO_LCD
		MOV A, #9H
		CALL ESCREVE_DADO_LCD
		MOV A, #7FH
		CALL ESCREVE_DADO_LCD
		MOV A, #7FH
		CALL ESCREVE_DADO_LCD
		MOV A, #76H
		CALL ESCREVE_DADO_LCD
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE ESCREVE O GAME OVER ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;; FUNÇAO AUXILIAR PARA ESCREVER O E
ESCREVE_E:
		MOV A, #7FH
		CALL ESCREVE_DADO_LCD
		MOV A, #7FH
		CALL ESCREVE_DADO_LCD
		MOV A, #49H
		CALL ESCREVE_DADO_LCD
		MOV A, #49H
		CALL ESCREVE_DADO_LCD
		MOV A, #49H
		CALL ESCREVE_DADO_LCD
		MOV A, #49H
		CALL ESCREVE_DADO_LCD
		MOV A, #49H
		CALL ESCREVE_DADO_LCD
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; RECEBE A POSIÇÃO X DA NAVE EM A, DESENHA A MORTE, E DEPOIS DE UM TEMPO APAGA ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESENHA_MORTE_NAVE:
			PUSH AR1
			PUSH AR2
			MOV R1, A
		 	MOV B, A			;INICIALIZA B COM A COLUNA INICIAL
			  ADD A, #40H		   ;DEFINE A POSIÇÃO x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO PÁGINAS
			  ADD A, #07H		;COLOCA NA PARTE DE BAIXO DA TELA  
			  CALL ESCREVE_COMANDO_LCD
			 	;DESENHAR O BIXINHO	MORTO
				
			  MOV A, #49H
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #2AH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #1CH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #00H
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #077H
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #00H
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #01CH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			   MOV A, #2AH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			   MOV A, #49H
			  CALL ESCREVE_DADO_LCD
			   
			   ;;; LIMPA A NAVE DEPOIS DE UM TEMPO
			  MOV R2, #0FH
			  DJNZ R2, $
			  MOV A, R1
			  CALL LIMPA_NAVE
			  POP AR2
			  POP AR1
			  RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE DESENHA A MORTE DA NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;LIMPA DUAS LINHAS DA TELA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; A PRIMEIRA LINHA A LIMPAR DEVE SER INDICADA POR A ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LIMPA_DUAS_LINHAS:
			  PUSH AR1
			  PUSH AR2
			  MOV R1, A ;;SALVA A PRIMEIRA LINHA A LIMPAR
			  CLR SELECT
			  MOV B, #2D
DENOVO:
			  ADD A, #0B8H		   ;COMANDO PÁGINAS
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #40H		   ;PRIMEIRA COLUNA
			  CALL ESCREVE_COMANDO_LCD
			  MOV R2, #64D
			  
LIMPA_1:
			   MOV A, #00H
			   CALL ESCREVE_DADO_LCD
			   DJNZ R2, LIMPA_1
			   	;;LIMPA O LADO DIREITO DA COLUNA
				SETB SELECT
				ADD A, #0B8H		   ;COMANDO PÁGINAS
				CALL ESCREVE_COMANDO_LCD
				MOV A, #40H		   ;PRIMEIRA COLUNA
				CALL ESCREVE_COMANDO_LCD
				MOV R2, #64D
				  
LIMPA_2:
				MOV A, #00H
				CALL ESCREVE_DADO_LCD
				DJNZ R2, LIMPA_2

				MOV A, R1 ;; RECUPERA A PRIMEIRA LINHA A LIMPAR
				INC A ;; VAI PARA A SEGUNDA

			DJNZ B, DENOVO	;;LIMPA OS DOIS LADOS DA SEGUNDA COLUNA
			POP AR2
			POP AR1
			RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE LIMPA DUAS LINHAS DA TELA ;;;;;;;;;;;;;;;;;;;;;;;;	   


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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;FUNÇÃO QUE DECIDE SE DEVE MUDAR O LADO OU NÃO. SE TEM QUE MUDAR, JÁ MUDA
;B DEVE SER INICIALIZADO COM O VALOR DA COLUNA, E DEPOIS NÃO MEXIDO MAIS

TEM_QUE_MUDAR:
		JB SELECT, NAO_MUDA
		INC B
		MOV A, B
		SUBB A, #63D
		JZ MUDA_LADO_CALL
		RET
MUDA_LADO_CALL:
		CALL MUDA_LADO
		MOV B, #0F0H  ;QUALQUER COISA
		RET
NAO_MUDA:
		RET
;; FIM DA FUNÇÃO ;;;;;;;;;;;;;;;;;;;;;;;;;
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
 LIMPA_NAVE:
				PUSH AR1
			  MOV B, A				  ;;INICIALIZA B COM A COLUNA
			 ADD A, #40H		   ;DEFINE A POSIÇÃO x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO PÁGINAS
			  ADD A, #07H		;COLOCA NO LUGAR CERTO DA TELA  
			  CALL ESCREVE_COMANDO_LCD
			 	  
			  MOV R1, #11D
LIMPA_ET:
			  MOV A, #0H
			  CALL ESCREVE_DADO_LCD
			  CALL TEM_QUE_MUDAR
			  DJNZ R1, LIMPA_ET
			  POP AR1
			  RET


;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE LIMPA A NAVE


 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DESENHA A NAVE [SPACE INVADER] COM A POSIÇÃO X DO INÍCIO DADA EM A, E NA BASE DA TELA e o select define qual o lado	
 DESENHA_NAVE:
		  	  MOV B, A			;INICIALIZA B COM A COLUNA INICIAL
			  ADD A, #40H		   ;DEFINE A POSIÇÃO x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO PÁGINAS
			  ADD A, #07H		;COLOCA NA PARTE DE BAIXO DA TELA  
			  CALL ESCREVE_COMANDO_LCD
			 	;DESENHAR O BIXINHO
				
			  MOV A, #70H
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #18H
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #7DH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #0B6H
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #0BCH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #3CH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #0BCH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			   MOV A, #0B6H
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			   MOV A, #7DH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			   MOV A, #18H
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #70H
			  CALL ESCREVE_DADO_LCD
			  RET
;;FIM DA FUNÇÃO QUE DESENHA O MOSNTRINHO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;FUNÇÃO QUE DESENHA O INIMIGO, POSIÇÃO X DADA EM A, LINHA Y DADA EM B
DESENHA_INIMIGO:
				PUSH AR1
		  	   MOV R1, A			;INICIALIZA O R1 COM A COLUNA
			  ADD A, #40H		   ;DEFINE A POSIÇÃO x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO PÁGINAS
			  ADD A, B		;COLOCA NO LUGAR CERTO DA TELA  
			  CALL ESCREVE_COMANDO_LCD
			 	;DESENHAR A NAVEZINHA DO INIMIGO
			  MOV B, R1			;;INICIALIZA B COM A COLUNA
			  MOV A, #0FH
			  CALL ESCREVE_DADO_LCD
			  CALL TEM_QUE_MUDAR
			  MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #7FH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #0FFH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #7FH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			   MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			   MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			   MOV A, #1FH
			  CALL ESCREVE_DADO_LCD
			   CALL TEM_QUE_MUDAR
			  MOV A, #0FH
			  CALL ESCREVE_DADO_LCD
			  POP AR1
			  RET
 ;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE DESENHA O UM INIMIGO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNÇÃO QUE LIMPA UM INIMIGO DA TELA
;;;;;;;;;;;;;;;;;; POSIÇÃO X EM A, COLUNA Y EM B. BIT SELECT DEFINE QUAL O LADO
LIMPA_INIMIGO:
		  	  PUSH AR1
			  MOV R1, A
			 ADD A, #40H		   ;DEFINE A POSIÇÃO x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO PÁGINAS
			  ADD A, B		;COLOCA NO LUGAR CERTO DA TELA  
			  CALL ESCREVE_COMANDO_LCD
			  MOV B, R1		  ;;INICIALIZA B COM A COLUNA
			  MOV R1, #11D
LIMPA_TERRAQUEO:
			  MOV A, #0H
			  CALL ESCREVE_DADO_LCD
			  CALL TEM_QUE_MUDAR
			  DJNZ R1, LIMPA_TERRAQUEO
			  POP AR1
			  RET

;;;;;;;;;;;;;;;;;;;; FIM DA FUNÇÃO QUE LIMPA UM INIMIGO


 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 ;;;;;;;; CONTROLE DO DISPLAY ;;;;;;;;;;;;;;;;;;;;;;;

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 ; port 3 is used for data lines 
	; port 1 is used for control lines as listed below
	; P1.0 ---D/I
	; P1.1 ---R / W 
	; P1.2 ---E 
	; P1.3 ---CS1 
	; P1.4 ---CS2  

;--------------------------------------------------------------------------------
;-- Envia (escreve) comando colocado em A para o LCD,  seleciona qual parte com o bit select
;

ESCREVE_COMANDO_LCD:
	JB TODOS, LIGA_DOIS
	     jb 	Select, Cs_2	;SELECT É UM BIT QUE DEFINE SE TU ESCREVE NO CS1 E O CS2
		clr	LCD_C2
  		setb 	LCD_C1             ;Chip select cs1 enabled 
 		jmp 	ESCREVE_INST
Cs_2:    clr	LCD_C1
		setb 	LCD_C2               ;Chip select cs2 enabled 
		JMP ESCREVE_INST
LIGA_DOIS:
		SETB LCD_C1
		SETB LCD_C2
ESCREVE_INST:		
		nop
		PUSH AR0
		mov	r0,  #0FFH
		djnz	r0, $   ;GERA ATRASO
		POP AR0
		clr 	LCD_RW              ;Write mode selected
  		clr 	LCD_DI              ;Instruction mode selected
 		mov 	LCD_DATA, a            ;Place Instruction on bus
  		setb 	LCD_E               ;Enable High
  		nop
  		clr 	LCD_E               ;Enable Low
  		nop
  		clr 	LCD_C1              ;put cs1 in non select mode
  		clr 	LCD_C2               ;put cs2 in non select mode
  		ret

	
;--------------------------------------------------------------------------------
;-- Envia (escreve) dado colocado em A para o LCD , seleciona qual parte com o bit select
;
ESCREVE_DADO_LCD:
	JB TODOS, LIGA_DOIS_A
  	jb 	Select,Cs_2a   		;VER SE QUER ESCREVER NO CS1 OU NO CS2
	clr	LCD_C2
	setb 	LCD_C1              ;Chip select cs1 enabled 
	jmp 	ESCR_DADO
Cs_2a:    		
	clr		LCD_C2
	setb 	LCD_C2              ;Chip select cs2 enabled 
	JMP ESCR_DADO
LIGA_DOIS_A:
	SETB LCD_C1
	SETB LCD_C2

ESCR_DADO:		
	nop
	PUSH AR0
	mov	r0,  #0FFH
	djnz	r0, $	   ;CRIA UM ATRASO
	POP AR0
	clr  	LCD_RW               ;Write mode selected
	setb 	LCD_DI               ;Data mode selected
	mov 	LCD_DATA,A               ;Place data on bus
	setb 	LCD_E              ;Enable High
	nop
	clr 	LCD_E               ;Enable Low
	nop
	clr  	LCD_C1               ;put cs1 in non select mode
	clr  	LCD_C2               ;put cs2 in non select mode
   		ret
;--------------------------------------------------------------------------------
;-- Inicializa o Display: Envia comandos para configurar LCD
;
INICIO_LCD:  
	SETB TODOS  
	mov 	a, #3eh            ; Display off 
        call 	ESCREVE_COMANDO_LCD  
		PUSH AR7              
  		CALL DELAY			   ;GERA ATRASO
		SETB TODOS 
  		mov 	a,  #3fh          ; Display on
  		call 	ESCREVE_COMANDO_LCD               
  		CALL DELAY
  		CALL CLEAR_DISPLAY
             
  		mov 	a, #40h            ; Y address counter at First column
  		call 	ESCREVE_COMANDO_LCD                
  		mov 	a,  #0b8h          ; X address counter at Starting point
  		call 	ESCREVE_COMANDO_LCD 
		POP AR7               
        ret

CLEAR_DISPLAY:
	PUSH AR7
	PUSH AR1
	  MOV R7, #07D
DENOVO_CLEAR:
	
	MOV	a,  #0b8h          ; X address counter at Starting point
	ADD A, R7
  	call 	ESCREVE_COMANDO_LCD
	MOV R1, #064D
	mov 	a, #40h            ; Y address counter at First column
  	call 	ESCREVE_COMANDO_LCD                
COLUNA1:
	MOV A, #00H
	CALL ESCREVE_DADO_LCD
	DJNZ R1, COLUNA1
	
  DJNZ R7, DENOVO_CLEAR
POP AR1
POP AR7
   RET

DELAY:
	PUSH AR0
	PUSH AR1

	mov	r0, #0ffh
ONE_MORE_TIME:
 	mov r1, #0ffh
	djnz r1, $
	djnz r0, one_more_time
	
	POP AR1
	POP AR0
	ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;; DADOS NA MEMÓRIA;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIMIGOS:;X,Y[lcd page]
	DB 	96D, 0D			   ;INIMIGO 0
	DB	75D, 0D			   ;INIMIGO 1
	DB	54D, 0D			   ;INIMIGO 2 
	DB	31D, 0D //PRIMEIRA LINHA  ;INIMIGO 3;.... ETC
	DB 	96D, 1D
	DB	75D, 1D
	DB	54D, 1D
	DB	31D, 1D //SEGUNDA LINHA


NAVE:  ;X, Y[lcd page], VIDAS
	DB 59D, 7D, 3D

TIROS:	;X,Y, DIREÇÃO
	DB 0FFH, 0FFH, 0FFH	  ;;COMO COLOCAR VÁRIOS TIROS NESSA MATRIX DEPOIS? OU JÁ DEIXAR A MATRIX COM UM TAMANHO GRANDE?


END