cmake_minimum_required(VERSION 3.4.1)

add_library(
        wed1
        SHARED
        src/main/jni/wed1.c
)

add_library(
        wed2
        SHARED
        src/main/jni/wed2.c
)
