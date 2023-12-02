# CS323 - Compilers Project Phase 2

## Basic features

- ### Symbol Table

  - Data structure

    - We use a linked list to maintain the basic structure of symbol table.

    - ```c
      typedef struct SymbolTableNode
      {
          char *name;
          SymbolList *list;
          struct SymbolTableNode *next;
      } SymbolTableNode;
      
      typedef struct SymbolTable
      {
          SymbolTableNode *head;
      } SymbolTable;
      ```

  - Implementation

    - 解释一下declaration
    - We use a map to achieve optimization of lookup in symbol table

  - ### Scope check

    - Data structure

      - We use a linked list for variable sharing the same name in different scope

      - ```c
        typedef struct SymbolList
        {
            SymbolListNode *head;
        } SymbolList;
        
        typedef struct SymbolTableNode
        {
            char *name;
            SymbolList *list;
            struct SymbolTableNode *next;
        } SymbolTableNode;
        ```

     - We also use a linked list to maintain the data structure of different scope

     - ```c
       typedef struct ScopeListNode
       {
           SymbolTable *table;
           struct ScopeListNode *next;
       } ScopeListNode;
       
       typedef struct ScopeList
       {
           ScopeListNode *head;
       } ScopeList;
       ```
  
       
  
  - ### Bonus part
  
    - 
