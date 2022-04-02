//
// Created by Hannes Furmans on 01.04.22.
//

#ifndef SERVER_BENCH_STORE_H
#define SERVER_BENCH_STORE_H

#include <stdatomic.h>

#include "c_hash_map.h"

struct Store {
    c_hash_map_t * content;
    atomic_ullong get_counter;
    atomic_ullong set_counter;
    atomic_ullong del_counter;
};

struct Store * store_init();

void store_destroy(struct Store * store);

void store_set(struct Store * store, char * key, char * value, unsigned int value_len);

struct Record * store_get(struct Store * store, char * key);

void store_del(struct Store * store, char * key);

unsigned long long store_get_counter(struct Store * store);

unsigned long long store_set_counter(struct Store * store);

unsigned long long store_del_counter(struct Store * store);

#endif //SERVER_BENCH_STORE_H
