#/bin/bash
clang -framework IOKit -framework Foundation -framework ApplicationServices -o HIDToKey HIDToKey.m
