.include "inc/m8def.inc"

.equ BAUD_RATE = 12

.def temp = r16
.def temp2 = r21
.def status_reg = r17
.def com_reg = r18
.def port_char = r19
.def port_num = r20

.cseg
rjmp RESET
reti ;rjmp INT0
reti ;rjmp INT1
reti ;rjmp TIMER2_COMP
reti ;rjmp TIMER2_OVF
reti ;rjmp TIMER1_CAPT
reti ;rjmp TIMER1_COMPA
reti ;rjmp TIMER1_COMPB
reti ;rjmp TIMER1_OVF
reti ;rjmp TIMER0_OVF
reti ;rjmp SPI_STC
reti ;rjmp USART_RXC
reti ;rjmp USART_UDRE
reti ;rjmp USART_TXC
reti ;rjmp ADC
reti ;rjmp EE_RDY
reti ;rjmp ANA_COMP
reti ;rjmp TWI
reti ;rjmp SPM_READY

RESET:
	cli				; disable interrupts
	ldi temp, 1<<ACD
	out ACSR, temp
	clr temp
	out PortB, temp
	out PortC, temp
	out PortD, temp
	ser temp
	out DDRB, temp
	out DDRC, temp
	out DDRD, temp
	ldi port_num, 0
	ldi port_char, 'D'

	ldi temp, high(RAMEND)
	out SPH, temp
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(BAUD_RATE)	; high byte-half of BAUD_RATE
	out UBRRH, temp
	ldi temp, low(BAUD_RATE)	; low byte-half of BAUD_RATE
	out UBRRL, temp
	ldi temp, (1<<RXEN)|(1<<TXEN)	; enable transmit and recieve
	out UCSRB, temp
	sei				; enable interrupts
loop:
	rcall in_com
	rcall set_output
	rcall send_com
	rjmp loop

in_com:
	sbis UCSRA, RXC
	rjmp in_com
	in com_reg, UDR

	ldi status_reg, 0
	cpi com_reg, 'B'
	brlo check_num
	cpi com_reg, 'E'
	brsh check_num
	mov port_char, com_reg
	rjmp exit
check_num:
	cpi com_reg, '0'
	brlo exit_err
	cpi com_reg, '8'
	brsh exit_err
	subi com_reg, '0'
	mov port_num, com_reg
	rjmp exit
exit_err:
	ldi status_reg, 1
exit:	ret

set_output:
	cpi status_reg, 1
	breq s_o_exit
	ldi temp2, 1
	mov temp, port_num
	cpi temp, 0
	breq s_o_lp_exit
s_o_lp:
	lsl temp2
	dec temp
	brne s_o_lp
s_o_lp_exit:
	cpi port_char, 'B'
	rjmp B_port_set
	cpi port_char, 'C'
	rjmp C_port_set
D_port_set:
	ldi temp, PortD
	eor temp, temp2
	out PortD, temp
	rjmp s_o_exit
B_port_set:
	ldi temp, PortB
	eor temp, temp2
	out PortB, temp
	rjmp s_o_exit
C_port_set:
	ldi temp, PortC
	eor temp, temp2
	out PortC, temp
s_o_exit:
	ret

send_com:
	sbis UCSRA, UDRE
	rjmp send_com
	out UDR, status_reg
	ret
