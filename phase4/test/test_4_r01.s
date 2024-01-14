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
hanoi:
  lw $t3, 0($sp)
  addi $sp, $sp, 4
  lw $t4, 0($sp)
  addi $sp, $sp, 4
  lw $t5, 0($sp)
  addi $sp, $sp, 4
  lw $t0, 0($sp)
  addi $sp, $sp, 4
  sw $t0, 0($gp)
  lw $t0, 0($sp)
  addi $sp, $sp, 4
  sw $t0, 4($gp)
  lw $t0, 0($sp)
  addi $sp, $sp, 4
  sw $t0, 8($gp)
  lw $t0, 0($sp)
  addi $sp, $sp, 4
  addi $sp, $sp, -4
  sw $t5, 0($sp)
  addi $sp, $sp, -4
  sw $t4, 0($sp)
  addi $sp, $sp, -4
  sw $t3, 0($sp)
  sw $t0, 12($gp)
  lw $t2, 0($gp)
  move $t0, $t2
  sw $t0, 16($gp)
  li $t0, 1
  sw $t0, 20($gp)
  lw $t1, 16($gp)
  lw $t2, 20($gp)
  beq $t1, $t2, label0
  j label1
label0:
  lw $t1, 4($gp)
  move $t0, $t1
  sw $t0, 24($gp)
  li $t0, 10000
  sw $t0, 28($gp)
  lw $t2, 24($gp)
  lw $t1, 28($gp)
  mul $t0, $t2, $t1
  sw $t0, 32($gp)
  lw $t2, 12($gp)
  move $t0, $t2
  sw $t0, 36($gp)
  lw $t1, 32($gp)
  lw $t2, 36($gp)
  add $t0, $t1, $t2
  sw $t0, 40($gp)
  lw $t1, 40($gp)
  move $a0, $t1
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal write
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  j label2
label1:
  lw $t2, 0($gp)
  move $t0, $t2
  sw $t0, 44($gp)
  li $t0, 1
  sw $t0, 48($gp)
  lw $t1, 44($gp)
  lw $t2, 48($gp)
  sub $t0, $t1, $t2
  sw $t0, 52($gp)
  lw $t1, 4($gp)
  move $t0, $t1
  sw $t0, 56($gp)
  lw $t2, 12($gp)
  move $t0, $t2
  sw $t0, 60($gp)
  lw $t1, 8($gp)
  move $t0, $t1
  sw $t0, 64($gp)
  lw $t2, 64($gp)
  addi $sp, $sp, -4
  sw $t2, 0($sp)
  lw $t1, 60($gp)
  addi $sp, $sp, -4
  sw $t1, 0($sp)
  lw $t2, 56($gp)
  addi $sp, $sp, -4
  sw $t2, 0($sp)
  lw $t1, 52($gp)
  addi $sp, $sp, -4
  sw $t1, 0($sp)
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  addi $sp, $sp, -4
  sw $t0, 0($sp)
  addi $sp, $sp, -4
  sw $gp, 0($sp)
  addi $gp, $gp, 72
  jal hanoi
  lw $gp, 0($sp)
  addi $sp, $sp, 4
  lw $t0, 0($sp)
  addi $sp, $sp, 4
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  move $t0, $v0
  sw $t0, 68($gp)
  lw $t2, 4($gp)
  move $t0, $t2
  sw $t0, 72($gp)
  li $t0, 10000
  sw $t0, 76($gp)
  lw $t1, 72($gp)
  lw $t2, 76($gp)
  mul $t0, $t1, $t2
  sw $t0, 80($gp)
  lw $t1, 12($gp)
  move $t0, $t1
  sw $t0, 84($gp)
  lw $t2, 80($gp)
  lw $t1, 84($gp)
  add $t0, $t2, $t1
  sw $t0, 88($gp)
  lw $t2, 88($gp)
  move $a0, $t2
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  jal write
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  lw $t1, 0($gp)
  move $t0, $t1
  sw $t0, 92($gp)
  li $t0, 1
  sw $t0, 96($gp)
  lw $t2, 92($gp)
  lw $t1, 96($gp)
  sub $t0, $t2, $t1
  sw $t0, 100($gp)
  lw $t2, 8($gp)
  move $t0, $t2
  sw $t0, 104($gp)
  lw $t1, 4($gp)
  move $t0, $t1
  sw $t0, 108($gp)
  lw $t2, 12($gp)
  move $t0, $t2
  sw $t0, 112($gp)
  lw $t1, 112($gp)
  addi $sp, $sp, -4
  sw $t1, 0($sp)
  lw $t2, 108($gp)
  addi $sp, $sp, -4
  sw $t2, 0($sp)
  lw $t1, 104($gp)
  addi $sp, $sp, -4
  sw $t1, 0($sp)
  lw $t2, 100($gp)
  addi $sp, $sp, -4
  sw $t2, 0($sp)
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  addi $sp, $sp, -4
  sw $t0, 0($sp)
  addi $sp, $sp, -4
  sw $gp, 0($sp)
  addi $gp, $gp, 120
  jal hanoi
  lw $gp, 0($sp)
  addi $sp, $sp, 4
  lw $t0, 0($sp)
  addi $sp, $sp, 4
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  move $t0, $v0
label2:
  sw $t0, 116($gp)
  li $t0, 0
  sw $t0, 120($gp)
  lw $t1, 120($gp)
  move $v0, $t1
  jr $ra
main:
  li $t0, 3
  sw $t0, 124($gp)
  lw $t2, 124($gp)
  move $t0, $t2
  sw $t0, 128($gp)
  lw $t1, 128($gp)
  move $t0, $t1
  sw $t0, 132($gp)
  li $t0, 1
  sw $t0, 136($gp)
  li $t0, 2
  sw $t0, 140($gp)
  li $t0, 3
  sw $t0, 144($gp)
  lw $t2, 144($gp)
  addi $sp, $sp, -4
  sw $t2, 0($sp)
  lw $t1, 140($gp)
  addi $sp, $sp, -4
  sw $t1, 0($sp)
  lw $t2, 136($gp)
  addi $sp, $sp, -4
  sw $t2, 0($sp)
  lw $t1, 132($gp)
  addi $sp, $sp, -4
  sw $t1, 0($sp)
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  addi $sp, $sp, -4
  sw $t0, 0($sp)
  addi $sp, $sp, -4
  sw $gp, 0($sp)
  addi $gp, $gp, 152
  jal hanoi
  lw $gp, 0($sp)
  addi $sp, $sp, 4
  lw $t0, 0($sp)
  addi $sp, $sp, 4
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  move $t0, $v0
  sw $t0, 148($gp)
  li $t0, 0
  sw $t0, 152($gp)
  lw $t2, 152($gp)
  move $v0, $t2
  move $a0,$v0
  li $v0, 17
  syscall
