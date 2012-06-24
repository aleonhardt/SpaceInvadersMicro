;DESABILITEI AS INTERRUP��ES (COLOCANDO UM CLR EA LOGO ABAIXO DO SEU SET) PARA TESTAR OS BOT�ES.
;EST�O FALTANDO AS DEFINI��ES DE NAVE_X E LINHA_LCD QUE EU COLOQUEI DE QUALQUER JEITO S� PARA PODER RODAR MEUS TESTES.
;OS BOT�ES EST�O 100%, BOTEM PARA RODAR SEM BREAKPOINT, ABRAM A P1 E CLIQUEM E DESCLIQUEM P1.0, P1.1 E P1.2 PARA VEREM O R1 MUDAR DE VALOR.  --- ARTHUR  





USING	0	;Register bank 0 is the current bank

;;;;;;;;;;;;;; PROGRAM DATA
INI_PROG  	EQU		0100H
INT_TIM0	EQU		000BH
INT_TIM1	EQU		001BH


;;;;;;;;;;; DISPLAY DATA
SELECT 		BIT		00H ;SELECIONA O LADO ESQUERDO OU DIREITO DO LCD (0/1)
TODOS 		BIT		03H	;QUANDO EST� EM UM INDICA QUE DEVE ESCREVER NOS DOIS LADOS

LCD_DATA	EQU 	P3
LCD_DI		EQU		P2.7					 ;;;;;;; COLOCAR ESSES DEFINES NOS LUGARES QUE ACESSA
LCD_RW		EQU		P2.6
LCD_E		EQU		P2.5
LCD_C1		EQU		P2.4
LCD_C2		EQU		P2.3

LINHA_LCD DATA 07FH

;;;;;;;;; LEDS
LED1		EQU		P1.0
LED2		EQU		P1.2
LED3		EQU		P1.4

;;;;;;;; MEM�RIA (30H A 7FH)
PLAYER DATA 30H
PLAYERX DATA 30H
PLAYERY DATA 31H
PLAYERLIFE DATA 32H

GAME_OVER BIT 04H

ENEMIES DATA 33H
;TABELA DE INIMIGOS
LAST_ENEMY DATA 41H

NUMERO_INIMIGOS EQU 08D

PLAYER_SHOTS DATA 42H  ;so tem um tiro por vez
PLAYER_SHOTX		 DATA 42H
PLAYER_SHOTY		 DATA 43H

ENEMY_SHOTS DATA 44H   ;;FILA SEQUENCIAL NORMAL DOS TIROS
					;;;;;;;;;;;;; O Y DOS TIROS DEVE TER  O FORMATO 0001 0LIN[BAIXO] OU 0000 0LIN [CIMA]
					;; OU SEJA, CADA TIRO INDICA SE EST� NA PARTE DE CIMA OU DE BAIXO DA LINHA, E QUAL LINHA

MARCA_PARADA_TIROS EQU 0F5H


;;;;;; flags de movimenta��o dos inimigos na mem�ria
DIRECAO_INIMIGOS BIT 05H   ;;; ESQUERDA 1, DIREITA 0
MUDOU_DIRECAO BIT 06H

MAIOR_X			DATA	60H	
MENOR_X			DATA	61H
PRIMEIRA_LINHA_LIMPAR 	DATA	62H

DESLOCAMENTO_INIMIGO EQU 10D

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




ORG 0000H			; Vetor RESET
   	LJMP 	INICIO			; Pula para o inicio do programa principal
ORG INT_TIM0
	JMP TRATA_TIM0 ;ATUALIZA A TELA A CADA 0.1 SEGUNDOS. A CADA Y VEZES QUE ATUALIZOU A TELA FAZ COISAS COMO ANDAR OS INIMIGOS E OS TIROS. 
				 ;SEMPRE QUE ATUALIZA A TELA ANDA A NAVE OU ATIRA

ORG INI_PROG
INICIO:
    ;;SETANDO O TIMER
	;SETB EA
	;SETB ET0
	;MOV TMOD, #02H
	;MOV TH0, #09BH ;100 VEZES
	;MOV TL0,  #09BH
	;MOV R7, #0H
	;SETB TR0
	;;TIMER SETADO

	;CLR GAME_OVER



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AGORA O BIXO VAI PEGAR:

	STARTINGX EQU 64D ; max = 116
	STARTINGY EQU 7D
	MOV PLAYERX, #STARTINGX
	MOV PLAYERY, #STARTINGY
	
	CALL INICIALIZA_DADOS_JOGO
	CALL IMPRIME_TELA_INICIAL
	
	SHOT_NULL EQU 0FFH
	MOV PLAYER_SHOTX, #SHOT_NULL
	MOV PLAYER_SHOTY, #SHOT_NULL
		



	MOV BUTTONS, #0FFH

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;FUN��ES DO LCD A SEREM USADAS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IMPRIME_TELA_INICIAL - INIMIGOS E NAVE DEVEM ESTAR INICIALIZADOS
;MOVE_NAVE - POSICAO ANTIGA DA NAVE EM A
;MATA_NAVE  - VAI ESCREVER A NAVE DENOVO EM STARTINGX E ATUALIZAR A MEM�RIA
;MATA_UM_INIMIGO - N�MERO DO INIMIGO [INDEX NO VETOR] INDICADO POR A, S� DEPOIS COLOCAR FFH NA MEM�RIA
;MOVE_TODOS_OS_INIMIGOS_VIVOS - A FUN��O DE MOVER OS INIMIGOS NA MEM�RIA DEVE SER CHAMADA ANTES [�BVIO]
;ESCREVE_GAME_OVER - S� CHAMAR, LIMPAR TODA A TELA E ESCREVER OU S� ESCREVER???
		  
	;POOOOOOOOOOOOOOLING:
;LEFT_B  	    EQU 11111101B  ;PX.1 LEFT
RIGHT_B         EQU 11111011B  ;PX.2 RIGHT
FIRE_B          EQU 11111110B  ;PX.0 FIRE
BUTTONS         EQU P2
BUTTONS_PRESSED EQU 11111111B
FILTER_ALL		EQU	11111000B
FILTER_MOV		EQU 11111001B
RIGHT_LIMIT 	EQU 117D

	CHECK_FIRE:
	MOV A, BUTTONS
	ORL A, #FILTER_ALL
	MOV R0, A
	XRL A, #BUTTONS_PRESSED
	JZ CHECK_FIRE
	
	CALL DEBOUNCE
;descobre qual o bot�o foi apertado, fire tem precendencia m�xima
	MOV A, R0
	ORL A, #FIRE_B
	XRL A, #FIRE_B
	JZ PLAYER_SHOOTING
;se RIGHT e LEFT estiverem apertados, n�o se move	
	MOV A, R0
	XRL A, #FILTER_MOV
	JZ CHECK_FIRE
	
	MOV A, R0
	XRL A, #RIGHT_B
	JZ PLAYER_MOV_RIGHT
	JNZ PLAYER_MOV_LEFT
	JMP CHECK_FIRE

;fun��o de debounce
	DEBOUNCE:
	MOV R6, #50D
	DEBOUNCING:
	MOV R7, #50D
	DJNZ R7, $
	DJNZ R6, DEBOUNCING
	RET 
;;;;;;;;;;;;;;;;;;;
	
	PLAYER_SHOOTING:
	MOV A, PLAYER_SHOTX
	XRL A, #SHOT_NULL
	JNZ CHECK_FIRE
	
	MOV A, PLAYERX
	ADD A, #5D
	MOV PLAYER_SHOTX, A
	
	MOV A, PLAYERY
	CLR C
	SUBB A, #1D
	SETB C
	CALL CONVERTE_Y_TIRO
	MOV PLAYER_SHOTY, A
	
	JMP CHECK_FIRE
	
	PLAYER_MOV_RIGHT:
	MOV R1, PLAYERX
	MOV A, R1
	XRL A, #RIGHT_LIMIT
	JZ CHECK_FIRE
	MOV A, R1
	INC R1
	MOV PLAYERX, R1
	CALL MOVE_NAVE
	JMP CHECK_FIRE
	
	PLAYER_MOV_LEFT:
	MOV R1, PLAYERX
	MOV A, R1
	JZ CHECK_FIRE
	MOV A, R1
	DEC R1
	MOV PLAYERX, R1
	CALL MOVE_NAVE
	JMP CHECK_FIRE
	
	
	JMP $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN_LOOP:
	 MOV R7, #0H

;;;BLABLABLA
	 RETI
;;;;;;;;;;;;;;;;;;;FIM DO MAIN LOOP



;;; FUN��O QUE TRATA O TIMER 0
;QUANDO ELE CONTAR 100 VEZES, CHAMA O MAIN LOOP, QUE � O TEMPO CERTO DE ATUALIZA��O
TRATA_TIM0:
 	INC R7
	MOV A, R7
	SUBB A, #0100D
	JC VOLTA_TIM0
	JZ MAIN_LOOP
VOLTA_TIM0:
	RETI




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; FUN��O QUE INICIALIZA OS DADOS NECESS�RIOS PARA O JOGO;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INICIALIZA_DADOS_JOGO:
	CLR LED1
	CLR LED2
	CLR LED3 ;;DEFINE AS 3 VIDAS DO BIXINHO
	CLR GAME_OVER
	MOV PLAYERX, #STARTINGX
	MOV PLAYERY, #STARTINGY
	 
	CALL INICIALIZA_INIMIGOS
	
;	SHOT_NULL EQU 0FFH
	MOV PLAYER_SHOTX, #SHOT_NULL
	MOV PLAYER_SHOTY, #SHOT_NULL

	MOV ENEMY_SHOTS, #MARCA_PARADA_TIROS 

	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O DE INICIALIZA��O ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;; FUN��O QUE TRADUZ O Y, DADO EM A, NO FORMATO 0001 0LIN[BAIXO] OU 0000 0LIN [CIMA]
;;;;;;;;;;;;;;;;;;;;;;E COLOCA EM A A LINHA E SETA/CLR O BIT TIRO_METADE_BAIXO ;;;;;;;;;;;;;;;;;;;;;;;
TRADUZ_Y_TIRO:
	PUSH AR1
	MOV R1, A ;;SALVA O VALOR
	ANL A, #00010000B ;;FILTRO PARA O BIT BAIXO/CIMA
	JNZ BIT_BAIXO
BIT_CIMA:
	CLR TIRO_METADE_BAIXO

TRADUZ_LINHA:
	MOV A, R1
	ANL A, #00000111B ;;FILTRO PARA OS BITS QUE DEFINEM A LINHA
	;;A EST� AGORA COM O Y CERTO
	POP AR1
	RET

BIT_BAIXO:
	SETB TIRO_METADE_BAIXO
	JMP TRADUZ_LINHA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; FIM DA FUN��O QUE TRADUZ O Y DOS TIROS ;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; FUNCAO QUE CONVERTE UMA LINHA E UM BIT PARA O FORMATO DO Y LISTA DE TIROS ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;LINHA DADA EM A E BIT EMBAIXO DADO EM C. RETORNO EM A;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CONVERTE_Y_TIRO:
	JC ADICIONA_BIT_EMBAIXO
	RET		;; SE O BIT N�O EST� LIGADO, ENT�O N�O MUDA NADA E RETORNA O A IGUAL
ADICIONA_BIT_EMBAIXO:
	 ADD A, #016D ;;SETA O BIT CERTO, DEIXA O RESTO INTACTO
	 RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; FIM DA FUN��O QUE CONVERTE O Y DOS TIROS ;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE MOVE OS TIROS E DEPOIS ATUALIZA O LCD ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_TIROS:
	CALL MOVE_TIROS_INIMIGOS
	CALL MOVE_TIROS_NAVE
	CALL MOVE_TIROS_LCD
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUNCAO QUE MOVE OS TIROS ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; FUNCAO QUE MOVE O TIRO DA NAVE, SE HOUVER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_TIROS_NAVE:
	MOV A, PLAYER_SHOTX
	XRL A, #SHOT_NULL
	JZ SEM_TIRO_NAVE
;;CASO TENHA UM TIRO DA NAVE
	MOV A, PLAYER_SHOTY ;;S� MUDA O Y N�
	CALL TRADUZ_Y_TIRO	 ;;LINHA EM A E ESTADO EM TIRO_METADE_BAIXO
	JB TIRO_METADE_BAIXO, MANTEM_LINHA_TIRO
	;;;;;;;;;; SE O TIRO ESTA NA METADE DE CIMA, TEM QUE MUDAR A LINHA E O ESTADO
	DEC A ;;A ESTA COM A LINHA
	SETB TIRO_METADE_BAIXO ;;COLOCA O TIRO NA METADE DE BAIXO DA PROXIMA LINHA
	MOV C, TIRO_METADE_BAIXO
   	CALL CONVERTE_Y_TIRO ;;A EST� COM A LINHA
	;; A FICA COM O Y NO FORMATO CERTO
	MOV PLAYER_SHOTY, A
	RET

MANTEM_LINHA_TIRO:	;; SO MUDA O TIRO DA METADE DE BAIXO PARA A METADE DE CIMA
	CLR TIRO_METADE_BAIXO
	MOV C, TIRO_METADE_BAIXO
	CALL CONVERTE_Y_TIRO ;;A FICA COM O Y NO FORMATO CERTO
	MOV PLAYER_SHOTY, A
	RET

SEM_TIRO_NAVE:
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE O TIRO DA NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUNCAO QUE MOVE OS TIROS DOS INIMIGOS, NA MEM�RIA ;;;;;;;;;;;;
MOVE_TIROS_INIMIGOS:
	PUSH AR0
	MOV R0, #ENEMY_SHOTS
	CJNE @R0, #MARCA_PARADA_TIROS, MOVE_PROXIMO_TIRO
;NENHUM_TIRO:	;CASO NAO TENHA NENHUM TIRO AINDA	
	POP AR0	   
	RET

MOVE_PROXIMO_TIRO:
	 ; X DO TIRO.. CONTINUA O MESMO
	INC R0
	MOV A, @R0 ;;Y DO TIRO QUE DEVE MOVER
	CALL TRADUZ_Y_TIRO ;; COLOCA A LINHA EM A E O ESTADO EM TIRO_METADE_BAIXO
	JB TIRO_METADE_BAIXO, TROCA_LINHA_TIRO
;; SE O TIRO DO INIMIGO AINDA ESTA NA METADE DE CIMA, N�O PRECISA TROCAR A LINHA, S� MUDAR PARA A METADE DE BAIXO.
	SETB TIRO_METADE_BAIXO
	MOV C, TIRO_METADE_BAIXO
	CALL CONVERTE_Y_TIRO ;;A J� EST� COM A LINHA
	;; A FICA COM O Y NO FORMATO CERTO
	MOV @R0, A

 APONTA_PROXIMO_TIRO:
	INC R0 ;;APONTA PARA O X DO PROXIMO TIRO
	CJNE @R0, #MARCA_PARADA_TIROS, MOVE_PROXIMO_TIRO
	
	POP AR0
	RET

TROCA_LINHA_TIRO:		;;TEM QUE COLOCAR NA METADE DE CIMA DA PROXIMA LINHA
	INC A		;PROXIMA LINHA
	CLR TIRO_METADE_BAIXO	;COLOCA NA METADE DE CIMA
	MOV C, TIRO_METADE_BAIXO
	CALL CONVERTE_Y_TIRO
		;; A FICA COM O Y NO FORMATO CERTO
	MOV	@R0, A
	JMP APONTA_PROXIMO_TIRO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE OS TIROS DOS INIMIGOS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;	  fun��o que decide se o inimigo vai atirar, e chama a fun��o de atirar ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;SO � CHAMADA DEPOIS DE MOVER OS INIMIGOS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIMIGO_ATIRAR:
	PUSH AR0


	;MOV R0, #ENEMIES
	;MOV A, PLAYERX
	CALL ENCONTRA_INIMIGO_MESMO_X	;;O A ESTAR� APONTANDO PARA O INIMIGO COM O MESMO X DA NAVE. SE N�O TEM NENHUM, A=0
	JZ NAO_ATIRA
	
ATIRA:								  ;;CASO HAJA UM INIMIGO COM O MESMO X DA NAVE
		PUSH AR1					  
	   MOV R0, A				;; FAZ O R0 APONTAR PARA O INIMIGO CERTO
	   ADD A, #08D				;; SER� QUE O INIMIGO DA FRENTE EXISTE?
	   MOV R1, A
	   MOV A, @R1
	   MOV R1, A
		MOV A, #0FFH ;;J� ESTA MORTO
		XRL A, R1
		JZ DISPARA_TIRO_DE_TRAS

DISPARA_TIRO_DA_FRENTE:
	  	MOV A, @R1	;R1 EST� APONTANDO PARA O x DO INIMIGO DA FRENTE
		ADD A, #5D	;;PARTE DO MEIO DO INIMIGO
		SETB C		;; DA PARTE DE CIMA DA LINHA
		INC R1		;;APONTA PARA O Y DO INIMIGO
		MOV B, @R1 	; B FICA COM O Y CERTO
		CALL ADICIONA_TIRO_INIMIGO
		
		POP AR1	   ;; JA ATIROU, VOLTA
		POP AR0
		RET

DISPARA_TIRO_DE_TRAS:
		MOV A, @R0		;;R0 AINDA EST� APONTANDO PARA O X DO INIMIGO DE TRAS
		ADD A, #5D	;;PARTE DO MEIO DO INIMIGO
		SETB C		;; DA PARTE DE CIMA DA LINHA
		INC R0		;;APONTA PARA O Y DO INIMIGO
		MOV B, @R0 	; B FICA COM O Y CERTO
		CALL ADICIONA_TIRO_INIMIGO	
		
		POP AR1		;JA ATIROU, VOLTA
		POP AR0
		RET	
	  
NAO_ATIRA:
		POP AR0	
		RET

;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE FAZ O INIMIGO ATIRAR QUANDO APROPRIADO;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE DESCOBRE SE TEM ALGUM INIMIGO PASSANDO POR CIMA DA NAVE ;;;;;;;
;;;;;;;;;;;;;;;;;;;;; SE TIVER, COLOCA O ENDERE�O DELE NO A, SE N�O, A=0 ;;;;;;;;;;;;; ;;;;;;;;;

ENCONTRA_INIMIGO_MESMO_X:
	PUSH AR0
	PUSH AR1
	PUSH AR2

	MOV R0, #ENEMIES
	MOV B, PLAYERX
	MOV R1, #NUMERO_INIMIGOS

PROXIMO_INIMIGO_MESMO_X:
	 MOV A, @R0
	MOV R2, A
	MOV A, #0FFH ;;J� ESTA MORTO
	XRL A, R2
	JZ COMPARA_X_PROXIMO_INIMIGO
	
	CALL ESTA_NA_MIRA				 ;; SE N�O EST� MORTO, SER� QUE EST� SOBRE A NAVE??
	JZ ESTA_SOBRE_NAVE								;; A=0 SE EST� SOBRE A NAVE
											 ;; SE N�O, OLHA O PR�XIMO
COMPARA_X_PROXIMO_INIMIGO:
	INC R0
	INC R0 		 ;;APONTA PARA O PROXIMO X
	DJNZ R1, PROXIMO_INIMIGO_MESMO_X

	MOV A,#00H ;;NENHUM INIMIGO EST� SOBRE A NAVE :( 
	POP AR2
	POP AR1
	POP AR0
	RET

ESTA_SOBRE_NAVE:
	MOV A, @R0 ;;X DO INIMIGO QUE EST� SOBRE A NAVE
	POP AR2
	POP AR1
	POP AR0
	RET			   ;JA ACHOU, PODE SER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; FIM DA FUN��O V� SE ALGUM INIMIGO EST� SOBRE A NAVE ;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; FUN��O QUE DEFINE SE O INIMIGO COM X NO A EST� SOBRE ALGUM PONTO DA NAVE;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;DEVOLVE A=0H SE ESTIVER NA MIRA E A=FFH SE NAO ESTIVER ;;;;;;;;;;;;;;;;;;
ESTA_NA_MIRA:
	PUSH AR0
	MOV B, PLAYERX
	MOV R0, #11D ;;OLHA POR TODOS OS PONTOS DA NAVE
	ADD A, #5D	;;SE O MEIO DO INIMIGO EST� SOBRE A NAVE
PROXIMA_POSICAO_NAVE:
	XRL A, B	 ;;SE A POSI��O DA NAVE E A DO CANHAO � IGUAL, TA NA MIRA
	JZ NA_MIRA
	INC B
	DJNZ R0, PROXIMA_POSICAO_NAVE ;;SE NAO TENTA NA PROXIMA POSICAO DA NAVE
NAO_ESTA_NA_MIRA:
	  MOV A, #0FFH
	  POP AR0
	  RET
NA_MIRA:
	MOV A, #00H
	POP AR0
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; FIM DA FUN��O QUE DEFINE SE O INIMIGO ESTA SOBRE A NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	  


ADICIONA_TIRO_POSICAO BIT 09H
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; ADICIONA UM TIRO NA PILHA DE ENEMY_SHOTS ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;X EM A, Y EM B E TIRO_EMBAIXO EM C ;;;;;;;;;;;;;;;;;;;;;;;
ADICIONA_TIRO_INIMIGO:
	 PUSH AR0
	 PUSH AR1
	 MOV R1, A				   ;R1 SALVA X
	 MOV ADICIONA_TIRO_POSICAO, C  ;SALVA O BIT DO ESTADO L�
	 MOV R0, #ENEMY_SHOTS
	 CALL PERCORRE_LISTA_TIROS_ATE_PARADA
	 ;; R0 AGORA EST� NA MARCA DE PARADA
	 MOV A, R1
	 MOV @R0, A ;;COLOCA O X NO FIM DA FILA
	 INC R0		;;R0 APONTA PARA O Y
	 MOV C, ADICIONA_TIRO_POSICAO
	 MOV A, B
	 CALL CONVERTE_Y_TIRO
	 MOV @R0, A ;;COLOCA O Y CONVERTIDO NO LUGAR CERTO
	 INC R0
	 MOV @R0, #MARCA_PARADA_TIROS
	

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;; PERCORRE QUALQUER LISTA DE TIROS AT� A PARADA ;;;;;;;;;;;;;;;;;;
 ;;POSI��O INICIAL DADA EM R0, PODE SER QUALQUER UMA DELAS. DEVOLVE R0 COM A POSI��O DE PARADA
PERCORRE_LISTA_TIROS_ATE_PARADA: 
	
	MOV A, @R0

	SUBB A, #MARCA_PARADA_TIROS
	JZ ACHEI_A_MARCA_PARADA
PERCORRE_PROXIMO_TIRO:
	INC R0
	INC R0	   ;;VAI PARA O PR�XIMO X
	MOV A, @R0
	CJNE A, #MARCA_PARADA_TIROS, PERCORRE_PROXIMO_TIRO

ACHEI_A_MARCA_PARADA:
	RET 		;R0 VAI CONTINUAR APONTANDO PARA A MARCA DE PARADA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; FIM DA FUN��O QUE PERCORRE A LISTA AT� O FINAL



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; FUN��O QUE MATA A NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; CHAMA A FUN��O DE MATAR A NAVE NO LCD E CASO ACABE AS VIDAS, D� GAME OVER ;;;;;;;;;;;;;;;;
MATA_NAVE:
	CALL MATA_NAVE_LCD
	MOV PLAYERX, #STARTINGX			;;VOLTA PARA A POSI��O INICIAL
	JB LED3, SEGUNDA_VIDA			;SE J� PERDEU UMA VIDA, OLHA A PR�XIMA
	SETB LED3						;SE N�O, APAGA AQUELA VIDA [AGORA TEM 2]
	RET
SEGUNDA_VIDA:
	JB LED2, TERCEIRA_VIDA		;;SE JA PERDEU DUAS VIDAS, OLHA A PR�XIMA
	SETB LED2					;;SE N�O, APAGA AQUELA [AGORA TEM 1]
	RET
TERCEIRA_VIDA:
	JB LED3, SEM_VIDAS			;;SE J� VERDEU 3 VIDAS, ENT�O � GAME OVER
	SETB LED1				;; SE N�O, APAGA A �LTIMA VIDA [AGORA N�O TEM MAIS VIDAS]
	RET
SEM_VIDAS:
	CALL ITS_GAME_OVER_MAN ;;SE ACABARAM TODAS AS VIDAS, � GAME OVER. CHAMA O GAME OVER
	RET	

;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MATA A NAVE;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; FUN��O CHAMADA QUANDO D� GAME OVER ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ITS_GAME_OVER_MAN:
	 CALL ESCREVE_GAME_OVER

	 JMP $ ;;CANCELA TODO O OUTRO PROCESSAMENTO, FICA AQUI PARA SEMPRE
	 RET 	;;LOL NEVER

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; FIM DA FUN��O DO GAME OVER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; FUN��O QUE MOVE OS INIMIGOS DE ACORDO ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_MEMORIA_INIMIGOS:

	 CALL DEFINE_BORDAS_X_INIMIGOS ;INICIALIZA O MAIOR_X E O MENOR_X
	JB DIRECAO_INIMIGOS, ATUALMENTE_ESQUERDA
	;JMP	ATUALMENTE_DIREITA
	
	ATUALMENTE_DIREITA:
		; PROCURA O MAIOR X
			MOV A, MAIOR_X												  ;;QUE FAZ ESSAS LINHAS MANOOO?
			ADD A, #DESLOCAMENTO_INIMIGO 
			SUBB A, #116D ; TAMANHO M�XIMO DO x MENOS TAMANHO DA NAVE = 116
			JC CONTINUA_DESLOCAMENTO

			SETB DIRECAO_INIMIGOS	  ;PASSOU DO M�XIMO DA TELA, S� ANDA UMMA LINHA PR� BAIXO E MUDA A DIRECAO
			SETB MUDOU_DIRECAO
			JMP	CONTINUA_DESLOCAMENTO
	
	ATUALMENTE_ESQUERDA:
		; PROCURA O MENOR X
			MOV A, MENOR_X
			SUBB A, #DESLOCAMENTO_INIMIGO 
			JNC CONTINUA_DESLOCAMENTO            	 ; SE BAIXOU DE ZERO ENT�O PASSOU
			CLR DIRECAO_INIMIGOS					  ;FAZ ELE IR PARA A LINHA DE BAIXO
			SETB MUDOU_DIRECAO
			
	CONTINUA_DESLOCAMENTO:
		
			JB MUDOU_DIRECAO, MUDA_LINHA 	  ;;SE TROCOU DE DIRE��O CHAMA A FUN��O QUE MUDA A LINHA
			CALL MOVE_MEMORIA_TODOS_INIMIGOS_VIVOS	   ;;SE N�O, CHAMA A FUN��O QUE MOVE OS CARAS
			JMP FIM_MOVIMENTACAO

  MUDA_LINHA:
  	CALL MUDA_LINHA_MEMORIA_TODOS_INIMIGOS_VIVOS
	JB GAME_OVER, CHAMA_GAME_OVER

	FIM_MOVIMENTACAO:
	RET
CHAMA_GAME_OVER:
	CALL ITS_GAME_OVER_MAN
	RET		;;LOL NUNCA VAI VOLTAR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE OS INIMIGOS, DE ACORDO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; INICIALIZA OS INIMIGOS COM A TABELA DE INIMIGOS LOGO ABAIXO;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INICIALIZA_INIMIGOS:
											  ; PREENCHE OS DADOS DOS INIMIGOS
	;MOV PRIMEIRA_VEZ, #01H   ; DIZ QUE JA INICIO
	PUSH AR0
	PUSH AR1

	SETB DIRECAO_INIMIGOS	  ;;INICIALIZA OS INIMIGOS ANDANDO PR� ESQUERDA
	CLR MUDOU_DIRECAO
		
	MOV A,#ENEMIES ;COMECA COM O VALOR DA X DO INIMIGO
	MOV R0, A
	MOV DPTR,#TAB_INIMIGOS
	CLR A
	MOV R1, A
	
	LOOP_INICIA_INIMIGOS:	
	MOV A, R1
	MOVC A,@A + DPTR
	MOV @R0, A
	INC R0
	INC R1
	CJNE R1, #016D,LOOP_INICIA_INIMIGOS ; S�O 8 INIMIGOS
	POP AR1
	POP AR0 
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TAB_INIMIGOS:
	;COORDENADAS Dos inimigos:
	;      X,    Y ,				   
	DB 15D, 00H   
	DB 35D, 00H
	DB	55D, 00H
	DB	 75D, 00H
	DB 15D, 02H   
	DB 35D, 02H
	DB	 55D, 02H
	DB	 75D, 02H
;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	   
;;;;;;;;;;;;;;;;;;;; FUN��O QUE MOVE OS INIMIGOS HORIZONTALMENTE NA MEM�RIA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_MEMORIA_TODOS_INIMIGOS_VIVOS:
	PUSH AR0
	PUSH AR1
	PUSH AR2
	PUSH AR5
	MOV PRIMEIRA_LINHA_LIMPAR, #0FH

	MOV R1, #NUMERO_INIMIGOS	
	MOV R0, #ENEMIES
ONE_MORE_ENEMY:	
	MOV A, @R0
	MOV R2, A
	MOV A, #0FFH ;;J� ESTA MORTO
	XRL A, R2
	JZ MOVE_PROXIMO_INIMIGO	  

	INC R0
	CALL ATUALIZA_PRIMEIRA_LINHA_LIMPAR
	DEC R0	 ;VOLTA PhARA A POSI��O ANTERIOR
	


	MOV A, R2  ;;X DO INIMIGO
	JB DIRECAO_INIMIGOS, MOVE_ESQUERDA

move_direita:	
	ADD A, #DESLOCAMENTO_INIMIGO
	MOV @R0, A					 ;;MUDA O X DO INIMIGO
	JMP MOVE_PROXIMO_INIMIGO

move_esquerda: 
		CLR C
		SUBB A, #DESLOCAMENTO_INIMIGO
		MOV @R0, A					 ;;MUDA O X DO INIMIGO

MOVE_PROXIMO_INIMIGO:
	INC R0
	INC R0 ;;VAI PARA O X DO INIMIGO SEGINTE
	DJNZ R1, ONE_MORE_ENEMY	 
	
	POP AR2
	POP AR1
	POP AR0
 RET

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE OS INIMIGOS NA MEMORIA, HORIZONTALMENTE
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; FUN�AO QUE ESCREVE QUAL A PRIMEIRA LINHA A LIMPAR, NUMA VARI�VEL	 ESPECIFICA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ATUALIZA_PRIMEIRA_LINHA_LIMPAR:		 ;;;; DEFINE QUAL A PRIMEIRA LINHA A LIMPAR	, RECEBE O R0 APONTANDO PR� Y

	MOV B, @R0 ;;Y DO INIMIGO			
	MOV A, PRIMEIRA_LINHA_LIMPAR
	SUBB A,B
	JNC	LINHA_LIMPAR

	RET
LINHA_LIMPAR:
	MOV PRIMEIRA_LINHA_LIMPAR, @R0

	RET

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;; FIM DA FUN��O QUE DEFINE QUAL A PRIMEIRA LINHA A LIMPAR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; FUN��O QUE FAZ OS INIMIGOS IREM pARA A LINHA DE BAIXO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MUDA_LINHA_MEMORIA_TODOS_INIMIGOS_VIVOS:
	PUSH AR0
	PUSH AR1
	PUSH AR2
	MOV R1, #NUMERO_INIMIGOS	
	MOV R0, #ENEMIES
	INC R0 	;APONTA PARA O Y
ONE_MORE_ENEMY_1:	
	MOV A, @R0
	MOV R2, A
	MOV A, #0FFH ;;J� ESTA MORTO
	XRL A, R2
	JZ MOVE_PROXIMO_INIMIGO	

	CALL ATUALIZA_PRIMEIRA_LINHA_LIMPAR

	MOV A, R2
	ADD A, #01H ;VAI PARA A LINHA DE BAIXO
		
	MOV @R0, A					 ;;MUDA O X DO INIMIGO
	CJNE A, #07H, MOVE_PROXIMO_INIMIGO_1	  ;CASO SEJA A LINHA 7, � GAME OVER MAN

INDICA_GAME_OVER:
		SETB GAME_OVER
		POP AR2
		POP AR1
		POP AR0
 		RET	
					;VOLTA IMEDIATAMENTE E NEM PRECISA MAIS ESCREVER, J� MATA O BIXO E DEU MANO. E DEU
MOVE_PROXIMO_INIMIGO_1:
	INC R0
	INC R0 ;;VAI PARA O y DO INIMIGO SEGINTE
	DJNZ R1, ONE_MORE_ENEMY_1	 
	
	POP AR2
	POP AR1
	POP AR0
 	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE FAZ OS INIMIGOS IREM PARA A LINHA DE BAIXO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; FUNCAO QUE DEFINE O VALOR DO INIMIGO MAIS � DIREITA E � ESQUERDA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEFINE_BORDAS_X_INIMIGOS:
	 PUSH AR0
	 PUSH AR1
	 PUSH AR2
		
	MOV MAIOR_X, #0H
	MOV MENOR_X, #0FFH

	 MOV R1, #NUMERO_INIMIGOS	
	MOV R0, #ENEMIES
ONE_MORE_ENEMY_LALA:	
	MOV A, @R0
	MOV R2, A
	MOV A, #0FFH ;;J� ESTA MORTO
	XRL A, R2
	JZ BORDA_PROXIMO_INIMIGO
	MOV A, R2
	SUBB A, MAIOR_X
	JNC ESSE_EH_MAIOR

	MOV A,MENOR_X			   ;SE NAO � O MAIOR, SER� O MENOR?
	SUBB A, R2					;SUBTRAI O X ATUAL DO MENOR_X , SE N�O DER CARRY � POR QUE O X ATUAL � MENOR
	JNC ESSE_EH_MENOR
	;;SE NAO � NADA, S� VAI PRO PR�XIMO
BORDA_PROXIMO_INIMIGO:
	INC R0
	INC R0 ;;VAI PARA O X DO INIMIGO SEGINTE
	DJNZ R1, ONE_MORE_ENEMY_LALA
VOLTA_BORDAS:	
	POP AR2
	POP AR1
	POP AR0
 	RET	 
 ESSE_EH_MAIOR:
 	MOV MAIOR_X, A
	JMP BORDA_PROXIMO_INIMIGO
ESSE_EH_MENOR:
	MOV MENOR_X, A
	JMP BORDA_PROXIMO_INIMIGO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; FIM DA FUN��O QUE DEFINE AS BORDAS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;; ESCREVE A TELA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;; IMPRIME A TELA INICIAL, COM OS INIMIGOS E A NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 IMPRIME_TELA_INICIAL:
 	PUSH AR1
	PUSH AR0
 	CALL INICIO_LCD
	CALL DELAY

	MOV A, PLAYERX	;;A FICA COM A POSI��O x DA NAVE
	CALL TRADUZ_X	;;A FICA COM A POSI��O X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL DESENHA_NAVE  ;; DESENHA A NAVE NO LUGAR DA TELA
	MOV R1, #8D	  ;;S�O 8 INIMIGOS PARA DESENHAR
	MOV R0, #ENEMIES
IMPRIME_INIMIGOS:

	MOV A, @R0
	CALL TRADUZ_X ;;A FICA COM O X CORRETO
	INC R0
	MOV B, @R0			;;Y NO B
	CALL DESENHA_INIMIGO
	CALL DELAY
	
;PROXIMO_INIMIGO:
	 INC R0		;APONTA PARA O X DO PR�XIMO INIMIGO

	 DJNZ R1, IMPRIME_INIMIGOS 
	   
	  POP AR0
	  POP AR1
	  RET
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE DESENHA A TELA INICIAL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; PEGA A POSI��O DA MEM�RIA E ESCREVE A NAVE, A POSI��O X ANTIGA DA NAVE FICA EM A
MOVE_NAVE:
   	CALL TRADUZ_X	;;A FICA COM A POSI��O X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL LIMPA_NAVE	 ;; LIMPA A NAVE DA TELA

	MOV A, PLAYERX;A FICA COM A POSI��O x DA NAVE
	CALL TRADUZ_X	;;A FICA COM A POSI��O X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL DESENHA_NAVE  ;; DESENHA A NAVE NO NOVO LUGAR DA TELA
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE PEGA OS DADOS DA MEM�RIA E DESENHA A NAVE NA TELA;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE MOVE NA TELA TODOS OS TIROS, INIMIGOS E DA NAVE ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_TIROS_LCD:
	CALL MOVE_TIROS_INIMIGOS_LCD
	CALL MOVE_TIROS_NAVE_LCD
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE TODOS OS TIROS NO LCD ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIRO_METADE_BAIXO BIT 0FH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE MOVE OS TIROS DOS INIMIGOS, BASEADO NOS DADOS DA MEM�RIA;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_TIROS_INIMIGOS_LCD:
	PUSH AR0

	MOV R0, #ENEMY_SHOTS
	CJNE @R0, #MARCA_PARADA_TIROS, PROXIMO_TIRO_INIMIGO
;NENHUM TIRO AINDA
	POP AR0
	RET

PROXIMO_TIRO_INIMIGO:	
	MOV A, @R0			;;PEGA O X
	CALL TRADUZ_X
	ADD A, #040H
	CALL ESCREVE_COMANDO_LCD   ;;COLOCA NA POSI��O X CERTA
	INC R0	;;PEGA O Y
	MOV A, @R0
	CALL TRADUZ_Y_TIRO ;;A FICA COM O Y CERTO, BIT TIRO_METADE_BAIXO FICA CORRETO
	JB TIRO_METADE_BAIXO, ESCREVE_TIRO_METADE_BAIXO
ESCREVE_TIRO_METADE_CIMA:
	CALL LIMPA_LINHA_ANT	  ;;A J� EST� COM A POSI��O Y 

	ADD A, #0B8H
	CALL ESCREVE_COMANDO_LCD  ;;COLOCA NO Y CERTO
	MOV A, #06H ;;00000110
	CALL ESCREVE_DADO_LCD
	JMP VERIFICA_HA_PROX_TIRO

ESCREVE_TIRO_METADE_BAIXO: 
	
	ADD A, #0B8H
	CALL ESCREVE_COMANDO_LCD ;;COLOCA NO Y CERTO
	MOV A, #060H ;;01100000
	CALL ESCREVE_DADO_LCD

VERIFICA_HA_PROX_TIRO:
	 INC R0 ;;APONTA PROX X ENEMY_SHOTS
	 CJNE @R0, #MARCA_PARADA_TIROS , PROXIMO_TIRO_INIMIGO ;;MARCA DE PARADA INDICA QUE N�O TEM MAIS TIROS

	 POP AR0
	 RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE OS TIROS DOS INIMIGOS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; FUN��O QUE MOVE OS TIROS DA NAVE, BASEADO NOS DADOS DA MEM�RIA;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;MUDAR ;; MUDAR ;;MUDAR
MOVE_TIROS_NAVE_LCD:
	PUSH AR0

	MOV A, PLAYER_SHOTX 	
	XRL A, #SHOT_NULL
	JZ SEM_TIRO_PLAYER

	MOV A, PLAYER_SHOTX		;PEGA O X
	CALL TRADUZ_X
	ADD A, #040H
	CALL ESCREVE_COMANDO_LCD   ;;COLOCA NA POSI��O X CERTA
	
	MOV A,PLAYER_SHOTY;;PEGA O Y
	CALL TRADUZ_Y_TIRO ;;A FICA COM O Y CERTO, BIT TIRO_METADE_BAIXO FICA CORRETO
	JB TIRO_METADE_BAIXO, ESCREVE_TIRO_METADE_BAIXO
ESCREVE_TIRO_NAVE_METADE_CIMA:

	ADD A, #0B8H
	CALL ESCREVE_COMANDO_LCD  ;;COLOCA NO Y CERTO
	MOV A, #06H ;;00000110
	CALL ESCREVE_DADO_LCD
	
	POP AR0				;; O PLAYER S� TEM UM TIRO POR VEZ NA TELA, S� ESCREVE AQUELE
	RET

ESCREVE_TIRO_NAVE_METADE_BAIXO:
	CALL LIMPA_LINHA_SEGUINTE ;; A J� EST� COM Y CERTO  
	
	ADD A, #0B8H
	CALL ESCREVE_COMANDO_LCD ;;COLOCA NO Y CERTO
	MOV A, #060H ;;01100000
	CALL ESCREVE_DADO_LCD

	 POP AR0		 ;; O PLAYER S� TEM UM TIRO POR VEZ NA TELA, S� ESCREVE AQUELE
	 RET

SEM_TIRO_PLAYER:
	POP AR0
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE OS TIROS DA NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PEGA A POSI��O DA MEM�RIA E LIMPA A NAVE. DEPOIS DE UM TEMPO ESCREVE ELA DENOVO EM STARTINGX;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MATA_NAVE_LCD:
	PUSH AR1
	MOV A, PLAYERX	;;A FICA COM A POSI��O x DA NAVE
	CALL TRADUZ_X	;;A FICA COM A POSI��O X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	MOV R1, A
	CALL LIMPA_NAVE	 ;; LIMPA A NAVE DA TELA
	MOV A, R1
	MOV R1, #0FH
	DJNZ R1, $
	CALL DESENHA_MORTE_NAVE	;DESENHA A MORTE E LIMPA DEPOIS DE UM TEMPO
	MOV PLAYERX, #STARTINGX
	MOV	 A, #STARTINGX
	CALL TRADUZ_X
	CALL DESENHA_NAVE
	POP AR1
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MATA A NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; MATA UM INIMIGO. QUAL INIMIGO � INDICADO POR A, AS POSI��ES DE MEM�RIA DEVEM SER V�LIDAS;;;;
;;;;;;;;;;;;;;;;;;;; SO DEPOIS ZERAR AS POSI��ES DE MEM�RIA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MATA_UM_INIMIGO:
	PUSH AR0
	MOV R0, #ENEMIES
	ADD A, R0
	ADD A, R0 
	MOV R0, A ;;APONTA PARA O X CERTO
	MOV A, @R0 ;;A FICA COM O X DO INIMIGO
	CALL TRADUZ_X ;;A FICA COM O X CORRETO E O BIT SELECT FICA CERTO
	INC R0
	MOV B, @R0	;;B FICA COM O Y
	CALL LIMPA_INIMIGO
	POP AR0
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE PEGA OS DADOS DA MEM�RIA DE UM INIMIGO E MATA ELE ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;LIMPA DUAS COLUNAS E ESCREVE NOVAMENTE OS INIMIGOS TODOS, NOS LUGARES ONDE A MEM�RIA APONTA ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_TODOS_OS_INIMIGOS_VIVOS:
	PUSH AR1
	PUSH AR2
	PUSH AR0
	MOV A, PRIMEIRA_LINHA_LIMPAR
	CALL LIMPA_DUAS_LINHAS
	MOV R0, #ENEMIES	;SALVA O ENDERE�O DOS INIMIGOS

	MOV R1, #NUMERO_INIMIGOS	  ;;S�O NO M�XIMO 8 INIMIGOS PARA MOVER

MOVE:

	MOV A, @R0	;MOVE O X DO INIMIGO PARA R2
	MOV R2, A
	MOV A, #0FFH
	XRL A, R2
	JZ PROXIMO
	;;;; SE O INIMIGO N�O ESTA MORTO
	MOV A, R2
	CALL TRADUZ_X ;;A FICA COM O X CORRETO
	INC R0
	MOV B, @R0 ;; B FICA COM O VALOR DE Y
	CALL DESENHA_INIMIGO
	DEC R0 ;;S� PARA FUNCIONAR OS DOIS INC ABAIXO
	
PROXIMO:
	 INC R0
	 INC R0 ;APONTA PARA O PR�XIMO INIMIGO


	 DJNZ R1, MOVE 
	 POP AR0
	 POP AR2
	 POP AR1
	 RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE TODOS OS INIMIGOS VIVOS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; escreve GAME OVER NA TELA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ESCREVE_GAME_OVER:
		CALL CLEAR_DISPLAY
PRIMEIRA_LINHA_ESQ:
		CLR SELECT
		MOV A, #40H
		ADD A, #43D ;DEFINE ONDE COME�A A ESCREVER
	   	CALL ESCREVE_COMANDO_LCD
		MOV A, #0B8H		   ;COMANDO P�GINAS
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
		MOV A, #0B8H		   ;COMANDO P�GINAS
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
		ADD A, #43D ;DEFINE ONDE COME�A A ESCREVER
	   	CALL ESCREVE_COMANDO_LCD
		MOV A, #0B8H		   ;COMANDO P�GINAS
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
		MOV A, #0B8H		   ;COMANDO P�GINAS
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE ESCREVE O GAME OVER ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;; FUN�AO AUXILIAR PARA ESCREVER O E
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DEPOIS DAQUI, N�O USAR MAIS NENHUMA FUN��O DO DISPLAY!!! ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; FUN��O QUE LIMPA A COLUNA EXATA DA LINHA ANTERIOR, PARA MOVER O TIRO
;;;;;;;;;;;;;;;;;;;;;;;; RECEBE EM A O Y CORRETO, O LCD J� EST� COM O X CERTO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LIMPA_LINHA_ANT:
	 PUSH AR1
	MOV R1, A ;;SALVA O Y  CORRETO
	DEC A
	ADD A, #0B8H
	CALL ESCREVE_COMANDO_LCD ;;COLOCA NO Y CERTO
	MOV A, #00H
	CALL ESCREVE_DADO_LCD
	MOV A, R1
	POP AR1
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE LIMPA A LINHA ANTERIOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; FUN��O QUE LIMPA A COLUNA EXATA DA LINHA SEGUINTE, PARA MOVER O TIRO
;;;;;;;;;;;;;;;;;;;;;;;; RECEBE EM A O Y CORRETO, O LCD J� EST� COM O X CERTO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LIMPA_LINHA_SEGUINTE:
	 PUSH AR1
	MOV R1, A ;;SALVA O Y  CORRETO
	INC A
	ADD A, #0B8H
	CALL ESCREVE_COMANDO_LCD ;;COLOCA NO Y CERTO
	MOV A, #00H
	CALL ESCREVE_DADO_LCD
	MOV A, R1
	POP AR1
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE LIMPA A LINHA SEGUINTE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; RECEBE A POSI��O X DA NAVE EM A, DESENHA A MORTE, E DEPOIS DE UM TEMPO APAGA ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESENHA_MORTE_NAVE:
			PUSH AR1
			PUSH AR2
			MOV R1, A
		 	MOV B, A			;INICIALIZA B COM A COLUNA INICIAL
			  ADD A, #40H		   ;DEFINE A POSI��O x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO P�GINAS
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
			  CALL DELAY
			  MOV A, R1
			  CALL LIMPA_NAVE
			  POP AR2
			  POP AR1
			  RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE DESENHA A MORTE DA NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;LIMPA DUAS LINHAS DA TELA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; A PRIMEIRA LINHA A LIMPAR DEVE SER INDICADA POR A ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LIMPA_DUAS_LINHAS:
			  PUSH AR1
			  PUSH AR2
			  MOV R1, A ;;SALVA A PRIMEIRA LINHA A LIMPAR
			  SETB TODOS ;; LIMPA OD DOIS LADOS DA TELA AO MESMO TEMPO
			  MOV B, #2D
LIMPA_OUTRA_LINHA:
			  ADD A, #0B8H		   ;COMANDO P�GINAS
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #40H		   ;PRIMEIRA COLUNA
			  CALL ESCREVE_COMANDO_LCD
			  MOV R2, #64D
			  
LIMPA_1:
			   MOV A, #00H
			   CALL ESCREVE_DADO_LCD
			   DJNZ R2, LIMPA_1	   ;;LIMPA A LINHA TODA
			   	

				MOV A, R1 ;; RECUPERA A PRIMEIRA LINHA A LIMPAR
				INC A ;; VAI PARA A SEGUNDA

			DJNZ B, LIMPA_OUTRA_LINHA	;;LIMPA OS DOIS LADOS DA SEGUNDA LINHA
			CLR TODOS
			POP AR2
			POP AR1
			RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE LIMPA DUAS LINHAS DA TELA ;;;;;;;;;;;;;;;;;;;;;;;;	   


  ; TRADUZ A POSI��O X [DADA EM A] DE 0 A 127 PARA X DE 0 A 63 E QUAL DOS LADOS DO LCD USAR
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
;;FUN��O QUE DECIDE SE DEVE MUDAR O LADO OU N�O. SE TEM QUE MUDAR, J� MUDA
;B DEVE SER INICIALIZADO COM O VALOR DA COLUNA, E DEPOIS N�O MEXIDO MAIS

TEM_QUE_MUDAR:
		JB SELECT, NAO_MUDA
		INC B
		MOV A, B
		SUBB A, #63D
		JZ MUDA_LADO_CALL
		RET
MUDA_LADO_CALL:
		MOV A, LINHA_LCD
		CALL MUDA_LADO
		MOV B, #0F0H  ;QUALQUER COISA
		RET
NAO_MUDA:
		RET
;; FIM DA FUN��O ;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;MUDA O LADO [ESQUERDO PARA O DIREITO] EM QUE EST� SENDO ESCRITO ALGO NO LCD
;A LINHA CERTA � DADA NO A

MUDA_LADO:
			SETB SELECT		;ESCREVE NO LADO DIREITO
			ADD A, #0B8H		   ;COMANDO P�GINAS
					;COLOCA NA PARTE CERTA DA TELA
			CALL ESCREVE_COMANDO_LCD
			MOV A, #40H
			CALL ESCREVE_COMANDO_LCD
			
			RET
			
;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MUDA O LADO	 NO LCD
	
 ;POSI��O X DO INICIO DADA EM A E O SELECT DEFINE QUAL LADO
 ;USA O A E O B SEM SALVAR
 LIMPA_NAVE:
				PUSH AR1
			MOV LINHA_LCD, #07H
			  MOV B, A				  ;;INICIALIZA B COM A COLUNA
			 ADD A, #40H		   ;DEFINE A POSI��O x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO P�GINAS
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


;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE LIMPA A NAVE


 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DESENHA A NAVE [SPACE INVADER] COM A POSI��O X DO IN�CIO DADA EM A, E NA BASE DA TELA e o select define qual o lado	
 DESENHA_NAVE:
			mov	LINHA_LCD, #07h
		  	  MOV B, A			;INICIALIZA B COM A COLUNA INICIAL
			  ADD A, #40H		   ;DEFINE A POSI��O x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO P�GINAS
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
;;FIM DA FUN��O QUE DESENHA O MOSNTRINHO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;FUN��O QUE DESENHA O INIMIGO, POSI��O X DADA EM A, LINHA Y DADA EM B
DESENHA_INIMIGO:
				PUSH AR1
		  	   MOV R1, A			;INICIALIZA O R1 COM A COLUNA
			  ADD A, #40H		   ;DEFINE A POSI��O x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO P�GINAS
			  ADD A, B		;COLOCA NO LUGAR CERTO DA TELA
			MOV LINHA_LCD, B  
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
 ;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE DESENHA O UM INIMIGO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE LIMPA UM INIMIGO DA TELA
;;;;;;;;;;;;;;;;;; POSI��O X EM A, COLUNA Y EM B. BIT SELECT DEFINE QUAL O LADO
LIMPA_INIMIGO:
		  	  PUSH AR1
			  MOV R1, A
			MOV LINHA_LCD, B
			 ADD A, #40H		   ;DEFINE A POSI��O x
			  CALL ESCREVE_COMANDO_LCD
			  MOV A, #0B8H		   ;COMANDO P�GINAS
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

;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE LIMPA UM INIMIGO


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
	     jb 	Select, Cs_2	;SELECT � UM BIT QUE DEFINE SE TU ESCREVE NO CS1 E O CS2
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
		CLR TODOS
		POP AR7               
        ret

CLEAR_DISPLAY:
	PUSH AR7
	PUSH AR1
	SETB TODOS
	  MOV R7, #08D
DENOVO_CLEAR:
	
	MOV	a,  #0b8h          ; X address counter at Starting point
	ADD A, R7
	DEC A
  	call 	ESCREVE_COMANDO_LCD
	MOV R1, #064D
	mov 	a, #40h            ; Y address counter at First column
  	call 	ESCREVE_COMANDO_LCD                
COLUNA1:
	MOV A, #00H
	CALL ESCREVE_DADO_LCD
	DJNZ R1, COLUNA1
	
  DJNZ R7, DENOVO_CLEAR
  CLR TODOS
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


END