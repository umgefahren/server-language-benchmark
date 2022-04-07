//
// Created by Hannes Furmans on 07.04.22.
//

#ifndef C_NEW_SERVER_H
#define C_NEW_SERVER_H

#include <stdio.h>

#include "store.h"

int server_init();

int server_loop(int server_fd, struct Store * store);

#endif //C_NEW_SERVER_H
