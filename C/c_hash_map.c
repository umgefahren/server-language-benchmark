//
// Created by Hannes Furmans on 31.03.22.
//

#include "c_hash_map.h"
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include "khash.h"

KHASH_MAP_INIT_STR(m32, struct Record *)

struct CHashMap {
    khash_t(m32) * content;
    pthread_rwlock_t *rw_lock;
};

typedef struct CHashMap c_hash_map_t;

c_hash_map_t * c_hash_map_init() {
    c_hash_map_t * ret = (c_hash_map_t *) malloc(sizeof(c_hash_map_t));
    ret->content = kh_init(m32);
    ret->rw_lock = malloc(sizeof(pthread_rwlock_t));
    int rw_init_res = pthread_rwlock_init(ret->rw_lock, NULL);
    if (rw_init_res != 0) {
        puts("Couldn't initialize RWLock of concurrent hash map");
        exit(1);
    };
    return ret;
};

void c_hash_map_destroy(c_hash_map_t * map) {
    for (khint_t k = kh_begin(map->content); k != kh_end(map->content); ++k) {
        if (kh_exist(map->content, k)) {
            struct Record * to_free = kh_value(map->content, k);
            free(to_free);
        }
    }
    kh_destroy(m32, map->content);
    int rw_destroy_res = pthread_rwlock_destroy(map->rw_lock);
    if (rw_destroy_res != 0) {
        puts("Couldn't destroy RWLock of concurrent hash map");
        exit(1);
    }
};

inline struct Record * c_hash_map_get(c_hash_map_t * map, char * key) {
   int rw_acquire_lock =  pthread_rwlock_rdlock(map->rw_lock);
   if (rw_acquire_lock != 0) {
       puts("Couldn't acquire read lock in concurrent hashmap");
       exit(1);
   }
   khint32_t kh_key = kh_get(m32, map->content, key);
   struct Record * in_value = kh_value(map->content, kh_key);
   pthread_rwlock_unlock(map->rw_lock);
   struct Record * out_value = malloc(sizeof(struct Record));
   memcpy(out_value, in_value, sizeof(struct Record));
   return out_value;
};

inline u_int8_t c_hash_map_set(c_hash_map_t * map, char * key, char * value, unsigned int value_len) {
    int rw_acquire_lock = pthread_rwlock_wrlock(map->rw_lock);
    if (rw_acquire_lock != 0) {
        puts("Couldn't acquire write lock in concurrent hashmap");
        return rw_acquire_lock;
    }
    struct Record * new_record = (struct Record *) malloc(sizeof(struct Record));
    new_record->value = malloc(sizeof(char) * value_len);
    new_record->value = value;
    new_record->value_len = value_len;
    new_record->timestamp = time(NULL);
    int absent;
    khint_t kh_key = kh_put(m32, map->content, key, &absent);
    kh_value(map->content, kh_key) = new_record;
    int rw_release_lock = pthread_rwlock_unlock(map->rw_lock);
    if (rw_release_lock != 0) {
        puts("Couldn't release write lock in concurrent hashmap");
        return rw_release_lock;
    }
    return 0;
};

inline u_int8_t c_hash_map_del(c_hash_map_t * map, char * key) {
    int rw_acquire_lock = pthread_rwlock_wrlock(map->rw_lock);
    if (rw_acquire_lock != 0) {
        puts("Couldn't acquire write lock in concurrent hashmap");
        return rw_acquire_lock;
    }
    khint_t k = kh_get(m32, map->content, key);
    kh_del(m32, map->content, k);
    int rw_release_lock = pthread_rwlock_unlock(map->rw_lock);
    return rw_release_lock;
};