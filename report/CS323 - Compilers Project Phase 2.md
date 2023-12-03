# Phase 2

## For test

```bash
# for convenience we only use these two commands to test our compiler
make test #test our self created cases
make test_extra #test extra cases
```

## Scope checking

For scope checking, we implement by a way similar to giving method shown in following graph.

![image-20231202150355802](D:\cs323\Compiler_Project\report\image-20231202150355802.png)

The different is that in our implementation, a scope stack node points to a symbol table which contains symbol table nodes in the scope. That is, each node in scope stack holds a symbol table which is a subset of the global table(symbol table for global scope).

## Struct member

We can easily find that the member variable of a struct is just in its DefList scope wrapped in curly braces.

```c
StructSpecifier: STRUCT IDT LC DefList RC
```

By the way, noticed our implementation of scope checking, we realize we should do something when there is a curly brace. So we make some change on grammer, where the LCT and RCT is the terminal from flex, and the LC and RC are used for other grammer in bison. 

```c
LC: LCT { printDerivation("LC -> LCT\n"); $$ = initParserNode("LC", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); 
        scope_list_add(scope_stack);
}
    ;
RC: RCT { printDerivation("RC -> RCT\n"); $$ = initParserNode("RC", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); 
        temp_member_table = scope_list_pop(scope_stack);
        symbol_table_remove_empty(global_table);
}
    ;
```

In this reduce, we can do scope adding and popping.

Then for struct member declare, we save variables in a scope, when popping it, in the  temp_member_table in case of a possible struct declaration.

And in the reduce shown in following code, we can use temp_member_table to make type of a struct and make the type of a struct in symbol table point to it.

```
StructSpecifier: STRUCT IDT LC DefList RC
```

## Declaration

We add a variable|function|struct to the symbol table when we see a ID. 

```c
VarDec: ID 
```

But at that time, we do not know its type, even if it's a function, a variable or a struct. So we just add this ID to symbol table with a  type pointer pointing to a blank type, and save it in parse node. Later when we can determine its type, that is when we see a specifier, we traverse the parse tree and copy the type to where the pointer point to(to the symbol table). 

But noticed we have different  table for variable|function|struct, how can we determine which symbol table to add the ID. Actually we can simply add a new term representing the ID of a function|struct named IDT, which will not lead to any conflicts. 

```
ID: IDT{printDerivation("ID -> IDT\n"); $$ = $1; }
    ;
```



Then we add the ID to variable table when we see 

```
VarDec: ID 
```

and add the IDT to correct table when we see 

```
FunDec: IDT LPF VarList RPF
```

  or 

```
StructSpecifier: STRUCT IDT LC DefList RC 
```

## Type equivalence

- Here is our definition of different ``Type`` It has 4 categories

  - Primitive
    - Int Float Char

  - Array: an array of ``Type``

  - Structure, Function: we reuse the data structure ``SymbolTable`` to represent information within it respectively. Specifically, the first member in the ``SymbolTable`` of ``function`` is the return value.

- ```c
  typedef struct Type {
      enum {
          PRIMITIVE,
          ARRAY,
          STRUCTURE,
          FUNCTION
      } category;
      union {
          enum {
              SEMANTIC_TYPE_INT,
              SEMANTIC_TYPE_FLOAT,
              SEMANTIC_TYPE_CHAR
          } primitive;
          struct Array *array;
          SymbolTable *structure;
          SymbolTable *function;
      };
  } Type;
  typedef struct Array {
      struct Type *base;
      int size;
  } Array;
  ```

  

- We use a recursive way to determine whether two struct is different or not

- ```c
  int struct_equal(SymbolTable *struct1, SymbolTable *struct2) {
      SymbolTableNode *node1 = struct1->head;
      SymbolTableNode *node2 = struct2->head;
      while (node1 != NULL && node2 != NULL) {
          if (!type_equal(node1->list->head->type, node2->list->head->type))
              return 0;
          node1 = node1->next; node2 = node2->next;
      }
      return node1 == NULL && node2 == NULL;
  }
  int type_equal(Type *type1, Type *type2) {
      if (type1 == NULL || type2 == NULL)
          return 0;
      if (type1->category != type2->category)
          return 0;
      switch (type1->category)
      case PRIMITIVE:
          if (type1->primitive != type2->primitive)
              return 0; break;
      case ARRAY:
          if (!type_equal(type1->array->base, type2->array->base))
              return 0; break;
      case STRUCTURE:
          if (!struct_equal(type1->structure, type2->structure))
              return 0; break;
      case FUNCTION:
          if (!symbol_table_equal(type1->function, type2->function))
  			return 0; break;
      default:
          break;
  	}
      return 1;
  }
  ```


## Bonus test

### test_type

#### .spl

```
struct a {int x; float y;}a;
struct b {int m; float n;}b;
struct c {float p; int q;}c;
int test(){
    a=b;
    a=c;
    return 0;
}
```

#### .spl.myout:

```
Error type 5 at Line 6: unmatching types appear at both sides of the assignment operator
```

#### Explanation:

At Line 1, **struct a** is in struct table while **struct a {int x; float y;}a;** is in variable table, no error

Line 2 and Line3 are same as Line 1

At Line 5, **a** and **b** are equal type because they are both **struct{int, float}**

At Line 6, **a** and **b** are not equal type because **a** is **struct{int, float}** while b is **struct{float, int}**

### test_scope

#### .spl

```
float a;
struct s1 {int a;};
struct s2 {float a;}b;
int test1(){
    return a;
}
int test2(){
    int a;
    return a;
}
struct s1 test3(){
    return b;
}
struct s1 test4(){
    struct s1 b;
    return b;
}
```

#### .spl.myout:

```
Error type 8 at Line 5: Type mismatched for return.
Error type 8 at Line 12: Type mismatched for return.
```

#### Explanation:

At Line 5 in test1, a is float but not int.

At Line 9 in test2, a is int in this scope.

At Line 12 in test3, b is struct s2 but not struct s1.

At Line 16 in test4, b is struct s1 in this scope.
