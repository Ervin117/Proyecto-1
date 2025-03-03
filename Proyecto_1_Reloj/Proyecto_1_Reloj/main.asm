;
; Proyecto_1_Reloj.asm
;
; Created: 2/24/2025 4:41:01 PM
; Author : Ervin Gomez 231226
;

.include "M328DEF.inc"
.cseg
.org	0x0000
	JMP		START
.org	PCI2addr
	JMP		BOTONES

//.org	OVF2addr
	//JMP		LEDS1

.org	OVF1addr
	JMP		RELOJ_7SEG

//.org	OVF0addr
	//JMP		TNSTR

.equ T1Value = 0xE17B
.def MOD = R17
.def ACT = R18	

TABLA7SEG:	.DB		0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B //Orden de los numeros
					//0	   1	 2	    3	  4	    5    6     7	  8	    9	 

START: 
	//Configuración de la pila 
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

SETUP: 
	CLI		
	//Configuración del Prescaler TIMER1
	LDI		R16, (1<< CLKPCE)
	STS 	CLKPR, R16 
	LDI		R16, (1<< CLKPS2) 
	STS		CLKPR, R16

	//LDI		R16, (1<<CS01) | (1<<CS00)
	//OUT		TCCR0B, R16
	//LDI		R16, 100
	//OUT		TCNT0, R16

	//PORTC como entradas botones
	CBI		DDRC, PC0
	CBI		DDRC, PC1
	CBI		DDRC, PC2
	SBI		DDRC, PC0
	SBI		DDRC, PC1
	SBI		DDRC, PC2

	//Pines para los transistores (MULTIPLEXACION)
	CBI		DDRB, PB0
	CBI		DDRB, PB1 
	CBI		PORTB, PB0
	CBI		PORTB, PB1
	//CBI		PORTB, PB2
	//CBI		PORTB, PB3

	//Se establece PORTD la salida de los Displays
	LDI		R16, 0xFF
	OUT		DDRD, R16 
	LDI		R16, 0x00
	OUT		PORTD, R16

	CALL	INI_TMR1
	CALL	INICIO

	LDI		R16, 0x00
	STS		UCSR0B, R16

	//Configuraciones de interrupciones TIMER0
	//LDI		R16, (1 <<TOIE0)
	//STS		TIMSK0, R16
	//LDI		R16, (1<< PCINT0) | (1<< PCINT1)
	//STS		PCMSK0, R16
	//LDI		R16, (1<< PCIE0)
	//STS		PCICR, R16

	//Interrupcion del TMR1
	LDI		R16, (1 <<TOIE1)
	STS		TIMSK1, R16

	//Interrpción Pin Change
	LDI	R16, (1 << PCINT9) | (1 << PCINT8) | (1 << PCINT10)
	STS	PCMSK1, R16
	LDI	R16, (1 << PCIE1)
	STS	PCICR, R16

	SEI

MAIN: 
	//Loop infinito
	OUT		PORTD, R22 
	CPI		MOD, 1
	BREQ	HRS
	CPI		MOD, 2
	BREQ	FCH
	CPI		MOD, 3
	BREQ	CONF_HRS
	CPI		MOD, 4
	BREQ	CONF_FCH
	CPI		MOD, 5
	BREQ	CONF_ALR
	CPI		MOD, 6
	BREQ	APG_ALR
	RJMP	MAIN

HRS: 
	//Poner en los displays el valor de las horas
	//logica para mostrar las horas 
	RJMP	MAIN

FCH: 
	//Poner en los displays el valor de la fecha
	//logica para mostrar la fecha 
	RJMP	MAIN

CONF_HRS: 
	//logica para editar las horas
	//resetear las horas
	SBIS	PINB, PB1 //Incrementar el display 1 (unidades minutos)

	SBIS	PINB, PB2 //Decrementar el display 1 (decenas minutos) 
	RJMP	MAIN

CONF_FCH: 
	//logica para editar la fecha
	//Resetear la fecha
	SBIS	PINB, PB1 //Incrementar el display 1 (unidades dias)

	SBIS	PINB, PB2 //Decrementar el display 1 (decenas dias) 
	RJMP	MAIN
	
CONF_ALR: 
	//logica para configurar la alarma 
	//incremento, decremento, fijado 
	RJMP	MAIN

APG_ALR: 
	//logica para apagar la alarma. 
	//reseteo de la configuración de la alarma 
	RJMP	MAIN

INICIO:
	LDI		ZL, LOW(TABLA7SEG <<1)
	LDI		ZH, HIGH(TABLA7SEG <<1)
	LPM		R22, Z
	OUT		PORTD, R22
	RET

INI_TMR1:
	//Inicio del timer 1
	LDI		R16, HIGH(T1Value)
	STS		TCNT1H, R16
	LDI		R16, LOW(T1Value)
	STS		TCNT1L, R16

	LDI		R16, 0x00
	STS		TCCR1A, R16
	LDI		R16, (1 << CS11)
	STS		TCCR1B, R16
	RET

//******************************** LOGICA PARA EL RELOJ ******************************//
RELOJ_7SEG: 
	//Falta configuración del timer1/0
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	//SBI		TIFR0, TOV0
	//LDI		R16, 100
	//OUT		TCNT0, R16
	//INC		R20
	LDI		R16, HIGH(T1Value)
	STS		TCNT1H, R16
	LDI		R16, LOW(T1Value)
	STS		TCNT1L, R16
	CPI		R20, 100 //Ahora seria de un 1minuto por un minuto


	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

//******************************** LOGICA PARA LOS TRANSISTORES ******************************//
TNSTR: 
	//Falta configuración del timer2
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	SBI		TIFR0, TOV0
	LDI		R16, 100
	OUT		TCNT0, R16
	INC		R20
	CPI		R20, 100 //Ahora seria de un 500ms, se enciende las leds del medio 


	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI


//******************** LOGICA PARA LAS CONFIGURACIONES DEL RELOJ ***********************//
BOTONES: 
	PUSH	R16
	IN		R16, SERG
	PUSH	R16

	SBIS	PINB, PB0 //Ver si fue presionado, y cual es su valor para ver en cual modo estar 
	INC		MOD
	
	CPI		MOD, 0x07
	BRNE	MODOS
	CLR		MOD
	RJMP	FIN

MODOS: 
	CPI		MOD, 1
	BREQ	HRS_ISR
	CPI		MOD, 2
	BREQ	FCH_ISR
	CPI		MOD, 3
	BREQ	CONF_HRS_ISR
	CPI		MOD, 4
	BREQ	CONF_FCH_ISR
	CPI		MOD, 5
	BREQ	CONF_ALR_ISR
	CPI		MOD, 6
	BREQ	APG_ALR_ISR
	RJMP	FIN

HRS_ISR:
	RJMP	FIN

FCH_ISR:
	RJMP	FIN

CONF_HRS_ISR:	
	RJMP	FIN

CONF_FCH_ISR:
	RJMP	FIN

CONF_ALR_ISR:
	RJMP	FIN

APG_ALR_ISR:
	RJMP	FIN

FIN: 
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

//******************************** LOGICA PARA LAS LEDS ******************************//
LEDS1: 
	//Falta configuración del timer2
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	SBI		TIFR0, TOV0
	LDI		R16, 100
	OUT		TCNT0, R16
	INC		R20
	CPI		R20, 100 //Ahora seria de un 500ms, se enciende las leds del medio 


	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
