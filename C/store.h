//
// Created by Hannes Furmans on 01.04.22.
//

#ifndef SERVER_BENCH_STORE_H
#define SERVER_BENCH_STORE_H

#define STD_DUMP_INTERVAL 10.0

#include <stdatomic.h>
#include <pthread.h>
#include <time.h>
#include <stdbool.h>

#include "c_hash_map.h"

struct Store {
    c_hash_map_t * content;
    atomic_ullong get_counter;
    atomic_ullong set_counter;
    atomic_ullong del_counter;
    char * dump_string;
    pthread_rwlock_t * dump_string_mutex;
    time_t last_dump;
    double dump_delta;
};

struct Store * store_init();

void store_destroy(struct Store * store);

void store_set(struct Store * store, char * key, char * value, unsigned int value_len);

struct Record * store_get(struct Store * store, char * key);

void store_del(struct Store * store, char * key);

unsigned long long store_get_counter(struct Store * store);

unsigned long long store_set_counter(struct Store * store);

unsigned long long store_del_counter(struct Store * store);

char * store_new_dump(struct Store * store, char * out);

char * store_get_dump(struct Store * store);

void store_change_interval(struct Store * store, double interval);

double convert_to_seconds(struct tm * time);

#endif //SERVER_BENCH_STORE_H
