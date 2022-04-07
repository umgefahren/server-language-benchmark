//
// Created by Hannes Furmans on 07.04.22.
//

#include <sys/socket.h>
#include <unistd.h>
#include <stdbool.h>
#include <netinet/in.h>
#include <strings.h>
#include <stdlib.h>
#include <pthread.h>

#include "server.h"

struct handler_params {
    int client_fd;
    struct Store * store;
};


int server_init() {
    int socket_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (socket_fd == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    if (setsockopt(socket_fd, SOL_SOCKET, SO_REUSEADDR, &(int){1}, sizeof(int)) < 0)
        perror("setsockopt(SO_REUSEADDR) failed");

    struct sockaddr_in servaddr;
    bzero(&servaddr, sizeof(struct sockaddr_in));
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    servaddr.sin_port = htons(8080);

    if ((bind(socket_fd, (const struct sockaddr *) &servaddr, sizeof(servaddr))) != 0) {
        perror("Binding to sockaddress failed");
        exit(1);
    }

    if ((listen(socket_fd, 5) != 0)) {
        perror("Failed to listen to socket");
        exit(1);
    }

    return socket_fd;
}

void * handler_function(void * void_params) {
    struct handler_params * params = void_params;

    size_t buffer_size = 70;
    char * buffer = malloc(sizeof(char) * buffer_size);
    int client_fd = params->client_fd;

    FILE * client_file = fdopen(client_fd, "r+w");

    struct Store * store = params->store;



    int write_out;

    while (1) {
        unsigned long long counter_out;
        struct Record * record;
        int out;

        if (getline(&buffer, &buffer_size, client_file) < 0) {
            fclose(client_file);
            close(client_fd);
            free(void_params);
            free(buffer);
            break;
        }
        kstring_t * buff_kstr = malloc(sizeof(kstring_t));
        buff_kstr->s = malloc(sizeof(char) * 1);
        kputs(buffer, buff_kstr);
        struct CompleteCommand * command = command_parse(buff_kstr);

        bool is_valid = true;

        if (command->kind == Invalid)
            is_valid = false;

        bool counter_command = is_counter(command);
        record = store_execute_command(store, command, &out, &counter_out);
        if (counter_command) {
            write_out = fprintf(client_file, "%llu\n", counter_out);
        } else if (record == NULL && is_valid) {
            write_out = fputs("not found\n", client_file);
        } else if (is_valid) {
            write_out = fputs(ks_str(record->value), client_file);
            fputc('\n', client_file);
            free(record);
        } else {
            write_out = fputs("invalid command\n", client_file);
        }

        if (write_out < 0) {
            perror("Closing connection");
            fclose(client_file);
            close(client_fd);
            break;
        }
    }

    return NULL;
};

int server_loop(int server_fd, struct Store * store) {
    while (1) {
        struct sockaddr_in cli;
        socklen_t len = sizeof(cli);

        pthread_t * new_thread = malloc(sizeof(pthread_t));
        struct handler_params * params = malloc(sizeof(struct handler_params));
        params->store = store;

        int connfd = accept(server_fd, (struct sockaddr *) &cli, &len);
        if (connfd < 0) {
            perror("sever accept failed...");
            exit(1);
        }

        params->client_fd = connfd;
        if (pthread_create(new_thread, NULL, handler_function, params) != 0) {
            perror("Creation of new thread failed");
            exit(1);
        }
    }

    return 0;
}