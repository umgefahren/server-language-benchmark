#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include "c_hash_map.h"
#include "server.h"

int main() {
    c_hash_map_t * map = c_hash_map_init();
    c_hash_map_set(map, "hello", "world", 5);
    struct Record * out_record = c_hash_map_get(map, "hello");
    c_hash_map_destroy(map);
    puts(out_record->value);
    free(out_record);
    int threads_num = 0;
    pthread_t * threads = malloc(sizeof(pthread_t) * threads_num);

    server_init(threads, threads_num);
    return 0;
}
