//
// Created by Hannes Furmans on 06.04.22.
//

#ifndef C_NEW_COMMAND_H
#define C_NEW_COMMAND_H

#include "klib/kstring.h"
#include <stdlib.h>
#include <stdbool.h>

enum CommandType {
    Get,
    Set,
    Del,
    GetCounter,
    SetCounter,
    DelCounter,
    Invalid
};

struct CompleteCommand {
    enum CommandType kind;
    kstring_t key;
    kstring_t value;
};

struct CompleteCommand * command_parse(kstring_t input);

void compile_regex();

bool is_counter(struct CompleteCommand * command);

#endif //C_NEW_COMMAND_H
