//
// Created by Hannes Furmans on 01.04.22.
//


#include <stdlib.h>
#include <stdio.h>
#include <netinet/in.h>
#include <unistd.h>
#include <pthread.h>
#include <string.h>

#ifdef __APPLE__
#define DOMAIN PF_INET
#elif __linux
#define DOMAIN AF_INET
#endif

#include "server.h"
#include "parser.h"

char * not_found_string = "not found";
unsigned long not_found_len = 9;

void * handle_connection(void * arguments);

ssize_t read_line(int socket_fd, char * buffer);

void execute_command(int socket_fd, struct CompleteCommand * command, struct Store * store);

int server_init(pthread_t * threads, int threads_num, struct Store * store) {
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
        params->store = store;
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
    while (1) {
        char * buffer = malloc(sizeof(char) * 100);
        ssize_t num = read_line(socket_fd, buffer);
        if (num == 0) {
                break;
        }
        struct CompleteCommand * command = parse(buffer);
        complete_command_print(command);
        execute_command(socket_fd, command, params->store);
        free(command);
    }
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

void write_record(int socket_fd, struct Record * record) {
    if (record == NULL) {
        write(socket_fd, not_found_string, not_found_len);
    } else {
        write(socket_fd, record->value, record->value_len);
    }
}

void write_counter(int socket_fd, unsigned long long value) {
    char ret_string[30000] = { " " };
    sprintf(ret_string, "%llu", value);
    write(socket_fd, ret_string, strlen(ret_string));
}

struct DelCommand {
    char * key;
    struct tm * sleep_time;
    struct Store * store;
};

void sleep_time(struct tm * time) {
    int second = 0;
    second += time->tm_sec;
    second += time->tm_min * 60;
    second += time->tm_hour * 60 * 60;
    sleep(second);
}

void * delete_handler(void * arguments) {
    struct DelCommand * del_command = (struct DelCommand *) arguments;
    sleep_time(del_command->sleep_time);
    store_del(del_command->store, del_command->key);
    free(del_command);
    return NULL;
}

void execute_command(int socket_fd, struct CompleteCommand * command, struct Store * store) {
    if (command->type == Get) {
        struct Record * ret_record = store_get(store, command->key);
        write_record(socket_fd, ret_record);
        free(ret_record);
    } else if (command->type == Set) {
        struct Record * ret_record = store_get(store, command->key);
        store_set(store, command->key, command->value, command->value_len);
        write_record(socket_fd, ret_record);
        free(ret_record);
    } else if (command->type == Del) {
        struct Record * ret_record = store_get(store, command->key);
        store_del(store, command->key);
        write_record(socket_fd, ret_record);
        free(ret_record);
    } else if (command->type == Get_Counter) {
        unsigned long long ret_val = store_get_counter(store);
        write_counter(socket_fd, ret_val);
    } else if (command->type == Set_Counter) {
        unsigned long long ret_val = store_set_counter(store);
        write_counter(socket_fd, ret_val);
    } else if (command->type == Del_Counter) {
        unsigned long long ret_val = store_del_counter(store);
        write_counter(socket_fd, ret_val);
    } else if (command->type == New_Dump) {
        char * out = malloc(sizeof(char) * 2);
        out = store_new_dump(store, out);
        write(socket_fd, out, strlen(out));
        free(out);
    } else if (command->type == Get_Dump) {
        char *out = store_get_dump(store);
        write(socket_fd, out, strlen(out));
        free(out);
    } else if (command->type == Dump_Interval) {
        double seconds = convert_to_seconds(command->time);
        store_change_interval(store, seconds);
    } else if (command->type == Set_TTL) {
        struct Record * ret_record = store_get(store, command->key);
        store_set(store, command->key, command->value, command->value_len);
        struct DelCommand * del_command = malloc(sizeof(struct DelCommand));
        del_command->key = malloc(sizeof(char) * strlen(command->key));
        strcpy(del_command->key, command->key);
        del_command->sleep_time = malloc(sizeof(struct tm));
        memcpy(del_command->sleep_time, command->time, sizeof(struct tm));
        pthread_t delete_thread;
        int result_code = pthread_create(&delete_thread, NULL, delete_handler, del_command);
        if (result_code != 0) {
            perror("Error creating deleting thread");
            exit(1);
        }
        write_record(socket_fd, ret_record);
        free(ret_record);
    }
    write(socket_fd, "\n", 1);
}

