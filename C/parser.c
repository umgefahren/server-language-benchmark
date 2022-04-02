//
// Created by Hannes Furmans on 01.04.22.
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <regex.h>

#include "parser.h"

regex_t regex;

void compile_regex() {
    regcomp(&regex, "[[:alnum:]]+", 0);
}

enum CommandType classify_command(char * token);

bool validate_string(char * token);

bool parse_time(char * string, struct tm * time_out) {
    strptime(string, "%Hh-%Mm-%Ss", time_out);
    if (time_out->tm_hour == 0 && time_out->tm_min == 0 && time_out->tm_sec == 0) {
        return false;
    }
    return true;
}

double convert_to_seconds(struct tm * time) {
    double ret = 0;
    ret += time->tm_sec;
    ret += time->tm_min * 60;
    ret += time->tm_hour * 60 * 60;
    return ret;
}

void remove_trailing(char * input) {
    input[strcspn(input, "\n")] = 0;
}

void invalidate_command(struct CompleteCommand * cmd) {
    cmd->type = Invalid;
}

struct CompleteCommand * parse(char * input) {
    struct CompleteCommand * ret = malloc(sizeof(struct CompleteCommand));

    remove_trailing(input);

    char * token = strtok(input, " ");

    unsigned char loop_count = 0;
    while (token != NULL) {
        if (loop_count == 0) {
            enum CommandType tmp_type = classify_command(token);
            if (tmp_type == Invalid) {
                invalidate_command(ret);
                return ret;
            }
            ret->type = tmp_type;
        } else if (loop_count == 1) {
            struct tm * parsed_time = malloc(sizeof(struct tm));
            bool parse_result = parse_time(token, parsed_time);
            if (!parse_result) {
                free(parsed_time);
                if (!validate_string(token)) {
                    invalidate_command(ret);
                    return ret;
                }
                ret->key = token;
            } else {
                ret->time = parsed_time;
            }
        } else if (loop_count == 2) {
            if (!validate_string(token)) {
                invalidate_command(ret);
                return ret;
            }
            ret->value = token;
            ret->value_len = strlen(token);
        } else if (loop_count == 3) {
            struct tm * parsed_time = malloc(sizeof(struct tm));
            bool time_result = parse_time(token, parsed_time);
            if (!time_result) {
                free(parsed_time);
                invalidate_command(ret);
                return ret;
            }
            ret->time = parsed_time;
        } else {
            invalidate_command(ret);
            return ret;
        }

        token = strtok(NULL, " ");
        loop_count++;
    }

    if (ret->type == Get && loop_count != 2) {
        invalidate_command(ret);
        return ret;
    } else if (ret->type == Set && loop_count != 3) {
        invalidate_command(ret);
        return ret;
    } else if (ret->type == Del && loop_count != 2) {
        invalidate_command(ret);
        return ret;
    } else if (ret->type == Get_Counter && loop_count != 1) {
        invalidate_command(ret);
        return ret;
    } else if (ret->type == Set_Counter && loop_count != 1) {
        invalidate_command(ret);
        return ret;
    } else if (ret->type == Del_Counter && loop_count != 1) {
        invalidate_command(ret);
        return ret;
    } else if (ret->type == Get_Dump && loop_count != 1) {
        invalidate_command(ret);
        return ret;
    } else if (ret->type == New_Dump && loop_count != 1) {
        invalidate_command(ret);
        return ret;
    } else if (ret->type == Dump_Interval && loop_count != 2) {
        invalidate_command(ret);
        return ret;
    } else if (ret->type == Set_TTL && loop_count != 4) {
        invalidate_command(ret);
        return ret;
    }

    return ret;
};

inline enum CommandType classify_command(char * token) {
    if (strcmp(token, GET_STRING) == 0)
        return Get;
    else if (strcmp(token, SET_STRING) == 0)
        return Set;
    else if (strcmp(token, DEL_STRING) == 0)
        return Del;
    else if (strcmp(token, GET_COUNTER_STRING) == 0)
        return Get_Counter;
    else if (strcmp(token, SET_COUNTER_STRING) == 0)
        return Set_Counter;
    else if (strcmp(token, DEL_COUNTER_STRING) == 0)
        return Del_Counter;
    else if (strcmp(token, GET_DUMP_STRING) == 0)
        return Get_Dump;
    else if (strcmp(token, NEW_DUMP_STRING) == 0)
        return New_Dump;
    else if (strcmp(token, DUMP_INTERVAL_STRING) == 0)
        return Dump_Interval;
    else if (strcmp(token, SET_TTL_STRING) == 0)
        return Set_TTL;
    else
        return Invalid;
}

inline bool validate_string(char * token) {
    int reti = regexec(&regex, token, 0, NULL, 0);
    if (reti)
        return true;
    else
        return false;
}

void complete_command_print(struct CompleteCommand * command) {
    if (command->type == Get) {
        printf("%s %s\n", GET_STRING, command->key);
    } else if (command->type == Set) {
        printf("%s %s %s\n", SET_STRING, command->key, command->value);
    } else if (command->type == Del) {
        printf("%s %s\n", DEL_STRING, command->key);
    } else if (command->type == Get_Counter) {
        printf("%s\n", GET_COUNTER_STRING);
    } else if (command->type == Set_Counter) {
        printf("%s\n", SET_COUNTER_STRING);
    } else if (command->type == Del_Counter) {
        printf("%s\n", DEL_COUNTER_STRING);
    } else if (command->type == Get_Dump) {
        printf("%s\n", GET_DUMP_STRING);
    } else if (command->type == New_Dump) {
        printf("%s\n", NEW_DUMP_STRING);
    } else if (command->type == Dump_Interval) {
        printf("%s %fs\n", DUMP_INTERVAL_STRING, convert_to_seconds(command->time));
    } else if (command->type == Set_TTL) {
        printf("%s %s %s %f\n", SET_TTL_STRING, command->key, command->value, convert_to_seconds(command->time));
    } else {
        printf("Command is invalid\n");
    }
};

