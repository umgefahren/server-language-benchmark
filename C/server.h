//
// Created by Hannes Furmans on 01.04.22.
//

#ifndef SERVER_BENCH_SERVER_H
#define SERVER_BENCH_SERVER_H

#include <sys/socket.h>
#include <sys/types.h>

#include "store.h"

struct handler_params {
    int socket_fd;
    struct Store * store;
};

int server_init(pthread_t * threads, int threads_num, struct Store * store);

#endif //SERVER_BENCH_SERVER_H
