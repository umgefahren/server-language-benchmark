//
// Created by Hannes Furmans on 06.04.22.
//

#include <stdlib.h>
#include "command.h"
#include "klib/kstring.h"

int main() {
    kstring_t input = { 0, 0, NULL };
    kputs("SET key value\n", &input);
    compile_regex();
    struct CompleteCommand * command = command_parse(input);

}