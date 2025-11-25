.text
.type main, @function
.globl main

.include "ecall_macros.s"


#
# Creator (https://creatorsim.github.io/creator/)
#

.data
    string1: .string "Insert the string length (no more than 100 characters) "
    string2: .string "Insert the string "
    string3: .string "Insert a char "
    space:   .zero 100

.text
main:
    
    # print "Insert char..."
    la a0, string3
    li a7, 4
    ecall
    
    li a7, 11
    ecall
    
    li a7, 12
    ecall

    # return
    jr ra

