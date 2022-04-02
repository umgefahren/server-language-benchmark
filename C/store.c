//
// Created by Hannes Furmans on 01.04.22.
//

#include <stdlib.h>

#include "store.h"

struct Store * store_init() {
    struct Store * ret = malloc(sizeof(struct Store));
    ret->content = c_hash_map_init();
    atomic_store(&ret->set_counter, 0);
    atomic_store(&ret->get_counter, 0);
    atomic_store(&ret->del_counter, 0);
    return ret;
};

void store_destroy(struct Store * store) {
    c_hash_map_destroy(store->content);
    free(store);
};

void store_set(struct Store * store, char * key, char * value, unsigned int value_len) {
    c_hash_map_set(store->content, key, value, value_len);
    store->set_counter += 1;
};

struct Record * store_get(struct Store * store, char * key) {
    struct Record * ret = c_hash_map_get(store->content, key);
    store->get_counter += 1;
    return ret;
};

void store_del(struct Store * store, char * key) {
    c_hash_map_del(store->content, key);
    store->del_counter += 1;
};

unsigned long long store_get_counter(struct Store * store) {
    return atomic_load(&store->get_counter);
};

unsigned long long store_set_counter(struct Store * store) {
    return atomic_load(&store->set_counter);
};

unsigned long long store_del_counter(struct Store * store) {
    return atomic_load(&store->del_counter);
};