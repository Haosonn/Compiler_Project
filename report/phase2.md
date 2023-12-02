# Phase 2

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


## Ex test

### test1

### test2

### test3

### test4

### test5
