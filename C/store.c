//
// Created by Hannes Furmans on 01.04.22.
//

#include <stdlib.h>
#include <string.h>

#include "store.h"

struct Store * store_init() {
    struct Store * ret = malloc(sizeof(struct Store));
    ret->content = c_hash_map_init();
    atomic_store(&ret->set_counter, 0);
    atomic_store(&ret->get_counter, 0);
    atomic_store(&ret->del_counter, 0);
    ret->dump_string = malloc(sizeof(char) * 2);
    ret->dump_string[0] = *"[";
    ret->dump_string[1] = *"]";
    ret->dump_string_mutex = malloc(sizeof(pthread_rwlock_t));
    ret->last_dump = time(NULL);
    ret->dump_delta = STD_DUMP_INTERVAL;
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

inline char * store_new_dump(struct Store * store, char * out) {
    unsigned long records_num = 0;
    struct Record * records = c_hash_map_all_records(store->content, &records_num);
    char * opening_bracket = "[";
    out = realloc(out, sizeof(char) * (strlen(out) + strlen(opening_bracket)));
    out = strcat(out, opening_bracket);
    for (unsigned long i = 0; i < records_num; i++) {
        char * key_label = "{ \"key\": \"";
        char * key = records[i].key;
        char * associated_value_label = "\",\"associated_value\":{\"value\":\"";
        char * value = records[i].value;
        char * timestamp_label = "\",\"timestamp\":\"";
        char * timestamp = ctime(&records[i].timestamp);
        char * closing = "\"}}";
        if (i < records_num - 1)
            closing = "\"}},";
        size_t size_of_value = strlen(key_label) + strlen(key) + strlen(associated_value_label) + strlen(value) +
                strlen(timestamp_label) + strlen(timestamp) + strlen(closing);
        char * value_string = malloc(sizeof(char) * size_of_value);
        value_string = strcat(value_string, key_label);
        value_string = strcat(value_string, key);
        value_string = strcat(value_string, associated_value_label);
        value_string = strcat(value_string, value);
        value_string = strcat(value_string, timestamp_label);
        value_string = strcat(value_string, timestamp);
        value_string = strcat(value_string, closing);
        out = realloc(out, sizeof(char) * (strlen(out) + strlen(value_string)));
        out = strcat(out, value_string);
    }
    char * closing_bracket = "]";
    out = realloc(out, sizeof(char) * (strlen(out) + strlen(closing_bracket)));
    out = strcat(out, closing_bracket);
    pthread_rwlock_wrlock(store->dump_string_mutex);
    free(store->dump_string);
    store->dump_string = malloc(sizeof(char) * strlen(out));
    strcpy(store->dump_string, out);
    store->last_dump = time(NULL);
    pthread_rwlock_unlock(store->dump_string_mutex);
    return out;
};

inline char * store_get_dump(struct Store * store) {
    pthread_rwlock_rdlock(store->dump_string_mutex);
    double time_delta = difftime(store->last_dump, time(NULL));
    if (time_delta < store->dump_delta) {
        char * out = malloc(sizeof(char) * strlen(store->dump_string));
        strcpy(out, store->dump_string);
        pthread_rwlock_unlock(store->dump_string_mutex);
        return out;
    } else {
        pthread_rwlock_unlock(store->dump_string_mutex);
        char * out = malloc(sizeof(char) * 1);
        return store_new_dump(store, out);
    }
}

void store_change_interval(struct Store * store, double interval) {
    pthread_rwlock_wrlock(store->dump_string_mutex);
    store->dump_delta = interval;
    pthread_rwlock_unlock(store->dump_string_mutex);
}