//
// Created by Hannes Furmans on 06.04.22.
//

#include <stdbool.h>
#include "store.h"

struct Record * copy_record(struct Record * kh_value) {
    if (kh_value == NULL)
        return NULL;

    struct Record * ret = malloc(sizeof(struct Record));
    memcpy(ret, kh_value, sizeof(struct Record));
    ret->key.s = NULL;
    ret->key.l = 0;
    ret->key.m = 0;
    ret->value.s = NULL;
    ret->value.l = 0;
    ret->value.m = 0;
    // ret->key = { 0, 0, NULL};
    // ret->key->s = malloc(sizeof(char) * ks_len(kh_value->key));
    // ret->value = malloc(sizeof(kstring_t));
    // ret->value->s = malloc(sizeof(char)  * ks_len(kh_value->value));
    kputs(ks_str(&kh_value->key), &ret->key);
    kputs(ks_str(&kh_value->value), &ret->value);
    return ret;
}

struct Store * store_init() {
    struct Store * ret = malloc(sizeof(struct Store));
    ret->content = malloc(sizeof(kh_m32_t));
    ret->content = kh_init_m32();
    ret->content->vals = malloc(sizeof(struct Record *));
    ret->content->keys = malloc(sizeof(struct kh_m32_s));
    ret->rw_lock = malloc(sizeof(pthread_rwlock_t));
    pthread_rwlock_init(ret->rw_lock, NULL);
    ret->get_counter = malloc(sizeof(atomic_ullong));
    ret->set_counter = malloc(sizeof(atomic_ullong));
    ret->del_counter = malloc(sizeof(atomic_ullong));
    return ret;
}

inline struct Record * store_get(struct Store * store, char * key) {
    struct Record * ret = NULL;
    int lock_res = pthread_rwlock_rdlock(store->rw_lock);
    if(lock_res != 0) {
        printf("Error code %i\n", lock_res);
        perror("Couldn't accquire lock");
        exit(1);
    }

    khint_t k = kh_get_m32(store->content, key);
    printf("GET %i %s\n", k, key);
    if (k != kh_end(store->content)) {
        struct Record * kh_value = kh_value(store->content, k);
        ret = copy_record(kh_value);
    }

    pthread_rwlock_unlock(store->rw_lock);

    atomic_fetch_add(store->get_counter, 1);

    return ret;
}

inline struct Record * store_set(struct Store * store, char * key, char * value) {
    kstring_t record_key = {0, 0, NULL};
    // record_key->s = malloc(sizeof(char) * strlen(key));
    kputs(key, &record_key);
    kstring_t record_value = { 0, 0, NULL };
    // record_value->s = malloc(sizeof(char) * strlen(value));
    kputs(value, &record_value);
    struct Record * record = malloc(sizeof(struct Record));
    record->key = record_key;
    record->value = record_value;

    struct Record * ret = NULL;

    int lock_res = pthread_rwlock_wrlock(store->rw_lock);
    if(lock_res != 0) {
        printf("Error code %i\n", lock_res);
        perror("Couldn't accquire lock");
        exit(1);
    }
    khint_t k = kh_get_m32(store->content, key);

    if (k != kh_end(store->content)) {
        struct Record * kh_value = kh_value(store->content, k);
        ret = copy_record(kh_value);
    }
    int absent;
    // char * internal_key = strdup(key);
    k = kh_put_m32(store->content, key, &absent);
    printf("SET %i %s\n", k, key);
    if (absent) {
        kh_key(store->content, k) = strdup(key);
    }


    kh_value(store->content, k) = record;
    pthread_rwlock_unlock(store->rw_lock);

    atomic_fetch_add(store->set_counter, 1);

    return ret;
}

inline struct Record * store_del(struct Store * store, char * key) {
    struct Record * ret = NULL;


    int lock_res = pthread_rwlock_wrlock(store->rw_lock);
    if(lock_res != 0) {
        printf("Error code %i\n", lock_res);
        perror("Couldn't accquire lock");
        exit(1);
    }
    khint_t k = kh_get_m32(store->content, key);
    printf("DEL %i %s\n", k, key);
    if (k != kh_end(store->content)) {
        struct Record * kh_value = kh_value(store->content, k);
        ret = kh_value;
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

struct Record * store_execute_command(struct Store * store, struct CompleteCommand * command, int * out, unsigned long long * counter_out) {
    if (command->kind == Invalid) {
        *out = COMMAND_IS_INVALID;
        return NULL;
    }

    struct Record * ret = NULL;

    bool free_key = false;
    bool free_val = false;

    if (command->kind == Get) {
        ret = store_get(store, ks_str(command->key));
        free_key = true;
    } else if (command->kind == Set) {
        ret = store_set(store, ks_str(command->key), ks_str(command->value));
        free_key = true,
        free_val = true;
    } else if (command->kind == Del) {
        ret = store_del(store, ks_str(command->key));
        free_key = true;
    } else if (command->kind == GetCounter)
        *counter_out = store_get_counter(store);
    else if (command->kind == SetCounter)
        *counter_out = store_set_counter(store);
    else if (command->kind == DelCounter)
        *counter_out = store_del_counter(store);

    if (free_key) {
        free(ks_release(command->key));
    }

    if (free_val) {
        free(ks_release(command->value));
    }

    free(command);

    return ret;
}