#pragma once
#define TABLE_SIZE 100

typedef struct {
    char* key;
    char* value;
} Entry;

typedef struct {
    Entry* entries[TABLE_SIZE];
} Map;

unsigned long hash(const char* str);
void initMap(Map* map);
void setMap(Map* map, const char* key, const char* value);
char* getMap(Map* map, const char* key);
void deleteMap(Map* map, const char* key);
void freeMap(Map* map);
void printMap(Map* map);