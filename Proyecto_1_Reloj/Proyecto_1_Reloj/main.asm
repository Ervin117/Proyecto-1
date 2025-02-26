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
.org	PCI0addr
	JMP		BOTONES

.org	OVF2addr
	JMP		LED1

.org	OVF1addr
	JMP		RELOJ_7SEG

.org	OVF0addr
	JMP		TNSTR

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

	LDI		R16, (1<< CLKPCE)
	STS 	CLKPR, R16 
	LDI		R16, (1<< CLKPS2) //Configuración a acorde al TIMER1
	STS		CLKPR, R16

	LDI		R16, (1<<CS01) | (1<<CS00)
	OUT		TCCR0B, R16
	LDI		R16, 100
	OUT		TCNT0, R16

	//Bits para configurar los transistores (MULTIPLEXACION)
	LDI		R16, 0x00
	OUT		DDRB, R16
	LDI		R16, 0xFF
	OUT		PORTB, R16
	CBI		DDRC, PC0
	CBI		DDRC, PC1 
	CBI		PORTC, PC2
	CBI		PORTC, PC3

	//Se establece 
	LDI		R16, 0xFF
	OUT		DDRD, R16 //Se establece D como salida 
	LDI		R16, 0x00
	OUT		PORTD, R16
	OUT		PORTC, R16

	CALL	INICIO

	LDI		R16, 0x00
	STS		UCSR0B, R16

	//Configuraciones de interrupciones TIMER1
	LDI		R16, (1 <<TOIE0)
	STS		TIMSK0, R16
	LDI		R16, (1<< PCINT0) | (1<< PCINT1)
	STS		PCMSK0, R16
	LDI		R16, (1<< PCIE0)
	STS		PCICR, R16

	SEI

MAIN: 
	//Loop infinito 
	RJMP	MAIN

INICIO:
	LDI		ZL, LOW(TABLA7SEG <<1)
	LDI		ZH, HIGH(TABLA7SEG <<1)
	LPM		R22, Z
	OUT		PORTD, R22
	RET

//******************************** LOGICA PARA LAS LEDS ******************************//
RELOJ_7SEG: 
	//Falt configuración del timer2
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


//******************************** LOGICA PARA EL RELOJ ******************************//
RELOJ_7SEG: 
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	SBI		TIFR0, TOV0
	LDI		R16, 100
	OUT		TCNT0, R16
	INC		R20
	CPI		R20, 100 //Ahora seria de un 1minuto por un minuto


	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI



//******************** LOGICA PARA LAS CONFIGURACIONES DEL RELOJ ***********************//
BOTONES: 
	PUSH	R16
	IN		R16, SERG
	PUSH	R16

	IN		R17, PINB 
	SBIS	PINB, PB0 //Ver si fue presionado, y cual es su valor para ver en cual modo estar 
	INC		R17
	CPI		R17, 0x07 //Valor maximo de los botonazos 
	BRNE	MODOS  //ver que modo esta activado
	CLR		R17  //resetear el contador de botonazos 

MODOS: 
	CPI		R17, 1
	BREQ	HRS
	CPI		R17, 2
	BREQ	FCH
	CPI		R17, 3
	BREQ	CONF_HRS
	CPI		R17, 4
	BREQ	CONF_FCH
	CPI		R17, 5
	BREQ	CONF_ALR
	CPI		R17, 6
	BREQ	APG_ALR
	RJMP	FIN //REGRESAR AL INICIO
	
HRS: 
	//Poner en los displays el valor de las horas
	//logica para mostrar las horas 

FCH: 
	//Poner en los displays el valor de la fecha
	//logica para mostrar la fecha 

CONF_HRS: 
	//logica para editar las horas
	//resetear las horas
	SBIS	PINB, PB1 //Incrementar el display 1 (unidades minutos)

	SBIS	PINB, PB2 //Decrementar el display 1 (decenas minutos) 

	SBIS	PINB, PB3 //Incrementar el display 2 (unidades horas)

	SBIS	PINB, PB4 //Decrementar el display 2 (decenas horas) 

CONF_FCH: 
	//logica para editar la fecha
	//Resetear la fecha
	SBIS	PINB, PB1 //Incrementar el display 1 (unidades dias)

	SBIS	PINB, PB2 //Decrementar el display 1 (unidades decenas) 

	SBIS	PINB, PB3 //Incrementar el display 2 (mes unidades)

	SBIS	PINB, PB4 //Decrementar el display 2 (mes decenas) 

CONF_ALR: 
	//logica para configurar la alarma 
	//incremento, decremento, fijado 

APG_ALR: 
	//logica para apagar la alarma. 
	//reseteo de la configuración de la alarma 


FIN: 
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
