# Phase 3

### Overview

​ In phase 3, we finished IR instruction generation and implement some sort of optimization, based on what we have achieved in the previous phases.

### Basic data structure

```c
typedef struct IRInstruction {
    IROpCode opcode;
    char op1[OP_LEN_MAX];
    char op2[OP_LEN_MAX];
    char res[OP_LEN_MAX];
    struct IRInstruction* prev;
    struct IRInstruction* next;
} IRInstruction;

typedef struct IRInstructionList {
    IRInstruction* head;
    IRInstruction* tail;
} IRInstructionList;
```

- We use quadruples to represent an IR instruction.
- We use double-linked list for connecting IR instructions.

```c
typedef enum {
    IR_OP_ADD,
    IR_OP_SUB,
    IR_OP_MUL,
    IR_OP_DIV,
    IR_OP_ASSIGN,
    IR_OP_GOTO,
    IR_OP_IF_EQ_GOTO,
    IR_OP_IF_LT_GOTO,
    IR_OP_IF_LEQ_GOTO,
    IR_OP_LABEL,
    IR_OP_RETURN,
    IR_OP_READ,
    IR_OP_WRITE,
    IR_OP_CALL,
    IR_OP_DEC,
    IR_OP_ARG,
    IR_OP_PARAM,
    IR_OP_GET_ADDR,
    IR_OP_GET_VALUE,
    IR_OP_ASSIGN_ADDR,
    IR_OP_FUNC
} IROpCode;

/*
    IROpCode    |           description
    ------------|---------------------------------
    ADD         |       res := op1 + op2
    SUB         |       res := op1 - op2  
    MUL         |       res := op1 * op2
    DIV         |       res := op1 / op2
    ASSIGN      |       res := op1
    GOTO        |       goto res
    IF_EQ_GOTO  |       if op1 == op2 goto res
    IF_LT_GOTO  |       if op1 < op2 goto res
    IF_LEQ_GOTO |       if op1 <= op2 goto res
    LABEL       |       res(label name) :
    RETURN      |       return res
    READ        |       read res
    WRITE       |       write res
    CALL        |       res := call op1(function name)
    DEC         |       dec res(pointer addr) op1(size)
    ARG         |       arg res
    PARAM       |       param res
    GET_ADDR    |       res := &op1
    GET_VALUE   |       res := *op1
    ASSIGN_ADDR |       *res := op1
    FUNC        |       function res:
*/
```

- Above is explanation of ``IROpCode``.

### General approach

  During parsing, we use ``SymbolTable`` to record different symbols from different scopes, and for every ``ParserNode``, we have a pointer from the parser tree node itself to its corresponding symbol table node, to achieve convenience when we generate IR instructions after the parser tree is completed.

  We adopt a recursive way to generate IR instructions from calling ``translate_program`` on final non-terminal ``Program``, which calls different translation functions according to the parser tree structure.

### Symbol name

  For each new symbols, we use a self-increment ``int`` to represent its id in the symbol table, which is used in IR instructions to represent its semantic value.

### (BONUS part): Assignment, Address, Allocation

  **Multiple dimension arrays** and **structure variables** can appear in the program, and they can be declared as **function parameters**.

  During our development, we find that the IR generation of assignments of ``PRIMITIVE, ARRAY, STRUCTURE`` are **completely** different.

  For example, consider the following declaration and assignments

  ```c
  int int_value; // Assume symbol name is "s1"
  int int_array[5][5]; // Assume symbol name is "s2"
  struct INT_STRUCT {
   int int_value; // Assume symbol name is "s4"
  } int_structure; // Assume symbol name is "s3"
  
  int_value = 1;
  /* Simply
   s1 := 1
  */
  int_array[1][2] = 1;
  /*
   get the base addr of int_array s2
   add multiplication of idx of step in corresponding dimension
   get final addr t1
   *t1 = 1
  */
  int_structure.int_value = 1;
  /*
   get the base addr of int_sturcture s3
   add offset
   get final addr t1
   *t2 = 1
  */
  ```

  Given the complexity shown above, we determine to use the symbol name to record its allocated address no matter it is primitive type, array type and struct type. Therefore, allocation is needed for every variable.

  As for passing parameters in functions, our way shows advantages of simplicity.

  ```c
  struct INT_STRUCT {
   int int_value; 
  } int_structure; 
  int int_array[5][5];
  int function(int param_array[5], struct INT_STRUCT param_struct) { ... }
  int main() { function(int_array, int_structure}; }
                        
  /* IR instructions
  FUNCTION main :
   param int_structure.name
   param int_array.name
   CALL function
   ...
  FUNCTION function:
   ARG s1 // accept int_array.name where its address is recorded
   ARG s2 // accept int_struct.name where its address is recorded
  */
  ```

  We allocate variable starting from `MEM_ALLOC_START = 0x10000`. Whenever a variable, which can be primitive, array or structure, need to be allocated, we first calculate its size recursively, and then assign the address value to symbol name for initialization.

### IR Optimization

IR optimization is a crucial part of compiler optimization. Its goal is to improve the intermediate code without changing the semantics of the program, thereby enhancing the efficiency of the generated target code. This optimization can be applied to any target machine, hence the term "machine-independent".
There are several IR Optimization techniques. We just implemented a few simple ones among them.

#### Constant folding

Compute the value of constant expressions at compile time and replace the expressions with the results.

#### Constant propagation

If a variable is assigned a constant value, all uses of this variable in the subsequent code can be replaced with this constant value.

#### Copy propagation

 If a variable is assigned the value of another variable, all uses of this variable in the subsequent code can be replaced with the variable it is assigned to.

#### Dead code elimination

In general, dead code elimination requires first performing program flow analysis and analyzing variable references from a global perspective. We only implemented a simple version, that is, deleting assignment statements of variables that are not referenced.
