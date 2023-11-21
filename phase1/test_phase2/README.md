# Difference Explanaion

## test1

.out missing:
Error type 1 at Line 10: a variable is used without a definition

## test4

.out missing:
Error type 1 at Line 14: a variable is used without a definition

## test5

.out why error:
Error type 7 at Line 11: binary operation on non-nunmber varibles

.myout missing because the type of a unmatching operation expression is determined by the first term of it:
Error type 5 at Line 11: unmatching type on both sides of assignment

## test7

same as test 5

## test11

.myout different error type because we dont use type 11 and 14. We use different symbol table for variable, struct, function:
Error type 2 at Line 5: a function is used without a definition

## test14

.myout missing because we dont care a null type expression t.c:
Error type 5 at Line 11: unmatching types appear at both sides of the assignment operator

## test15

.myout missing because implicit type conversion is not supported in out implementation.
