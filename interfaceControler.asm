
DATA_DISP	EQU	P1		; Porta onde esta colocado o barramento de dados do display
EN 			EQU P3.7	; Bit EN do Display		
RS 			EQU P3.6	; Bit R/S do Display

ORG 	0000H			; Vetor RESET
   	LJMP 	INICIO			; Pula para o inicio do programa principal




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
;-- Envia (escreve) comando colocado em A para o LCD
;
ESCREVE_COMANDO_LCD:
	MOV		DATA_DISP,A		; escreve na porta de dados do LCD
	CLR		RS				; zera RS para indicar comando
PULSO_EN_LCD:
	SETB	EN				; da um pulso 0 - 1 - 0 em EN
	CLR		EN
	MOV		R7,#10			; gera um atraso
	CALL 	ATRASO
	RET
	
;--------------------------------------------------------------------------------
;-- Envia (escreve) dado colocado em A para o LCD
;
ESCREVE_DADO_LCD:
	MOV 	DATA_DISP,A		; escreve na porta de dados do LCD
	SETB	RS				; seta RS para indicar dado
	JMP		PULSO_EN_LCD	; da um pulso 0 - 1 - 0 em EN (ja escrito na outra rotina)

;--------------------------------------------------------------------------------
;-- Inicializa o Display: Envia comandos para configurar LCD
;
INICIO_LCD:   
	MOV     A,#38H                 ; DEFINE MATRIZ
	LCALL   ESCREVE_COMANDO_LCD
	MOV     A,#06H                 ; DESLOCA CURSOR DIREITA
	LCALL   ESCREVE_COMANDO_LCD
	MOV     A,#0EH                 ; CURSOR FIXO
	LCALL   ESCREVE_COMANDO_LCD
	MOV     A,#01H                 ; LIMPA DISPLAY
	LCALL   ESCREVE_COMANDO_LCD
	RET

END