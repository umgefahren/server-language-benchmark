//
// Created by Hannes Furmans on 01.04.22.
//


#include <stdlib.h>
#include <stdio.h>
#include <netinet/in.h>
#include <unistd.h>
#include <pthread.h>

#ifdef __APPLE__
#define DOMAIN PF_INET
#elif __linux
#define DOMAIN AF_INET
#endif

#include "server.h"

void * handle_connection(void * arguments);

ssize_t read_line(int socket_fd, char * buffer);

int server_init(pthread_t * threads, int threads_num) {
    int server_fd = socket(DOMAIN, SOCK_STREAM, 6);
    if (server_fd == -1) {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }


    int opt = 1;
    int opt_result = setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    if (opt_result < 0) {
        perror("setsocketopt error");
        exit(EXIT_FAILURE);
    }


    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(8080);

    int bind_result = bind(server_fd, (struct sockaddr *)&address, sizeof(address));
    if (bind_result < 0) {
        perror("bind failure");
        exit(EXIT_FAILURE);
    }

    int listen_result = listen(server_fd, 1000);
    if (listen_result < 0) {
        perror("listen");
        exit(EXIT_FAILURE);
    }

    int addrlen = sizeof(address);
    for (;;) {
        int new_socket = accept(server_fd, (struct sockaddr *) &address, (socklen_t *) &addrlen);
        if (new_socket < 0) {
            perror("accept");
            exit(EXIT_FAILURE);
        }
        struct handler_params *params = malloc(sizeof(struct handler_params));
        params->socket_fd = new_socket;
        threads_num += 1;
        threads = realloc(threads, sizeof(pthread_t) * threads_num);
        pthread_t handler_thread = threads[threads_num - 1];
        int result_code = pthread_create(&handler_thread, NULL, handle_connection, params);
        printf("Result code %i\n", result_code);
        if (result_code != 0) {
            perror("error creating thread");
            close(server_fd);
            exit(EXIT_FAILURE);
        }
    }
    /*
    int join_code = pthread_join(handler_thread, NULL);
    if (join_code != 0) {
        perror("error joining");
        exit(EXIT_FAILURE);
    }
    */

    return 0;
}

void *handle_connection(void *arguments) {
    struct handler_params * params = (struct handler_params *) arguments;
    int socket_fd = params->socket_fd;
    printf("Socket fd => %i\n", socket_fd);
    char * buffer = malloc(sizeof(char) * 100);
    read_line(socket_fd, buffer);
    puts(buffer);
    close(socket_fd);
    return NULL;
}

ssize_t read_line(int socket_fd, char * buffer) {
    ssize_t buffer_offset = 0;
    ssize_t buff_len = 0;
    ssize_t total_read_len = 0;
    while (1) {
        ssize_t read_len = read(socket_fd, &buffer[buffer_offset], 100);
        buff_len += read_len;
        buffer_offset += read_len;
        total_read_len += read_len;
        buffer = realloc(buffer, sizeof(char) * buff_len);
        if (buffer == NULL) {
            perror("malloc error");
            exit(EXIT_FAILURE);
        }
        for (ssize_t i = buffer_offset; i < buffer_offset + read_len; i++) {
            char character = buffer[i];

            if (character == '\n')
                break;
        }
        if (read_len < 100) {
            break;
        }
    }
    return total_read_len;
}