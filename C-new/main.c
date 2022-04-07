#include <stdio.h>
#include <assert.h>
#include <stdlib.h>

#include "command.h"
#include "store.h"
#include "server.h"

int main() {
    compile_regex();

    struct Store * store = store_init();

    int server_fd = server_init();

    server_loop(server_fd, store);

    return 0;
}
