//
// Created by Hannes Furmans on 01.04.22.
//

#ifndef SERVER_BENCH_SERVER_H
#define SERVER_BENCH_SERVER_H

#include <sys/socket.h>
#include <sys/types.h>

struct handler_params {
    int socket_fd;
};

int server_init(pthread_t * threads, int threads_num);

#endif //SERVER_BENCH_SERVER_H
