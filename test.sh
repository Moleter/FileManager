#!/bin/bash

source ./file_manager.sh

setup() {
  mkdir -p test_dir
  files=("test_dir")
  current_selection=0
  directory="$(pwd)"
}

cleanup() {
  [[ -d test_dir ]] && rm -r test_dir
}

test_delete_dict() {
  setup

  echo "Y" | delete_dict

  if [[ ! -d test_dir ]]; then
    echo "TEST PASSED: directory deleted"
  else
    echo "TEST FAILED: directory not deleted"
  fi

  cleanup
}

test_delete_dict
