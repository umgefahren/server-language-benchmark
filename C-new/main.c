#include <stdio.h>
#include <assert.h>
#include <stdlib.h>

#include "command.h"
#include "store.h"
#include "server.h"

int main() {
    compile_regex();

    struct Store * store = store_init();

    kstring_t * input = malloc(sizeof(kstring_t));
    input->s = malloc(sizeof(char) * 2);
    kputs("SET key value\n", input);

    struct CompleteCommand * command = command_parse(input);

    int out;
    unsigned long long counter_out;

    struct Record * ret = store_execute_command(store, command, &out, &counter_out);

    assert(ret == NULL);

    free(ks_release(input));

    input = malloc(sizeof(kstring_t));
    input->s = malloc(sizeof(char) * 2);

    kputs("GET key\n", input);

    command = command_parse(input);

    ret = store_execute_command(store, command, &out, &counter_out);

    assert(strcmp(ks_str(ret->value), "value") == 0);

    int server_fd = server_init();

    server_loop(server_fd, store);

    return 0;
}
