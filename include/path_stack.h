#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_STACK_SIZE 100

typedef struct {
    char* data[MAX_STACK_SIZE];
    int top;
} CharStack;

void initCharStack(CharStack* stack) {
    stack->top = -1;
}

int isCharStackEmpty(CharStack* stack) {
    return stack->top == -1;
}

int isCharStackFull(CharStack* stack) {
    return stack->top == MAX_STACK_SIZE - 1;
}

void pushCharStack(CharStack* stack, char* value) {
    if (isCharStackFull(stack)) {
        printf("Error: stack is full\n");
        return;
    }
    stack->data[++stack->top] = value;
}

char* popCharStack(CharStack* stack) {
    if (isCharStackEmpty(stack)) {
        printf("Error: stack is empty\n");
        return NULL;
    }
    return stack->data[stack->top--];
}

char* peekCharStack(CharStack* stack) {
    if (isCharStackEmpty(stack)) {
        printf("Error: stack is empty\n");
        return NULL;
    }
    return stack->data[stack->top];
}