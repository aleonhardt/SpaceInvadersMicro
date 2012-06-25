USING 0

SHOT_NULL EQU 0FFH

ORG 0000H
	JMP INICIO

ORG 0100H
INICIO:
CALL INICIALIZA_INIMIGOS


INICIALIZA_INIMIGOS:
											  ; PREENCHE OS DADOS DOS INIMIGOS
	;MOV PRIMEIRA_VEZ, #01H   ; DIZ QUE JA INICIO
	PUSH AR0
	PUSH AR1

	SETB DIRECAO_INIMIGOS	  ;;INICIALIZA OS INIMIGOS ANDANDO PRÁ ESQUERDA
	CLR MUDOU_DIRECAO
		
	MOV R0, #ENEMIES
	MOV DPTR, #TAB_INIMIGOS
	
	MOV R1, #00H ;CLR EM R1 NÃO FUNC
	LOOP_INICIA_INIMIGOS:	
	MOV A, R1
	MOVC A, @A + DPTR
	MOV @R0, A
	INC R0
	INC R1
	CJNE R1, #016D, LOOP_INICIA_INIMIGOS ; SÃO 8 INIMIGOS
	
	POP AR1
	POP AR0 
	RET

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


REINICIO:
	
	CALL VERIFICA_QUANTIDADE_INIMIGOS_VIVOS ; ISSO COLOCA EM ENEMIES_ALIVE O VALOR DE INIMIGOS VIVOS
	MOV  A,  ENEMIES_ALIVE
	JNZ AINDA_VIVEM

	CALL INICIALIZA_INIMIGOS
	AINDA_VIVEM:
	RET

 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 VERIFICA_TIRO_X: ; RECEBE DO R0 A POSIÇÃO X DE UM INIMIGO
 							  ;FUNÇÃO QUE PERCORRE TODO O TAMANHO DO INIMIGO X ATÉ X+11 E DIZ NO FLAG ACERTOU_TIRO_X
	 						  ; SE FOI BALEADO
	PUSH AR0 
	PUSH AR1
	PUSH AR2

  

  MOV  ACERTOU_TIRO_X, #00H

  MOV A,@R0	 ; COM ESSA MANOBRA CONSEGUIMOS COLOCAR NO R1 O VALOR ATUAL DE X
  MOV R1, A

  MOV R2, #00H ; R2 NOVAMENTE O CONTADOR, VAI ACABAR QUANDO CHEGAR NA POSIÇÃO 11 DA NAVE
  TESTA_PROXIMA_LARGURA_X:
  MOV A,R1
  XRL A, PLAYER_SHOTX
  JZ ACERTO_O_INIMIGO
  INC R1
  INC R2
  CJNE R2, #0BH, TESTA_PROXIMA_LARGURA_X
  JMP ACABO_VERIFICA_TIRO_X
  ACERTO_O_INIMIGO:
  MOV  ACERTOU_TIRO_X, #01H
  ACABO_VERIFICA_TIRO_X:

  	POP AR2 
	POP AR1
	POP AR0

  RET
   
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VERIFICA_QUANTIDADE_INIMIGOS_VIVOS:	 ; EH SO CHAMAR ELA QUE DIZ QUANTOS INIMIGOS TEM VIVOS
																 ; FEITA PARA USAR COM UM COMEÇA DENOVO
	PUSH AR0 
	PUSH AR2

	

	MOV R2, 00H ;PARA VARIAR R2 É MEU CONTADOR DE VEZES QUE PARA EM 8
	MOV ENEMIES_ALIVE, #00H
    MOV R0, #ENEMIES
	 
	PROXIMA_CHECAGEM_DE_VIVOS:
	MOV A, @R0
	XRL A, #0FFH
	JZ ADICIONA_OA_NUMERO_DE_VIVOS

	INC R0				 ;PROXIMO X
	INC R0
	INC R2               ; INCREMENTA CONTADOR
	CJNE R2, #08H, PROXIMA_CHECAGEM_DE_VIVOS ; SE CHAGA EM 8 SAI DA FUNÇÃO SE NÃO PROCURA O PROXIMO
	JMP ACABO_VERIFICA_QUANTIDADE_INIMIGOS_VIVOS

	ADICIONA_OA_NUMERO_DE_VIVOS:
	MOV A, ENEMIES_ALIVE
	INC A
	MOV ENEMIES_ALIVE, A
	INC R0				 ;PROXIMO X
	INC R0
	INC R2               ; INCREMENTA CONTADOR
	CJNE R2, #08H, PROXIMA_CHECAGEM_DE_VIVOS ; SE CHAGA EM 8 SAI DA FUNÇÃO SE NÃO PROCURA O PROXIMO
	
	ACABO_VERIFICA_QUANTIDADE_INIMIGOS_VIVOS:

	POP AR2 
	POP AR0
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VERIFICA_MORTE_INIMIGO:
	PUSH AR0 
	PUSH AR2

	MOV R0, #ENEMIES
	MOV R2, #00H ;VAI INDICAR QUANTOS JA PROCUROU

	PROCURA_PROXIMO_VIVO:
	CJNE @R0, #0FFH, ESTA_VIVO							;R0 DETEM X INIMIGO ATUAL
																			;FF É A MARCA DA MORTE
	INC R0 ; PARA APONTAR PARA O PROXIMO X ENIMIGO VIVO
	INC R0
	INC R2 
	CJNE R2, #08H, PROCURA_PROXIMO_VIVO		; 8 É O NUMERO DE INIMIGOS
	JMP ACABOU_VERIFICA_MORTE_INIMIGO

	ESTA_VIVO:
	;HORA DE VERIFICAR SE NÃO TOMOU UM TIRO
	
	 CALL VERIFICA_TIRO_X ;FUNÇÃO QUE PERCORRE TODO O TAMANHO DO INIMIGO DE X ATÉ X+11 E DIZ NO FLAG ACERTOU_TIRO_X
	 									; SE FOI BALEADO  
	
	MOV A, ACERTOU_TIRO_X
	JZ INCREMENTA_R0_EM_dois_PROCURA_PROXIMO_VIVO ; SE NÃO PEGOU NA LARGURA ENTÃO JA NÃO ACERTOU.
																					     ; VAI PARA O PROXIMO INIMIGO

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;1)estou matando quando y igual a y, disso mais duas questões:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;1.1)	pode ser quando y + 1 tiro esta na frente de y? ou seja na frente não dentro
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;1.2) o y possui algum comprimento? a calda do y seria fatal se existe??
	
														
	INC R0	; AGORA APONTAM PARA Y

	MOV A, @R0
	CALL TRADUZ_Y_TIRO

	CJNE A, PLAYER_SHOTY, INCREMENTA_R0_EM_um_PROCURA_PROXIMO_VIVO
																				; O INCREMENTO EM 1 É PORQUE JA ESTAMOS NO Y
   ;;;;;;;;;;;;;;; ACERTOU O TIRO Y E X IGUAIS
   DEC R0        ;APONTA PARA O X DA NAVE QUE FOI PEGA
   
   CALL MATA_INIMIGO_ANULA_TIRO ; FUNÇÃO QUE MATA QUEM TA NO R0 E DIZ QUE TIRO DA NAVE N EXISTE MAIS
	JMP ACABOU_VERIFICA_MORTE_INIMIGO ;;; SÓ VAI PRO FIM  O MESMO QUE JA   




 INCREMENTA_R0_EM_dois_PROCURA_PROXIMO_VIVO:
 	INC R0
 INCREMENTA_R0_EM_um_PROCURA_PROXIMO_VIVO:
 	INC R0
	INC R2 ; MAIS UM FOI TESTADO

	CJNE R2, #08H, PROCURA_PROXIMO_VIVO		; 8 É O NUMERO DE INIMIGOS SE N PULAR CHEGOU AO FIM
   ACABOU_VERIFICA_MORTE_INIMIGO:


	POP AR2
	POP AR0

	RET


TRADUZ_Y_TIRO:
	RET


ENEMIES DATA 33H

PLAYER_SHOTS DATA 43H  ;so tem um tiro por vez
PLAYER_SHOTX DATA 43H
PLAYER_SHOTY DATA 44H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; VERIFICAR JA QUE OS DADOS PODEM ESTAR EM OUTRO LUGAR
ENEMIES_ALIVE DATA 45H
DIRECAO_INIMIGOS BIT 05H
MUDOU_DIRECAO BIT 06H
ACERTOU_TIRO_X DATA 46H
PLAYERLIFE DATA 32H

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


MATA_INIMIGO_ANULA_TIRO: ; FUNÇÃO QUE MATA QUEM TA NO R0 E DIZ QUE TIRO DA NAVE N EXISTE MAIS
		PUSH AR0

		MOV @R0, 0FFH
		INC  R0
		MOV @R0, 0FFH

		MOV	PLAYER_SHOTX,	  SHOT_NULL
		MOV	PLAYER_SHOTY,	  SHOT_NULL
		RET










;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	 
END
 
