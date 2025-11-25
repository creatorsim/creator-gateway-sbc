.extern print_float
.extern print_double
.section .bss
buffer:
    .space 20 #riscv64 han print until 20 digits (19 signed)
buffer_end:    
.section .data
minus_sign:
    .ascii "-"
nl: .ascii "\n" 
fmt_float: .string "%f\n"   
fmt_double: .string "%f\n"  
.section .text
#ifdef RISCV64_ORANGEPIRV2
.macro ecall
    addi sp, sp, -16       #ToDO: Save the right registers
    sw ra, 0(sp)           
    sw t0, 4(sp)           

    mv t0, a7              

    li t1, 1
    beq t0, t1, 1f 

    li t1, 2
    beq t0, t1, 2f

    li t1, 3
    beq t0, t1, 3f

    li t1, 4
    beq t0, t1, 4f

    li t1, 5
    beq t0, t1, 5f

    li t1, 8
    beq t0, t1, 8f

    li t1, 10
    beq t0, t1, 10f

    li t1, 11
    beq t0, t1, 11f
    
    li t1, 12
    beq t0, t1, 12f

    j 13f                   # return

1:
    la t1, buffer_end    # Apuntar al final del buffer
    li t2, 0             # contador dígitos
    li t5, 0              # limpiar flag negativo
    mv t0, a0            # copiar número

    bltz t0, .Lhandle_neg\@   # si t0 < 0 saltar para manejar signo

.Lcheck_zero\@:
    beqz t0, .Lprint_zero\@   # si es 0, imprimir '0'

    j .Lconvert_loop\@

.Lhandle_neg\@:
    neg t0, t0              # tomar valor absoluto
    li t5, 1                # marcar negativo

.Lconvert_loop\@:
    la t1, buffer_end       # apuntar al final del buffer
    li t2, 0                # contador dígitos

.Lloop\@:
    li t3, 10
    rem t4, t0, t3
    addi t4, t4, '0'
    addi t1, t1, -1
    sb t4, 0(t1)
    div t0, t0, t3
    addi t2, t2, 1
    bnez t0, .Lloop\@

    j .Lprint_number\@

.Lprint_zero\@:
    la t1, buffer_end
    addi t1, t1, -1
    li t4, '0'
    sb t4, 0(t1)
    li t2, 1

.Lprint_number\@:
    li a0, 1                

    # Print sign
    beqz t5, .Lprint_digits\@
    li a0, 1
    la a1, minus_sign
    li a2, 1
    li a7, 64
    .word 0x00000073
.Lprint_digits\@:
    mv a1, t1               
    mv a2, t2              
    li a7, 64
    .word 0x00000073

    # newline
    li a0, 1
    la a1, nl
    li a2, 1
    li a7, 64
    .word 0x00000073

    j 13f                   # salto al final o retorno


2:
    jal ra, print_float
    j 13f

3:
    jal ra, print_double
    j 13f 

4:
    # Print string
    mv t0, a0
    li t1, 0
.Lcount_loop\@: #count string length
    lbu t2, 0(t0)
    beq t2, zero, .Lcount_done\@ #if \0 founded, the string has been completly riden
    addi t1, t1, 1
    addi t0, t0, 1
    j .Lcount_loop\@
.Lcount_done\@:

    mv a1, a0
    mv a2, t1 #string lenght
    li a0, 1
    li a7, 64 # riscv original write instruction
    .word 0x00000073 # pure ecall!!

    # Print newline
    li a0, 1
    la a1, nl
    li a2, 1
    li a7, 64
    .word 0x00000073

    j 13f
5:
    # Read the line
    li a7, 63       # syscall number for read
    li a0, 0        # fd 0 (stdin)
    la a1, buffer   # address of buffer
    li a2, 20       # number of bytes to read
    .word 0x00000073
    # Process line
    mv t0, a0          # number bytes read
    li s0, 0           # s0 = acumulador del número
    li s1, 0           # s1 = flag signo (0 = +, 1 = -)
    la s2, buffer      # s2 = ptr actual en buffer
    mv s3, t0          # s3 = bytes restantes
    li s4, 0           # s4 = visto_digito (0/1)

.Lparse_loop\@:
    beqz s3, .Lfinish_parse\@   # si se acabó el buffer
    lb t1, 0(s2)                # cargar byte actual
    addi s2, s2, 1
    addi s3, s3, -1

    # si newline o carriage return, terminamos parseo
    li t2, 10
    beq t1, t2, .Lfinish_parse\@
    li t2, 13
    beq t1, t2, .Lparse_loop\@

    # permitir signo solo si aún no se ha visto dígito
    li t2, 45   # '-'
    beq t1, t2, .Lhandle_minus\@
    li t2, 43   # '+'
    beq t1, t2, .Lparse_loop\@

    # comprobar si es dígito '0'..'9'
    li t2, 48
    blt t1, t2, .Lfinish_parse\@
    li t2, 57
    bgt t1, t2, .Lfinish_parse\@

    # convertir ascii a valor
    li t2, 48
    sub t3, t1, t2     # t3 = digit value

    # s0 = s0 * 10 + t3   (usa mul)
    li t4, 10
    mul s0, s0, t4
    add s0, s0, t3

    li s4, 1            # hemos visto al menos 1 dígito
    j .Lparse_loop\@

.Lhandle_minus\@:
    beqz s4, .Lset_minus\@  # si aún no se vio dígito, aceptar signo
    j .Linvalid\@

.Lset_minus\@:
    li s1, 1
    j .Lparse_loop\@

.Lfinish_parse\@:
    beqz s4, .Linvalid\@
    # aplicar signo
    beqz s1, .Lsave_to_register\@
    nop                      # noop placeholder (reemplaza 'sub zero, zero, zero')
    neg s0, s0               # s0 = -s0

.Lsave_to_register\@: 
    mv a0, s0
    j 13f

.Linvalid\@:
    li a0, 0
    j 13f
     
8:
    li a7, 63       # syscall number for read
    mv t0,a0
    mv a2,a1
    mv a1,t0
    li a0, 0
    .word 0x00000073
    j 13f
10:
    li a7, 93       # syscall number for read
    li a0, 0
    .word 0x00000073
    j 13f  

11:
    li a7, 63       # syscall number for read
    li a0, 0        # fd 0 (stdin)
    la a1, buffer   # address of buffer
    li a2, 2      # number of bytes to read
    .word 0x00000073
    lb a0, buffer
    j 13f

12:
    # Print char
    mv a1, a0
    li a0,1
    li a2,1
    li a7,64
    .word 0x00000073      # <-- real ecall without macro

    li a0,1
    la a1, nl       # newline
    li a2,1
    li a7,64
    .word 0x00000073      # <-- real ecall without macro
    j 13f
13:
    lw t0, 4(sp)          
    lw ra, 0(sp)           
    addi sp, sp, 16 


.endm
#endif
