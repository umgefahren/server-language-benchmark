//
// Created by Hannes Furmans on 06.04.22.
//

#include "store.h"

struct Record * copy_record(struct Record * kh_value) {
    if (kh_value == NULL)
        return NULL;

    struct Record * ret = malloc(sizeof(struct Record));
    memcpy(ret, kh_value, sizeof(struct Record));
    ret->key = malloc(sizeof(kstring_t));
    ret->key->s = malloc(sizeof(char) * ks_len(kh_value->key));
    ret->value = malloc(sizeof(kstring_t));
    ret->value->s = malloc(sizeof(char) * ks_len(kh_value->value));
    kputs(ks_str(kh_value->key), ret->key);
    kputs(ks_str(kh_value->value), ret->value);
    return ret;
}

struct Store * store_init() {
    struct Store * ret = malloc(sizeof(struct Store));
    ret->content = malloc(sizeof(kh_m32_t));
    ret->content = kh_init_m32();
    ret->rw_lock = malloc(sizeof(pthread_rwlock_t));
    ret->get_counter = malloc(sizeof(atomic_ullong));
    ret->set_counter = malloc(sizeof(atomic_ullong));
    ret->del_counter = malloc(sizeof(atomic_ullong));
    return ret;
}

inline struct Record * store_get(struct Store * store, char * key) {
    struct Record * ret = NULL;

    pthread_rwlock_rdlock(store->rw_lock);

    khint_t k = kh_get_m32(store->content, key);
    if (k != kh_end(store->content)) {
        struct Record * kh_value = kh_value(store->content, k);
        ret = copy_record(kh_value);
    }

    pthread_rwlock_unlock(store->rw_lock);

    atomic_fetch_add(store->get_counter, 1);

    return ret;
}

inline struct Record * store_set(struct Store * store, char * key, char * value) {
    kstring_t * record_key = malloc(sizeof(kstring_t));
    record_key->s = malloc(sizeof(char) * strlen(key));
    kputs(key, record_key);
    kstring_t * record_value = malloc(sizeof(kstring_t));
    record_value->s = malloc(sizeof(char) * strlen(value));
    kputs(value, record_value);
    struct Record * record = malloc(sizeof(struct Record));
    record->key = record_key;
    record->value = record_value;

    struct Record * ret = NULL;

    pthread_rwlock_rdlock(store->rw_lock);
    khint_t k = kh_get_m32(store->content, key);
    if (k != kh_end(store->content)) {
        struct Record * kh_value = kh_value(store->content, k);
        ret = copy_record(kh_value);
    }
    int absent;
    k = kh_put_m32(store->content, key, &absent);
    kh_value(store->content, k) = record;
    pthread_rwlock_unlock(store->rw_lock);

    atomic_fetch_add(store->set_counter, 1);

    return ret;
}

inline struct Record * store_del(struct Store * store, char * key) {
    struct Record * ret = NULL;

    pthread_rwlock_rdlock(store->rw_lock);

    khint_t k = kh_get_m32(store->content, key);
    if (k != kh_end(store->content)) {
        struct Record * kh_value = kh_value(store->content, k);
        ret = copy_record(kh_value);
    }
    kh_del_m32(store->content, k);
    pthread_rwlock_unlock(store->rw_lock);

    atomic_fetch_add(store->del_counter, 1);

    return ret;
}

inline unsigned long long store_get_counter(struct Store * store) {
    return atomic_load(store->get_counter);
}

inline unsigned long long store_set_counter(struct Store * store) {
    return atomic_load(store->set_counter);
}

inline unsigned long long store_del_counter(struct Store * store) {
    return atomic_load(store->del_counter);
}