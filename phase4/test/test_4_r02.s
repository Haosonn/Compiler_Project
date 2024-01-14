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
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal read
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  move $t0, $v0
  sw $t0, 0($gp)
  lw $t2, 0($gp)
  move $t0, $t2
  sw $t0, 4($gp)
  lw $t1, 4($gp)
  move $t0, $t1
  sw $t0, 8($gp)
  li $t0, 0
  sw $t0, 12($gp)
  lw $t2, 8($gp)
  lw $t1, 12($gp)
  bgt $t2, $t1, label0
  j label1
label0:
  li $t0, 1
  sw $t0, 16($gp)
  lw $t2, 16($gp)
  move $a0, $t2
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal write
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  j label2
label1:
  lw $t1, 4($gp)
  move $t0, $t1
  sw $t0, 20($gp)
  li $t0, 0
  sw $t0, 24($gp)
  lw $t2, 20($gp)
  lw $t1, 24($gp)
  blt $t2, $t1, label3
  j label4
label3:
  li $t0, 1
  sw $t0, 28($gp)
  lw $t2, 28($gp)
  neg $t2, $t2
  addi $t0, $t2, 0
  sw $t0, 32($gp)
  lw $t1, 32($gp)
  move $a0, $t1
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal write
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  j label5
label4:
  li $t0, 0
  sw $t0, 36($gp)
  lw $t2, 36($gp)
  move $a0, $t2
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal write
  lw $ra, 0($sp)
  addi $sp, $sp, 4
label5:
label2:
  li $t0, 0
  sw $t0, 40($gp)
  lw $t1, 40($gp)
  move $v0, $t1
  move $a0,$v0
  li $v0, 17
  syscall
