#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TABLE_SIZE 100

typedef struct {
    char* key;
    char* value;
} Entry;

typedef struct {
    Entry* entries[TABLE_SIZE];
} Map;

unsigned long hash(const char* str) {
    unsigned long hash = 5381;
    int c;
    while ((c = *str++)) {
        hash = ((hash << 5) + hash) + c;
    }
    return hash % TABLE_SIZE;
}

void initMap(Map* map) {
    for (int i = 0; i < TABLE_SIZE; i++) {
        map->entries[i] = NULL;
    }
}

void setMap(Map* map, const char* key, const char* value) {
    unsigned long index = hash(key);
    Entry* entry = map->entries[index];
    if (entry == NULL) {
        entry = malloc(sizeof(Entry));
        entry->key = strdup(key);
        map->entries[index] = entry;
    }
    entry->value = strdup(value);
}

char* getMap(Map* map, const char* key) {
    unsigned long index = hash(key);
    Entry* entry = map->entries[index];
    if (entry == NULL) {
        return NULL;
    }
    return entry->value;
}

void deleteMap(Map* map, const char* key) {
    unsigned long index = hash(key);
    Entry* entry = map->entries[index];
    if (entry != NULL) {
        free(entry->key);
        free(entry->value);
        free(entry);
        map->entries[index] = NULL;
    }
}

void freeMap(Map* map) {
    for (int i = 0; i < TABLE_SIZE; i++) {
        Entry* entry = map->entries[i];
        if (entry != NULL) {
            free(entry->key);
            free(entry->value);
            free(entry);
        }
    }
}

void printMap(Map* map) {
    for (int i = 0; i < TABLE_SIZE; i++) {
        Entry* entry = map->entries[i];
        if (entry != NULL) {
            printf("%s: %s\n", entry->key, entry->value);
        }
    }
}