//
// Created by Hannes Furmans on 01.04.22.
//

#ifndef SERVER_BENCH_PARSER_H
#define SERVER_BENCH_PARSER_H

#define GET_STRING "GET"
#define SET_STRING "SET"
#define DEL_STRING "DEL"
#define GET_COUNTER_STRING "GETC"
#define SET_COUNTER_STRING "SETC"
#define DEL_COUNTER_STRING "DELC"

enum CommandType {
    Get,
    Set,
    Del,
    Get_Counter,
    Set_Counter,
    Del_Counter,
    Invalid
};

struct CompleteCommand {
    enum CommandType type;
    char * key;
    char * value;
    unsigned int value_len;
};

struct CompleteCommand * parse(char * input);

void complete_command_print(struct CompleteCommand * command);

void compile_regex();

#endif //SERVER_BENCH_PARSER_H
