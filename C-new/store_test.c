//
// Created by Hannes Furmans on 07.04.22.
//

#include <string.h>
#include <assert.h>
#include "klib/kstring.h"
#include "store.h"

int main() {
    struct Store * store = store_init();
    char * key = "Hello";
    char * value = "World";
    struct Record * ret = store_set(store, key, value);

    if (ret != NULL) {
        puts("NULL is an error");
        exit(1);
    }

    ret = store_get(store, key);

    assert(strcmp(ks_str(ret->value), value) == 0);
    puts(ks_str(ret->value));

    return 0;
}
