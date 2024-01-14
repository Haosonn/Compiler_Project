# SPL compiler generated assembly
.data
_prmpt: .asciiz "Enter an integer: "
_eol: .asciiz "\n"
.globl main
.text
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
main:
  li $t0, 110
  sw $t0, 0($gp)
  li $t0, 97
  sw $t0, 4($gp)
  li $t0, 3
  sw $t0, 8($gp)
  lw $t2, 0($gp)
  lw $t1, 4($gp)
  sub $t0, $t2, $t1
  sw $t0, 12($gp)
  li $t0, 2
  sw $t0, 16($gp)
  lw $t2, 8($gp)
  lw $t1, 16($gp)
  mul $t0, $t2, $t1
  sw $t0, 20($gp)
  lw $t2, 12($gp)
  lw $t1, 20($gp)
  add $t0, $t2, $t1
  sw $t0, 24($gp)
  lw $t2, 24($gp)
  move $t0, $t2
  sw $t0, 8($gp)
  lw $t1, 8($gp)
  move $t0, $t1
  sw $t0, 28($gp)
  lw $t2, 28($gp)
  move $a0, $t2
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal write
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  li $t0, 0
  sw $t0, 32($gp)
  lw $t1, 32($gp)
  move $v0, $t1
  move $a0,$v0
  li $v0, 17
  syscall
