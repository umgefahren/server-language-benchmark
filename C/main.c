#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include "server.h"
#include "store.h"
#include "parser.h"

int main() {
    compile_regex();

    struct Store * store = store_init();


    int threads_num = 0;
    pthread_t * threads = malloc(sizeof(pthread_t) * threads_num);

    server_init(threads, threads_num, store);
    return 0;
}
