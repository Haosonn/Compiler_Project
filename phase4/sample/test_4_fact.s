# SPL compiler generated assembly
.data
_prmpt: .asciiz "Enter an integer: "
_eol: .asciiz "\n"
.globl main
.text
j main
read:
  li $v0, 4
  la $a0, _prmpt
  syscall
  li $v0, 5
  syscall
  jr $ra
write:
  li $v0, 1
  syscall
  li $v0, 4
  la $a0, _eol
  syscall
  move $v0, $0
  jr $ra
fact:
  move $a0, $t0
  sw $t0, 0($gp)
  li $t3, 1
  lw $t2, 0($gp)
  beq $t2, $t3, label1
  j label2
label1:
  lw $t1, 0($gp)
  move $v0, $t1
  jr $ra
label2:
  lw $t2, 0($gp)
  addi $t0, $t2, -1
  sw $t0, 4($gp)
  lw $t1, 4($gp)
  addi $sp, $sp, -4
  sw $t1, 0($sp)
  addi $sp, $sp, -4
  jal fact
  move $t0, $v0
  addi $sp, $sp, -4
  sw $t0, 8($gp)
  lw $t2, 0($gp)
  lw $t1, 8($gp)
  mul $t0, $t2, $t1
  sw $t0, 12($gp)
  lw $t2, 12($gp)
  move $v0, $t2
  jr $ra
main:
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal read
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  move $t0, $v0
  sw $t0, 16($gp)
  lw $t1, 16($gp)
  move $t0, $t1
  sw $t0, 20($gp)
  li $t3, 1
  lw $t2, 20($gp)
  bgt $t2, $t3, label3
  j label4
label3:
  lw $t1, 20($gp)
  move $t1, $a0
  addi $sp, $sp, -8
  jal fact
  move $t0, $v0
  addi $sp, $sp, 0
  sw $t0, 24($gp)
  lw $t2, 24($gp)
  move $t0, $t2
  j label5
label4:
  sw $t0, 28($gp)
  li $t0, 1
label5:
  lw $t1, 28($gp)
  move $a0, $t1
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal write
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  sw $t0, 28($gp)
  li $v0, 0
  move $a0,$v0
  li $v0, 17
  syscall
