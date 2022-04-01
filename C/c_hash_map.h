//
// Created by Hannes Furmans on 31.03.22.
//
// Implementation of a locked hash map with a C api

#ifndef SERVER_BENCH_C_HASH_MAP_H
#define SERVER_BENCH_C_HASH_MAP_H

#include <time.h>

#define NOT_FOUND
#define OK

struct Record {
    char * value;
    unsigned int value_len;
    time_t timestamp;
};

struct CHashMap;

typedef struct CHashMap c_hash_map_t;

c_hash_map_t * c_hash_map_init();

void c_hash_map_destroy(c_hash_map_t * map);

struct Record * c_hash_map_get(c_hash_map_t * map, char * key);

u_int8_t c_hash_map_set(c_hash_map_t * map, char * key, char * value, unsigned int value_len);

u_int8_t c_hash_map_del(c_hash_map_t * map, char * key);

#endif //SERVER_BENCH_C_HASH_MAP_H
