#!/bin/bash

createFiles() {
    local dir_name="$1"
    mkdir "test/$dir_name"

    for file in file{0..9}.txt; do
        touch "test/$dir_name/$file"
    done
}

createFiles Lvl0
createFiles Lvl1