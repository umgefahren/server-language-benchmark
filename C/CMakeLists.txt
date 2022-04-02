cmake_minimum_required(VERSION 3.21)
project(server_bench C)

set(CMAKE_C_STANDARD 17)

add_library(c_hash_map c_hash_map.c c_hash_map.h klib/khash.h)

add_library(store store.c store.h)

target_link_libraries(store c_hash_map)

add_library(server server.c server.h)

add_library(parser parser.c parser.h)

add_executable(server_bench main.c)

target_link_libraries(server_bench store server parser)
