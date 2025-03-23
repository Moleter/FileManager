#!/bin/bash

stty -echo -icanon time 0 min 0
tput civis # cursor off

#variables
current_selection=0
directory="$(pwd)"
files=($(ls))
columns=$(tput cols)
left_width=$((columns / 2 - 2))
right_width=$((columns / 2 - 2))
max_display=10 #side files in list_side_files function

#functions
list_main_files() {
  tput reset
  tput cup 0 0
  echo "$directory"

  local total_files=${#files[@]}

  if ((current_selection < scroll_offset)); then
    scroll_offset=$current_selection
  elif ((current_selection >= scroll_offset + max_display)); then
    scroll_offset=$((current_selection - max_display + 1))
  fi

  for ((i = 0; i < max_display; i++)); do
    index=$((scroll_offset + i))
    [ "$index" -ge "$total_files" ] && break

    tput cup $((i + 2)) 2
    if [ "$index" -eq "$current_selection" ]; then
      tput rev
      echo "> ${files[$index]}"
      tput sgr0
    else
      echo "  ${files[$index]}"
    fi
  done

  if ((scroll_offset + max_display < total_files)); then
    tput cup $((max_display + 2)) 2
    echo " ↓"
  fi

}

list_side_files() {
  local count=0
  local selected_item="${files[$current_selection]}"

  if [ -d "$directory/$selected_item" ]; then
    local subfiles=($(ls "$directory/$selected_item"))
    tput cup 0 $((left_width + 4))
    echo "Zawartość: $slected_item"
    for j in "${!subfiles[@]}"; do
      tput cup $((j + 2)) $((left_width + 4))
      echo " ${subfiles[$j]}"

      ((count++))
      if [ "$count" -ge $max_display ]; then
        break
      fi
    done
  fi

  if [ "${#subfiles[@]}" -gt "$max_display" ]; then
    tput cup $((j + 3)) $((left_width + 4))
    echo " ..."
  fi

}

draw_screen() {
  list_main_files
  list_side_files

  tput cup $((${#files[@]} + 4)) 0
  echo "Strzałki: Nawigacja | d: usuń | ?: zmień nazwę | ?: przenieś | q: Wyjście"
}

enter_directory() {
  selected_item="${files[$current_selection]}"
  if [ -d "$directory/$selected_item" ]; then
    directory="$directory/$selected_item"
    files=($(ls "$directory"))
    current_selection=0
  fi
}

go_back() {
  directory="$(dirname "$directory")"
  files=($(ls "$directory"))
  current_selection=0
}

delate_file() {
  selected_item="${files[$current_selection]}"
  rm "$directory/$selected_item"
  files=($(ls "$directory"))
}

# change_file_name() {
#
# }

# move_file() {
#
# }

# main

draw_screen

while true; do
  read -rsn1 key

  if [[ "$key" == $'\x1b' ]]; then
    read -rsn2 key
  fi

  case "$key" in
  "[A") # up
    ((current_selection > 0)) && ((current_selection--))
    ;;
  "[B") # down
    ((current_selection < ${#files[@]} - 1)) && ((current_selection++))
    ;;
  "[C") # right
    enter_directory
    ;;
  "[D") #left
    go_back
    ;;
  "d") #delete file
    delate_file
    ;;
  "q") # quite
    break
    ;;
  esac
  draw_screen
done

clear
stty echo icanon
tput cnorm
