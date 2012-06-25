;UNIVERSIDADE FEDERAL DO RIO GRANDE DO SUL
;8051 SPACE INVADERS
;PROJETO FINAL PARA A DISCIPLINA DE MICROCONTROLADORES ENG4056
;PROFESSOR GILSON WIRTH
;DESENVOLVEDORES: ;ALESSANDRA LEONHARDT	;ARTHUR CARVALHO RAUTER	;LUCAS SCHONS

USING	0	;Register bank 0 is the current bank

;;;;;;;;;;;;;; PROGRAM EQUATES
INI_PROG  	EQU		0100H
INT_TIM0	EQU		000BH

;;;;;;;;;;; DISPLAY DATA
SELECT 		BIT		20H ;SELECIONA O LADO ESQUERDO OU DIREITO DO LCD (0/1)
TODOS 		BIT		21H	;QUANDO EST� EM UM INDICA QUE DEVE ESCREVER NOS DOIS LADOS

LCD_DATA	EQU 	P3
LCD_DI		EQU		P2.7					 
LCD_RW		EQU		P2.6
LCD_E		EQU		P2.5
LCD_C1		EQU		P2.4
LCD_C2		EQU		P2.3

LINHA_LCD DATA 07CH

;;;;;;;;; LEDS
LED1		EQU		P1.0
LED2		EQU		P1.2
LED3		EQU		P1.4

;;;;;;;;; BITS
GAME_OVER BIT 22H
;;;;;; flags de movimenta��o dos inimigos na mem�ria
DIRECAO_INIMIGOS BIT 23H   ;;; ESQUERDA 1, DIREITA 0
MUDOU_DIRECAO BIT 24H

;;;;;;;; MEM�RIA (30H A 7FH)
PLAYER DATA 30H
PLAYERX DATA 30H
PLAYERY DATA 31H
PLAYERLIFE DATA 32H
ENEMIES DATA 33H
;TABELA DE INIMIGOS
LAST_ENEMY DATA 42H
PLAYER_SHOTS DATA 43H  ;so tem um tiro por vez
PLAYER_SHOTX DATA 43H
PLAYER_SHOTY DATA 44H
ENEMY_SHOTS DATA 45H   ;;FILA SEQUENCIAL NORMAL DOS TIROS
					;;;;;;;;;;;;; O Y DOS TIROS DEVE TER  O FORMATO 0001 0LIN[BAIXO] OU 0000 0LIN [CIMA]
					;; OU SEJA, CADA TIRO INDICA SE EST� NA PARTE DE CIMA OU DE BAIXO DA LINHA, E QUAL LINHA
TIRO_METADE_BAIXO BIT 25H
MAIOR_X	DATA 60H	
MENOR_X	DATA 61H
PRIMEIRA_LINHA_LIMPAR DATA 62H
EIGHT_TIMERS DATA 63H


;EQUATES

NUMERO_INIMIGOS EQU 08D
MARCA_PARADA_TIROS EQU 0F5H
DESLOCAMENTO_INIMIGO EQU 10D
STARTINGX EQU 64D ; max = 116
STARTINGY EQU 7D
SHOT_NULL EQU 0FFH

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




ORG 0000H			; Vetor RESET
   	LJMP 	INICIO			; Pula para o inicio do programa principal
ORG INT_TIM0
	JMP TRATA_TIM0 ;ATUALIZA A TELA A CADA 0.1 SEGUNDOS. A CADA Y VEZES QUE ATUALIZOU A TELA FAZ COISAS COMO ANDAR OS INIMIGOS E OS TIROS. 
				 ;SEMPRE QUE ATUALIZA A TELA ANDA A NAVE OU ATIRA

ORG INI_PROG
INICIO:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;AGORA O BIXO VAI PEGAR:
	CALL INICIALIZA_DADOS_JOGO
	CALL IMPRIME_TELA_INICIAL
	MOV BUTTONS, #0FFH
	;;SETANDO O TIMER0
	; 16BITS, INICIANDO DE 3.035, ESTOURANDO EM 65.353. CONTA 62.500 OITO VEZES, O QUE � IGUAL A 0,5S
	SETB EA
	SETB ET0
	MOV TMOD, #01H
	
	MSB62500 EQU 00001011B	 ;BITS MAIS SIGNIFICATIVOS DE 62500
	LSB62500 EQU 11011011B	 ;BITS MENOS SIGNIFICATIVOS DE 62500
	;MSB62500 EQU 0FFH
	;LSB62500 EQU 0FEH

	MOV TH0, #MSB62500
	MOV TL0, #LSB62500
	MOV EIGHT_TIMERS, #8D
	SETB TR0
	;;TIMER SETADO


		  
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
	CALL NAVE_ATIRA
	JMP CHECK_FIRE
	
	PLAYER_MOV_RIGHT:
	MOV R0, PLAYERX
	MOV A, R0
	XRL A, #RIGHT_LIMIT
	JZ CHECK_FIRE
	MOV A, R0
	INC R0
	MOV PLAYERX, R0
	CALL MOVE_NAVE
	JMP CHECK_FIRE
	
	PLAYER_MOV_LEFT:
	MOV R0, PLAYERX
	MOV A, R0
	JZ CHECK_FIRE
	MOV A, R0
	DEC R0
	MOV PLAYERX, R0
	CALL MOVE_NAVE
	JMP CHECK_FIRE

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; FUN��O QUE TRATA O TIMER 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; LOOP PRINCIPAL, ONDE AS COISAS ACONTECEM ;;;;;;;;;;;;;;;;;;;;;;;;;
TRATA_TIM0:
	CLR TR0
	PUSH ACC
	PUSH PSW
	PUSH AR0
	PUSH AR5
	MOV TH0, #MSB62500
	MOV TL0, #LSB62500
	;AQUI MOVE OS TIROS	

	CALL TIRO_INIMIGO_ACERTOU
	CALL TIRO_NAVE_ACERTOU_CEU
	CALL TIRO_NAVE_ACERTOU_INIMIGO
	CALL PRECISA_REINICIO 
	CALL MOVE_TIROS	

	MOV R5, EIGHT_TIMERS
	DJNZ R5, END_TF0
	;AQUI MOVE OS INIMIGOS

	CALL MOVE_INIMIGOS
	CALL INIMIGO_ATIRAR

	

	MOV R5, #8D
END_TF0:
	MOV EIGHT_TIMERS, R5
	POP AR5
	POP AR0
	POP PSW
	POP ACC
	SETB TR0	 
	RETI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; FUN��O QUE INICIALIZA OS DADOS NECESS�RIOS PARA O JOGO;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INICIALIZA_DADOS_JOGO:
	
	CLR GAME_OVER
	MOV PLAYERX, #STARTINGX
	MOV PLAYERY, #STARTINGY
	MOV PLAYERLIFE, #3H
	
	CALL ATUALIZA_LED_VIDAS 
	CALL INICIALIZA_INIMIGOS
	
;	SHOT_NULL EQU 0FFH
	MOV PLAYER_SHOTX, #SHOT_NULL
	MOV PLAYER_SHOTY, #SHOT_NULL

	MOV ENEMY_SHOTS, #MARCA_PARADA_TIROS 

	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O DE INICIALIZA��O ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



ENEMIES_ALIVE DATA 64H
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;FUNCAO DE REINICIO DOS INIMIGOS SE TODOS MORREM ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; CHAMADA QUANDO UM INIMIGO � MORTO ;;;;;;;;;;;;;;;;;;
PRECISA_REINICIO:
	
	CALL VERIFICA_QUANTIDADE_INIMIGOS_VIVOS ; ISSO COLOCA EM ENEMIES_ALIVE O VALOR DE INIMIGOS VIVOS
	MOV  A,  ENEMIES_ALIVE
	JNZ AINDA_VIVEM

	CALL INICIALIZA_INIMIGOS
	
	AINDA_VIVEM:
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; FIM DA FUN��O DE REINICIO ;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; DIZ QUANTOS INIMIGOS ESTAO VIVOS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VERIFICA_QUANTIDADE_INIMIGOS_VIVOS:	 ; EH SO CHAMAR ELA QUE DIZ QUANTOS INIMIGOS TEM VIVOS
																 ; FEITA PARA USAR COM UM COME�A DENOVO
	PUSH AR0 
	PUSH AR2


	MOV R2, #NUMERO_INIMIGOS
	MOV ENEMIES_ALIVE, #00H
    MOV R0, #ENEMIES
	 
	PROXIMA_CHECAGEM_DE_VIVOS:
	MOV A, @R0
	XRL A, #0FFH
	JZ CHECA_PROXIMO_INIMIGO	  ;;JA ESTA MORTO

	MOV A, ENEMIES_ALIVE
	INC A
	MOV ENEMIES_ALIVE, A ;;ADICIONA UM NOS VIVOS

CHECA_PROXIMO_INIMIGO:
	INC R0				 
	INC R0				 ;APONTA PARA O PROXIMO INIMIGO

	DJNZ  R2, PROXIMA_CHECAGEM_DE_VIVOS 


ACABOU_VERIFICA_QUANTIDADE_INIMIGOS_VIVOS:

	POP AR2 
	POP AR0
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE DIZ QUANTOS INIMIGOS AINDA ESTAO VIVOS;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; fun��o chamada sempre que OS TIROS SE MOVEM;;;;;;;;;;;;;
;;;;;;;;;;;;; VERIFICA SE UM INIMIGO MORREU E MATA ELE E LIMPA O TIRO ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INIMIGO_NA_MIRA BIT 26H

TIRO_NAVE_ACERTOU_INIMIGO:
	PUSH AR0 
	PUSH AR2

	MOV R0, #ENEMIES
	MOV R2, #NUMERO_INIMIGOS

	PROCURA_PROXIMO_VIVO:
	
	MOV A, @R0
	XRL A, #0FFH
	JZ CHECA_PROXIMO_INIMIGO_FOI_ACERTADO	  ;;JA ESTA MORTO

	ESTA_VIVO:
	;HORA DE VERIFICAR SE N�O TOMOU UM TIRO
	
	MOV A, @R0
	 CALL VERIFICA_TIRO_MIRANDO_INIMIGO ;FUN��O QUE PERCORRE TODO O TAMANHO DO INIMIGO DE X AT� X+11 E DIZ NO FLAG INIMIGO_NA_MIRA
	 									; SE FOI BALEADO  
	JB INIMIGO_NA_MIRA, VER_MATA_INIMIGO_ACERTADO	;;VERIFICA SE MATA O INIMIGO QUE ESTA NA MIRA DO TIRO

CHECA_PROXIMO_INIMIGO_FOI_ACERTADO:
	INC R0				 
	INC R0				 ;APONTA PARA O PROXIMO INIMIGO

	DJNZ R2, PROCURA_PROXIMO_VIVO

ACABOU_VERIFICA_MORTE_INIMIGO:
	POP AR2
	POP AR0

	RET
;;;;;;;;  AQUI A FUN��O RETORNA; ABAIXO ESTA A VERIFICA��O SE O INIMIGO REALMENTE MORRE OU N�O

VER_MATA_INIMIGO_ACERTADO:		  ;;VERIFICA SE MATA O INIMIGO QUE ESTA NA MIRA DO TIRO

	INC R0	; AGORA APONTA PARA O Y DO INIMIGO

	 MOV A, PLAYER_SHOTY
	 CALL TRADUZ_Y_TIRO		
	MOV B, A		;; B FICA COM O Y DO TIRO, TIRO_EMBAIXO_LINHA FICA COM O ESTADO
	MOV A, @R0	  ;;A TEM O Y DO INIMIGO
					;; SE O Y DO TIRO FOR UM A MAIS QUE O Y DO INIMIGO E O TIRO ESTIVER ENCIMA, 
					;; DA� O INIMIGO MORRE

	XRL A, B 	;;SE O TIRO J� ESTA NO INIMIGO
	JZ MATA_INIMIGO_FUZILADO		;;MATA O INIMIGO DIRETO	

	JB TIRO_METADE_BAIXO, ACABOU_VERIFICA_MORTE_INIMIGO	;; COMO S� TEM UM TIRO, J� SAI DIRETO
		;;TIRO EST� NA PARTE DE CIMA DA LINHA
											  
	
	MOV A, @R0		;;COLOCA DENOVO O Y DO INIMIGO
	DEC B
	XRL A, B 	;;SE S�O IGUAIS
	JNZ ACABOU_VERIFICA_MORTE_INIMIGO		;;AINDA TEM ESPA�O PARA O TIRO DA NAVE ANDAR
	
    DEC R0        ;APONTA PARA O X DA NAVE QUE FOI PEGA

MATA_INIMIGO_FUZILADO:  
   CALL MATA_INIMIGO_ANULA_TIRO ; FUN��O QUE MATA QUEM TA NO R0 E DIZ QUE TIRO DA NAVE N EXISTE MAIS
	JMP ACABOU_VERIFICA_MORTE_INIMIGO ;;; S� VAI PRO FIM  O MESMO QUE JA   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE VERIFICA SE UM INIMIGO FOI ACERTADO ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ; FUN��O QUE MATA QUEM TA NO R0 E DIZ QUE TIRO DA NAVE NAO EXISTE MAIS
MATA_INIMIGO_ANULA_TIRO: 
	   	PUSH AR0
		CALL MATA_UM_INIMIGO_LCD	
		MOV @R0, #0FFH
		INC  R0
		MOV @R0, #0FFH
		

		CALL LIMPA_TIRO_NAVE_LCD
		MOV	PLAYER_SHOTX,	  #SHOT_NULL
		MOV	PLAYER_SHOTY,	  #SHOT_NULL

		POP AR0
		RET
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MATA O INIMIGO E LIMPA O TIRO;;;;;;;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; fun��o que verifica se o inimigo apontado em R0 est� na mira do tiro da nave
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VERIFICA_TIRO_MIRANDO_INIMIGO: ; RECEBE DO R0 A POSI��O X DE UM INIMIGO
 							  ;FUN��O QUE PERCORRE TODO O TAMANHO DO INIMIGO X AT� X+11 E DIZ NO FLAG ACERTOU_TIRO_X
	 						  ; SE FOI BALEADO
	PUSH AR0 
	PUSH AR1
	PUSH AR2


 CLR INIMIGO_NA_MIRA

  MOV A,@R0	 ; COM ESSA MANOBRA CONSEGUIMOS COLOCAR NO R1 O VALOR ATUAL DE X
  MOV R1, A

  MOV R2, #11D	;;TAMANHO DA NAVE
  TESTA_PROXIMA_LARGURA_X:
  MOV A,R1
  XRL A, PLAYER_SHOTX 
  JZ INIMIGO_ESTA_NA_MIRA	   ;;SE O X DO INIMIGO � O MESMO X DO TIRO
  INC R1
  DJNZ R2, TESTA_PROXIMA_LARGURA_X	;;TESTA COM O PR�XIMO X DA NAVE

 ACABOU_VERIFICA_TIRO_X:
   	POP AR2 
	POP AR1
	POP AR0
	RET

INIMIGO_ESTA_NA_MIRA:
	SETB INIMIGO_NA_MIRA
	JMP ACABOU_VERIFICA_TIRO_X

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; fim da fun��o que verifica se o inimigo esta na mira do tiro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE FAZ A NAVE ATIRAR ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NAVE_ATIRA:
	CLR ET0
	MOV A, PLAYERX
	ADD A, #5D
	MOV PLAYER_SHOTX, A	 ;;SAI DO MEIO DA NAVE
	MOV A, PLAYERY
	CLR C
	SUBB A, #1D			;;SAI DO Y SEGUINTE � NAVE
	CLR C
	CALL CONVERTE_Y_TIRO
	MOV PLAYER_SHOTY, A
	SETB ET0
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE FAZ A NAVE ATIRAR ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE VERIFICA SE O TIRO DA NAVE CHEGOU NO TODO DA TELA ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TIRO_NAVE_ACERTOU_CEU:
	MOV A, PLAYER_SHOTX
	XRL A, #SHOT_NULL
	JZ SEM_NENHUM_TIRO_NAVE

	MOV A, PLAYER_SHOTY
 	CALL TRADUZ_Y_TIRO
	XRL A, #00H
	JZ TIRO_NO_CEU
	;;TIRO PODE ANDAR MAIS AINDA
	RET
TIRO_NO_CEU:
	JNB TIRO_METADE_BAIXO, REMOVER_TIRO_CEU
	;;TIRO PODE ANDAR MAIS AINDA
	RET
REMOVER_TIRO_CEU:
	CALL LIMPA_TIRO_NAVE_LCD
	MOV PLAYER_SHOTX, #SHOT_NULL
	MOV PLAYER_SHOTY, #SHOT_NULL
	RET
SEM_NENHUM_TIRO_NAVE:
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE ELIMINA O TIRO DA NAVE QUANDO ELE CHEGA NO TOPO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; FUN��O QUE LIMPA O TIRO DA NAVE DO LCD ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;
LIMPA_TIRO_NAVE_LCD:
	MOV A, PLAYER_SHOTX
	CALL TRADUZ_X
	ADD A, #040H
	CALL ESCREVE_COMANDO_LCD
	MOV A, PLAYER_SHOTY
	CALL TRADUZ_Y_TIRO
	ADD A, #0B8H
	CALL ESCREVE_COMANDO_LCD
	MOV A, #00H
	CALL ESCREVE_DADO_LCD
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;;;;;;;;;; FIM DA FUN��O QUE LIMPA OTIRO DA NAVE DO LCD ;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE FAZ TODA A VERIFICA��O DE COLIS�O DOS TIROS DOS INIMIGOS;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TIRO_INIMIGO_ACERTOU:
	CALL TIRO_INIMIGO_ACERTOU_NAVE
	CALL TIRO_INIMIGO_ACERTOU_CHAO
	RET

;;;;;; FIM DA FUN��O DE COLIS�O DO TIRO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE V� SE UM TIRO ACERTOU A NAVE ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SE ACERTOU, TIRA ELE DA LISTA E MATA A NAVE ;;;;;;;;
TIRO_INIMIGO_ACERTOU_NAVE:				 ;;ACERTA A NAVE NO Y=6 E ESTADO= EMBAIXO
	 	PUSH AR0
	PUSH AR1

	MOV R0, #ENEMY_SHOTS
	MOV A, @R0
	XRL A, #MARCA_PARADA_TIROS
	JZ FIM_LISTA_TIROS_INIMIGOS
	;;;;;;
	
TESTA_NAVE_PROXIMO_TIRO:
	INC R0 ;;APONTA PARA O Y  DO TIRO
	MOV A, @R0 ;;Y DO TIRO
	CALL TRADUZ_Y_TIRO	;;LINHA EM A, ESTADO EM BIT TIRO_METADE_BAIXO
	XRL A, #06H ;;TESTA SE EST� NO Y ACIMA DA NAVE	
	JZ TIRO_SOBRE_NAVE
	 ;;;; SE N�O EST� SOBRE A NAVE, VAI PARA O PR�XIMO TIRO
TIRO_SEGUINTE_COLISAO:
	INC R0 ;; APONTA PARA O X SEGUINTE
	CJNE @R0, #MARCA_PARADA_TIROS, TESTA_NAVE_PROXIMO_TIRO
FIM_LISTA_TIROS_INIMIGOS:
				;;ACABOU OS TIROS
	POP AR1
	POP AR0
	RET

TIRO_SOBRE_NAVE:
	  JNB TIRO_METADE_BAIXO, VAI_PARA_TIRO_SEGUINTE ;;AINDA PODE ANDAR MAIS UMA VEZ
						   ;;CHEGOU NA NAVE
						   
	  DEC R0
	  MOV A, @R0 ;;X DO TIRO CERTO
				;;ACERTOU A NAVE OU A TERRA???
				 ;;SE X DO TIRO - X DA NAVE< TAMANHO DA NAVE, ACERTOU A NAVE
	 CLR C
	 SUBB A, PLAYERX  ;; A AGORA TEM X DO TIRO - X DA NAVE
	 JC ACERTOU_NADA_AINDA
	 SUBB A, #12D		;;MENOS O TAMANHO DA NAVE MAIS UM, PARA DAR O CARRY CERTO
	 JC	ACERTOU_NAVE_MUERTE

ACERTOU_NADA_AINDA:
		INC R0 ;;PARA IR PARA O TIRO SEGUINTE NO LUGAR CERTO	
	  JMP VAI_PARA_TIRO_SEGUINTE

ACERTOU_NAVE_MUERTE:   
	  	MOV A, R0 ;;APONTANDO PARA O X DO TIRO CERTO
	  	CALL REMOVE_TIRO_INIMIGO_LISTA
		CALL MATA_NAVE
		DEC R0
		JMP VAI_PARA_TIRO_SEGUINTE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FUN�AO QUE V� SE UM TIRO ACERTOU O CHAO;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SE ACERTOU, TIRA ELE DA LISTA ;;;;;;;;;;;;;;;;;;;;;
TIRO_INIMIGO_ACERTOU_CHAO:
	PUSH AR0
	PUSH AR1

	MOV R0, #ENEMY_SHOTS
	MOV A, @R0
	XRL A, #MARCA_PARADA_TIROS
	JZ FIM_LISTA_TIROS
	;;;;;;
	
TESTA_CHAO_PROXIMO_TIRO:
	INC R0 ;;APONTA PARA O Y  DO TIRO
	MOV A, @R0 ;;Y DO TIRO
	CALL TRADUZ_Y_TIRO	;;LINHA EM A, ESTADO EM BIT TIRO_METADE_BAIXO
	XRL A, #07H 	
	JZ TIRO_NA_ULTIMA_LINHA
	 ;;;; SE N�O EST� NA �LTIMA LINHA, VAI PARA O PR�XIMO TIRO
VAI_PARA_TIRO_SEGUINTE:
	INC R0 ;; APONTA PARA O X SEGUINTE
	CJNE @R0, #MARCA_PARADA_TIROS, TESTA_CHAO_PROXIMO_TIRO
FIM_LISTA_TIROS:
				;;ACABOU OS TIROS
	POP AR1
	POP AR0
	RET

TIRO_NA_ULTIMA_LINHA:
	  JNB TIRO_METADE_BAIXO, VAI_PARA_TIRO_SEGUINTE ;;AINDA PODE ANDAR MAIS UMA VEZ
						   ;;CHEGOU NA TERRA
						   
	  DEC R0
	  MOV A, @R0 ;;X DO TIRO CERTO
				;;ACERTOU A NAVE OU A TERRA???
				 ;;SE X DO TIRO - X DA NAVE< TAMANHO DA NAVE, ACERTOU A NAVE
	 CLR C
	 SUBB A, PLAYERX  ;; A AGORA TEM X DO TIRO - X DA NAVE
	 JC ACERTOU_CHAO
	 SUBB A, #12D		;;MENOS O TAMANHO DA NAVE MAIS UM, PARA DAR O CARRY CERTO
	 JC	ACERTOU_NAVE

ACERTOU_CHAO:
		MOV A, R0 ;;APONTANDO PARA O X DO TIRO CERTO
	  CALL REMOVE_TIRO_INIMIGO_LISTA
		DEC R0	 ;;APONTA PARA O Y DO TIRO ANTERIOR, PARA IR PR� O TIRO SEGUINTE CERTO
	  JMP VAI_PARA_TIRO_SEGUINTE

ACERTOU_NAVE:  ;;TEORICAMENTE ISSO NUNCA VAI ACONTECER, POIS ELE PESQUISA ANTES
				;	 SE ALGUM TIRO ACERTOU A NAVE E DEPOIS SE UM TIRO ACERTOU O CH�O 
	  	MOV A, R0 ;;APONTANDO PARA O X DO TIRO CERTO
	  	CALL REMOVE_TIRO_INIMIGO_LISTA
		CALL MATA_NAVE
		DEC R0
		JMP VAI_PARA_TIRO_SEGUINTE

;;;;;;;;;;FUNCAO QUE REMOVE UM TIRO DA LISTA DE TIROS DOS INIMIGOS;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; A EST� APONTANDO PARA O TIRO CERTO	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
REMOVE_TIRO_INIMIGO_LISTA:
  PUSH AR0
  PUSH AR1
  MOV R0, A ;;R0 FICA APONTANDO PARA O TIRO
  MOV R1, A ;;R1 TAMB�M FICA APONTANDO, COMO AUXILIAR
  
  MOV A, @R0 ;;COLOCA O X DO TIRO A SER APPAGADO NO A
  INC R0
  MOV B, @R0 ;;COLOCA O Y DO TIRO A SER APAGADO NO B
  CALL APAGA_TIRO_LCD
  
  INC R0 	;;APONTA PARA O X DO PR�XIMO TIRO
 CJNE @R0, #MARCA_PARADA_TIROS, REMOVE_PROXIMO_TIRO  ;;CASO N�O TENHA PROXIMO TIRO
	JMP MARCA_FIM_LISTA	


REMOVE_PROXIMO_TIRO:
	MOV A, @R0
  MOV @R1, A ;; MOVE A POSI�AO CERTA DO PROXIMO TIRO PARA O ANTERIOR
  INC R0
  INC R1

CJNE @R0, #MARCA_PARADA_TIROS, REMOVE_PROXIMO_TIRO ;;MOVE OS TIROS AT� ENCONTRAR O FINAL

MARCA_FIM_LISTA:
	MOV @R1, #MARCA_PARADA_TIROS	 ;;INDICA QUE ALI ACABA A LISTA E RETORNA
	INC R1
	MOV @R1, #00H
	POP AR1
	POP AR0 	
	RET	
	
;;;;;;;;;;;;;;;; FIM DA FUN�AO QUE REMOVE UM TIRO DA LISTA;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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
		XRL A, #0FFH ;;J� ESTA MORTO
		
		JZ DISPARA_TIRO_DE_TRAS

DISPARA_TIRO_DA_FRENTE:
	  	MOV A, @R1	;R1 EST� APONTANDO PARA O x DO INIMIGO DA FRENTE
		ADD A, #5D	;;PARTE DO MEIO DO INIMIGO
		CLR C		;; DA PARTE DE CIMA DA LINHA
		INC R1		;;APONTA PARA O Y DO INIMIGO
		MOV B, @R1 	
		INC B		;; B FICA COM O Y SEGUINTE
		CALL ADICIONA_TIRO_INIMIGO
		
		POP AR1	   ;; JA ATIROU, VOLTA
		POP AR0
		RET

DISPARA_TIRO_DE_TRAS:
		MOV A, @R0		;;R0 AINDA EST� APONTANDO PARA O X DO INIMIGO DE TRAS
		ADD A, #5D	;;PARTE DO MEIO DO INIMIGO
		CLR C		;; DA PARTE DE CIMA DA LINHA
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


	MOV R0, #ENEMIES
	MOV B, PLAYERX
	MOV R1, #NUMERO_INIMIGOS

PROXIMO_INIMIGO_MESMO_X:
	 MOV A, @R0
	XRL A, #0FFH ;;J� ESTA MORTO

	JZ COMPARA_X_PROXIMO_INIMIGO
	
	MOV A, @R0
	CALL ESTA_NA_MIRA				 ;; SE N�O EST� MORTO, SER� QUE EST� SOBRE A NAVE??
	JZ ESTA_SOBRE_NAVE								;; A=0 SE EST� SOBRE A NAVE
											 ;; SE N�O, OLHA O PR�XIMO
COMPARA_X_PROXIMO_INIMIGO:
	INC R0
	INC R0 		 ;;APONTA PARA O PROXIMO X
	DJNZ R1, PROXIMO_INIMIGO_MESMO_X

	MOV A,#00H ;;NENHUM INIMIGO EST� SOBRE A NAVE :( 

	POP AR1
	POP AR0
	RET

ESTA_SOBRE_NAVE:
	MOV A, R0 ;;A APONTA PARA O INIMIGO QUE ESTA SOBRE A NAVE

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
	PUSH AR1
	MOV B, PLAYERX
	MOV R0, #11D ;;OLHA POR TODOS OS PONTOS DA NAVE
	ADD A, #5D	;;SE O MEIO DO INIMIGO EST� SOBRE A NAVE
	MOV R1, A ;;SALVA O LUGAR DO TIRO
PROXIMA_POSICAO_NAVE:
	MOV A, R1
	XRL A, B	 ;;SE A POSI��O DA NAVE E A DO CANHAO � IGUAL, TA NA MIRA
	JZ NA_MIRA
	INC B
	DJNZ R0, PROXIMA_POSICAO_NAVE ;;SE NAO TENTA NA PROXIMA POSICAO DA NAVE
NAO_ESTA_NA_MIRA:
	  MOV A, #0FFH
	  POP AR1
	  POP AR0
	  RET
NA_MIRA:
	MOV A, #00H
	POP AR1
	POP AR0
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; FIM DA FUN��O QUE DEFINE SE O INIMIGO ESTA SOBRE A NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	  


ADICIONA_TIRO_POSICAO BIT 27H
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
	 POP AR1
	 POP AR0
	 RET

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;;; PERCORRE A LISTA DE TIROS AT� A PARADA ;;;;;;;;;;;;;;;;;;
 ;;POSI��O INICIAL DADA EM R0. DEVOLVE R0 COM A POSI��O DE PARADA
PERCORRE_LISTA_TIROS_ATE_PARADA: 
	
	MOV A, @R0

	XRL A, #MARCA_PARADA_TIROS
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
	MOV A, PLAYERLIFE
	JZ MORREU_GAME_OVER
	DEC A ;GOD MODE
	MOV PLAYERLIFE, A
	CALL ATUALIZA_LED_VIDAS
	RET
MORREU_GAME_OVER:
	CALL ITS_GAME_OVER_MAN
	RET		;;LOL NUNCA VAI VOLTAR

;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MATA A NAVE;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; FUNCAO QUE OLHA QUANTAS VIDAS O JOGADOR AINDA TEM E LIGA OS LEDS DE ACORDO ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ATUALIZA_LED_VIDAS:
	MOV A, #3H
	XRL A, PLAYERLIFE
	JZ TRES_VIDAS
	MOV A, #2H
	XRL A, PLAYERLIFE
	JZ DUAS_VIDAS
	MOV A, PLAYERLIFE
	DEC A
	JZ UMA_VIDA
	;;NUNHUMA VIDA: TODOS OS LEDS APAGADOS
	SETB LED1
	SETB LED2
	SETB LED3
	RET
TRES_VIDAS:
	CLR LED1
	CLR LED2
	CLR LED3
	RET
DUAS_VIDAS:
	CLR LED1
	CLR LED2
	SETB LED3
	RET
UMA_VIDA:
	CLR LED1
	SETB LED2
	SETB LED3
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; FIM DA FUN�AO QUE LIGA OS LEDS DE ACORDO COM AS VIDAS ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; FUN��O CHAMADA QUANDO D� GAME OVER ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ITS_GAME_OVER_MAN:
	CLR TR0	;;PARA DE CONTAR O TIMER TAMB�M, N�O TEM MAIS INTERRUP��ES
	 CALL ESCREVE_GAME_OVER

	 JMP $ ;;CANCELA TODO O OUTRO PROCESSAMENTO, FICA AQUI PARA SEMPRE
	 RET 	;;LOL NEVER

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; FIM DA FUN��O DO GAME OVER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;  FUN�AO QUE MOVE OS INIMIGOS NA MEM�RIA E ESCREVE NO LCD ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_INIMIGOS:
	CALL MOVE_MEMORIA_INIMIGOS
	CALL MOVE_TODOS_OS_INIMIGOS_VIVOS
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE OS INIMIGOS TOTALMENTE ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	CLR MUDOU_DIRECAO
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
		
	MOV R0, #ENEMIES
	MOV DPTR, #TAB_INIMIGOS
	
	MOV R1, #00H ;CLR EM R1 N�O FUNC
	LOOP_INICIA_INIMIGOS:	
	MOV A, R1
	MOVC A, @A + DPTR
	MOV @R0, A
	INC R0
	INC R1
	CJNE R1, #016D, LOOP_INICIA_INIMIGOS ; S�O 8 INIMIGOS
	
	POP AR1
	POP AR0 
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TAB_INIMIGOS:
	;COORDENADAS Dos inimigos:
	;      X,    Y ,				   
	DB 15D, 00H   
	DB 35D, 00H
	DB 55D, 00H
	DB 75D, 00H
	DB 15D, 02H   
	DB 35D, 02H
	DB 55D, 02H
	DB 75D, 02H
	DB 0FFH
;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	   
;;;;;;;;;;;;;;;;;;;; FUN��O QUE MOVE OS INIMIGOS HORIZONTALMENTE NA MEM�RIA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_MEMORIA_TODOS_INIMIGOS_VIVOS:
	PUSH AR0
	PUSH AR1


	MOV PRIMEIRA_LINHA_LIMPAR, #0FH

	MOV R1, #NUMERO_INIMIGOS	
	MOV R0, #ENEMIES
ONE_MORE_ENEMY:	
	MOV A, @R0
	XRL A, #0FFH ;;J� ESTA MORTO

	JZ MOVE_PROXIMO_INIMIGO	  

	INC R0
	CALL ATUALIZA_PRIMEIRA_LINHA_LIMPAR	 ;;MANDA O Y DO INIMIGO
	DEC R0	 ;VOLTA PARA A POSI��O ANTERIOR
	


	MOV A, @R0  ;;X DO INIMIGO
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

;;;;;;;;;;;;ARRUMAR;;ARRUMAR;;ARRUMAR
MUDA_LINHA_MEMORIA_TODOS_INIMIGOS_VIVOS:
	PUSH AR0
	PUSH AR1
	MOV R1, #NUMERO_INIMIGOS	
	MOV R0, #ENEMIES
	INC R0 	;APONTA PARA O Y
ONE_MORE_ENEMY_1:	
	MOV A, @R0
	XRL A, #0FFH ;;J� ESTA MORTO
	JZ MOVE_PROXIMO_INIMIGO	

	CALL ATUALIZA_PRIMEIRA_LINHA_LIMPAR

	MOV A, @R0
	ADD A, #01H ;VAI PARA A LINHA DE BAIXO
		
	MOV @R0, A					 ;;MUDA O X DO INIMIGO
	CJNE A, #07H, MOVE_PROXIMO_INIMIGO_1	  ;CASO SEJA A LINHA 7, � GAME OVER MAN

INDICA_GAME_OVER:
		SETB GAME_OVER
		POP AR1
		POP AR0
 		RET	
					;VOLTA IMEDIATAMENTE E NEM PRECISA MAIS ESCREVER, J� MATA O BIXO E DEU MANO. E DEU
MOVE_PROXIMO_INIMIGO_1:
	INC R0
	INC R0 ;;VAI PARA O y DO INIMIGO SEGINTE
	DJNZ R1, ONE_MORE_ENEMY_1	 
	
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
			
	MOV MAIOR_X, #0H
	MOV MENOR_X, #0FFH

	MOV R1, #NUMERO_INIMIGOS	
	MOV R0, #ENEMIES
ONE_MORE_ENEMY_LALA:	
	MOV A, @R0
	XRL A, #0FFH			;;J� ESTA MORTO
	JZ BORDA_PROXIMO_INIMIGO
	
	MOV A,@R0			   ; SER� O MENOR?
	SUBB A, MENOR_X					;SUBTRAI O X ATUAL DO MENOR_X , SE N�O DER CARRY � POR QUE O X ATUAL � MENOR
	JC ESSE_EH_MENOR

	MOV A, @R0				; SE NAO, SER� O MAIOR???
	SUBB A, MAIOR_X
	JNC ESSE_EH_MAIOR
	
	;;SE NAO � NADA, S� VAI PRO PR�XIMO
BORDA_PROXIMO_INIMIGO:
	INC R0
	INC R0 ;;VAI PARA O X DO INIMIGO SEGINTE
	DJNZ R1, ONE_MORE_ENEMY_LALA
VOLTA_BORDAS:	

	POP AR1
	POP AR0
 	RET	 
ESSE_EH_MAIOR:
 	MOV A, @R0
 	MOV MAIOR_X, A
	JMP BORDA_PROXIMO_INIMIGO
ESSE_EH_MENOR:
	MOV A, @R0
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


;;;;;;;;;;;; FUNCAO QUE APAGA O TIRO QUANDO ELE ALCAN�A O CHAO;;;;;;;;;;;;;
;;;;;;;;;;;;;X DO TIRO DADO EM A, Y DADO EM B;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
APAGA_TIRO_LCD:
		CALL TRADUZ_X
	  ADD A, #040H ;;TIRO NO X CERTO
	  CALL ESCREVE_COMANDO_LCD
	  MOV A, B
	  CALL TRADUZ_Y_TIRO ;;VAI FICAR EM A A LINHA CERTADO TIRO
	  ADD A, #0B8H 	;; TIRO NO Y CERTO	
	  CALL ESCREVE_COMANDO_LCD
	  MOV A, #00H ;;LIMPA O LUGAR
	  CALL ESCREVE_DADO_LCD
	  RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; PEGA A POSI��O DA MEM�RIA E ESCREVE A NAVE, A POSI��O X ANTIGA DA NAVE FICA EM A
MOVE_NAVE:
   	CLR ET0
	CALL TRADUZ_X	;;A FICA COM A POSI��O X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL LIMPA_NAVE	 ;; LIMPA A NAVE DA TELA

	MOV A, PLAYERX;A FICA COM A POSI��O x DA NAVE
	CALL TRADUZ_X	;;A FICA COM A POSI��O X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL DESENHA_NAVE  ;; DESENHA A NAVE NO NOVO LUGAR DA TELA
	SETB ET0
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; FUN��O QUE MOVE OS TIROS DOS INIMIGOS, BASEADO NOS DADOS DA MEM�RIA;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_TIROS_INIMIGOS_LCD:
	PUSH AR0
   	PUSH AR1

	MOV R0, #ENEMY_SHOTS
	CJNE @R0, #MARCA_PARADA_TIROS, PROXIMO_TIRO_INIMIGO
;NENHUM TIRO AINDA
	POP AR1
	POP AR0
	RET

PROXIMO_TIRO_INIMIGO:	
	MOV A, @R0			;;PEGA O X
	 MOV R1, A;;;;SALVA O X CERTO
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
	MOV A, R1
	CALL TRADUZ_X
	ADD A, #040H
	CALL ESCREVE_COMANDO_LCD   ;;COLOCA NA POSI��O X CERTA
	
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

	 POP AR1
	 POP AR0
	 RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MOVE OS TIROS DOS INIMIGOS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; FUN��O QUE MOVE OS TIROS DA NAVE, BASEADO NOS DADOS DA MEM�RIA;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	JB TIRO_METADE_BAIXO, ESCREVE_TIRO_NAVE_METADE_BAIXO
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
	
	MOV A, PLAYER_SHOTX		;PEGA O X
	CALL TRADUZ_X
	ADD A, #040H
	CALL ESCREVE_COMANDO_LCD   ;;COLOCA NA POSI��O X CERTA
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
	MOV A, PLAYERX	;;A FICA COM A POSI��O x DA NAVE
	CALL TRADUZ_X	;;A FICA COM A POSI��O X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL LIMPA_NAVE	 ;; LIMPA A NAVE DA TELA
	MOV A, PLAYERX	;;A FICA COM A POSI��O x DA NAVE
	CALL TRADUZ_X	;;A FICA COM A POSI��O X CORRETA DA NAVE, E O BIT SELECT FICA APROPRIADO
	CALL DESENHA_MORTE_NAVE	;DESENHA A MORTE E LIMPA DEPOIS DE UM TEMPO
	MOV PLAYERX, #STARTINGX
	CLR TODOS
	MOV	 A, #STARTINGX
	CALL TRADUZ_X
	CALL DESENHA_NAVE
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE MATA A NAVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; MATA UM INIMIGO. R0 J� EST� APONTANDO PARA O INIMIGO CERTO;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; SO DEPOIS ZERAR AS POSI��ES DE MEM�RIA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MATA_UM_INIMIGO_LCD:
	PUSH AR0
	;;R0 ESTA J� NA POSI��O DO INIMIGO CERTO
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
	PUSH AR0
	PUSH AR1
	PUSH AR2
	
	MOV A, PRIMEIRA_LINHA_LIMPAR
	CALL LIMPA_DUAS_LINHAS
	MOV R0, #ENEMIES	;SALVA O ENDERE�O DOS INIMIGOS

	MOV R1, #NUMERO_INIMIGOS	  ;;S�O NO M�XIMO 8 INIMIGOS PARA MOVER

MOVE:

	MOV A, @R0	
	XRL A, #0FFH   ;ESTA MORTO?

	JZ PROXIMO
	;;;; SE O INIMIGO N�O ESTA MORTO
	MOV A, @R0
	CALL TRADUZ_X ;;A FICA COM O X CORRETO
	INC R0
	MOV B, @R0 ;; B FICA COM O VALOR DE Y
	CALL DESENHA_INIMIGO
	DEC R0 ;;S� PARA FUNCIONAR OS DOIS INC ABAIXO
	
PROXIMO:
	 INC R0
	 INC R0 ;APONTA PARA O X DO PR�XIMO INIMIGO


	 DJNZ R1, MOVE 
	 
	 POP AR2
	 POP AR1
	 POP AR0
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
;;;;;;;;;;;;;;;;;;;;;;;; RECEBE EM A O Y CORRETO, LCD J� NO X CERTO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LIMPA_LINHA_ANT:
	 PUSH AR1
	MOV R1, A ;;SALVA O Y  CORRETO
	DEC A
	ADD A, #0B8H
	CALL ESCREVE_COMANDO_LCD ;;COLOCA NO Y CERTO
	MOV A, #00H
	CALL ESCREVE_DADO_LCD

	MOV A, R1	  ;;DEVOLVE O Y CORRETO

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
	MOV A, R1				;DEVOLVE O Y CORRETO
	POP AR1
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; FIM DA FUN��O QUE LIMPA A LINHA SEGUINTE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	


  SALVA_SELECT BIT 28H
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; RECEBE A POSI��O X DA NAVE EM A, DESENHA A MORTE, E DEPOIS DE UM TEMPO APAGA ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DESENHA_MORTE_NAVE:
			PUSH AR1
			PUSH AR2
			MOV C, SELECT
			MOV SALVA_SELECT, C
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
			  MOV C, SALVA_SELECT
			  MOV SELECT, C
			  CALL LIMPA_NAVE
			  CALL DELAY ;;DEBUG
			  CALL DELAY  ;;DEBUG 
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
				INC A
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
		CLR C
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
		CLR C
		SUBB A, #64D
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
			  MOV LINHA_LCD, #07h
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
		MOV A, #0C0H
		CALL ESCREVE_COMANDO_LCD

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