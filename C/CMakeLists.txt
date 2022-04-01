cmake_minimum_required(VERSION 3.21)
project(server_bench C)

set(CMAKE_C_STANDARD 17)

add_library(c_hash_map c_hash_map.c c_hash_map.h khash.h)

add_library(server server.c server.h)

add_executable(server_bench main.c)

target_link_libraries(server_bench c_hash_map server)
