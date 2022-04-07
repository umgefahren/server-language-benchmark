cmake_minimum_required(VERSION 3.18)
project(C_new C)

set(CMAKE_C_STANDARD 11)

include(CTest)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

add_library(string klib/kstring.h klib/kstring.c)

add_library(command command.c command.h)

add_library(store store.c store.h)

add_library(server server.c server.h)

add_executable(C_new main.c)

target_link_libraries(command string)
target_link_libraries(store command Threads::Threads)
target_link_libraries(server store command Threads::Threads)
target_link_libraries(C_new command store server)

add_executable(command_test command_test.c)
target_link_libraries(command_test string command store)

add_executable(store_test store_test.c)
target_link_libraries(store_test store string)

add_test(NAME command_test COMMAND command_test)
set_tests_properties(command_test PROPERTIES FAIL_REGULAR_EXPRESSION "ERROR")

add_test(NAME store_test COMMAND store_test)

