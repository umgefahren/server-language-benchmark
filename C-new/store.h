//
// Created by Hannes Furmans on 06.04.22.
//

#ifndef C_NEW_STORE_H
#define C_NEW_STORE_H

#include <stdatomic.h>
#include <pthread.h>
#include "klib/khash.h"
#include "klib/kstring.h"

struct Record {
    kstring_t * key;
    kstring_t * value;
};

KHASH_MAP_INIT_STR(m32, struct Record *)

struct Store {
    atomic_ullong * get_counter;
    atomic_ullong * set_counter;
    atomic_ullong * del_counter;
    pthread_rwlock_t * rw_lock;
    khash_t(m32) * content;
};

struct Store * store_init();

struct Record * store_get(struct Store * store, char * key);

struct Record * store_set(struct Store * store, char * key, char * value);

struct Record * store_del(struct Store * store, char * key);

unsigned long long store_get_counter(struct Store * store);

unsigned long long store_set_counter(struct Store * store);

unsigned long long store_del_counter(struct Store * store);

#endif //C_NEW_STORE_H
