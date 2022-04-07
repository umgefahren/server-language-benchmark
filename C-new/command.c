//
// Created by Hannes Furmans on 06.04.22.
//

#define GET_STRING "GET"
#define SET_STRING "SET"
#define DEL_STRING "DEL"
#define GET_COUNTER_STRING "GETC"
#define SET_COUNTER_STRING "SETC"
#define DEL_COUNTER_STRING "DELC"

#include <string.h>
#include <regex.h>
#include "command.h"

regex_t regex;

void compile_regex() {
    int reti = regcomp(&regex, "[a-zA-Z0-9]+", REG_EXTENDED);
    if (reti) {
        fprintf(stderr, "ERROR Couldn't compile regex\n");
        exit(1);
    }
}

void invalidate_command(struct CompleteCommand * command) {
    command->kind = Invalid;
}

kstring_t strip(kstring_t input) {
    // kstring_t ret =k ;
    kstring_t ret = { 0, 0, NULL };
    // ret->s = malloc(sizeof(char)*2);

    size_t len = ks_len(&input);
    for (size_t i = 0; i < len; i++) {
        char character = ks_str(&input)[i];
        if (character == '\n')
            break;
        kputc(character, &ret);
    }
    free(ks_release(&input));
    return ret;
}

struct CompleteCommand * command_parse(kstring_t input) {
    struct CompleteCommand * ret = malloc(sizeof(struct CompleteCommand));
    invalidate_command(ret);

    kstring_t stripped = strip(input);


    int nums = 0;

    int * offsets = ksplit(&stripped, ' ', &nums);

    char * command_type_string = NULL;

    if (nums >= 1) {
        command_type_string = malloc(sizeof(char) * offsets[1]);

        strncpy(command_type_string, ks_str(&stripped), offsets[1]);
    }

    if (nums == 3) {
        if (strcmp(command_type_string, SET_STRING) == 0) {
            ret->kind = Set;
            free(command_type_string);

            int len = offsets[2] - offsets[1];
            char * offset_pointer = ks_str(&stripped) + offsets[1];
            char * command_key_string = strndup(offset_pointer, len);

            /*
            char * command_key_string = NULL;
            kstring_t command_k_string = { 0, 0, NULL };

            int counter = 0;

            while (1) {
                char character = ks_str(&stripped)[offsets[1] + counter++];
                if (character == ' ') {
                    // puts(ks_str(&command_k_string));
                    break;
                }
                kputc(character, &command_k_string);
            }
            command_key_string = ks_str(&command_k_string);

            free(ks_release(&command_k_string));
             */
            strncpy(command_key_string, offset_pointer, len);


            int comp_result = regexec(&regex, command_key_string, 0, NULL, 0);

            if (comp_result == REG_NOMATCH) {
                invalidate_command(ret);
                free(command_key_string);
                // free(ks_release(&stripped));
                return ret;
            }

            offset_pointer = ks_str(&stripped) + offsets[2];
            len = ((int) ks_len(&stripped)) - offsets[2];
            char * command_value_string = strndup(offset_pointer, len);

            comp_result = regexec(&regex, command_value_string, 0, NULL, 0);

            if (comp_result == REG_NOMATCH) {
                invalidate_command(ret);
                free(command_key_string);
                free(command_value_string);
                // free(ks_release(&stripped));
                return ret;
            }

            kstring_t key = { 0, 0, NULL };
            kstring_t value = { 0, 0, NULL };
            kputs(command_key_string, &key);
            kputs(command_value_string, &value);
            free(command_key_string);
            free(command_value_string);
            ret->key = key;
            ret->value = value;
        } else {
            invalidate_command(ret);
            free(command_type_string);
            // free(ks_release(&stripped));
            return ret;
        }
    } else if (nums == 2) {
        int len = ((int) ks_len(&stripped)) - offsets[1];
        char *offset_pointer = ks_str(&stripped) + offsets[1];
        char *command_key_string = strndup(offset_pointer, len);

        int comp_result = regexec(&regex, command_key_string, 0, NULL, 0);

        if (comp_result == REG_NOMATCH) {
            invalidate_command(ret);
            free(command_type_string);
            free(command_key_string);
            // free(ks_release(&stripped));
            return ret;
        }

        kstring_t key = { 0, 0, NULL};
        kputs(command_key_string, &key);

        ret->key = key;

        if (strcmp(command_type_string, GET_STRING) == 0) {
            ret->kind = Get;
        } else if (strcmp(command_type_string, DEL_STRING) == 0) {
            ret->kind = Del;
        } else {
            invalidate_command(ret);
            free(ks_release(&ret->key));
            free(command_type_string);
            // free(ks_release(&stripped));
            return ret;
        }

        free(command_type_string);
    } else if (nums == 1) {

        if (strcmp(command_type_string, GET_COUNTER_STRING) == 0) {
            ret->kind = GetCounter;
        } else if (strcmp(command_type_string, SET_COUNTER_STRING) == 0) {
            ret->kind = SetCounter;
        } else if (strcmp(command_type_string, DEL_COUNTER_STRING) == 0) {
            ret->kind = DelCounter;
        }

        invalidate_command(ret);
        free(command_type_string);
    } else {
        free(command_type_string);
    }

    // free(ks_release(&stripped));
    return ret;
}

inline bool is_counter(struct CompleteCommand * command) {
    return (command->kind == GetCounter || command->kind == SetCounter || command->kind == DelCounter);
}