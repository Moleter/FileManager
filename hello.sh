#!/bin/bash

stty -echo -icanon time 0 min 0
tput civis # cursor off

#variables
current_selection=0
directory="$(pwd)"
files=()
columns=$(tput cols)
left_width=$((columns / 2 - 2))
right_width=$((columns / 2 - 2))
max_display=10 #side files in list_side_files function
files_to_move=()
message="Helo in simple file comander in bash!"

#functions

read_files() {
  files=()
  while IFS= read -r file; do
    files+=("$file")
  done < <(ls -1 "$directory")
}

list_main_files() {
  tput reset
  tput cup 0 0
  echo "$directory"

  read_files
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
  local subfiles=()
  local selected_item="${files[$current_selection]}"

  if [ -d "$directory/$selected_item" ]; then

    while IFS= read -r subfile; do
      subfiles+=("$subfile")
    done < <(ls -1 "$directory/$selected_item")

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
  echo "Strzałki: Nawigacja | d: usuń | c: zmień nazwę | m: przenieś | q: Wyjście"

  tput cup $((${#files[@]} + 6)) 0
  echo "$message"
}

enter_directory() {
  selected_item="${files[$current_selection]}"
  if [ -d "$directory/$selected_item" ]; then
    directory="$directory/$selected_item"
    read_files
    current_selection=0
  fi
}

go_back() {
  directory="$(dirname "$directory")"
  read_files
  current_selection=0
}

delate_file() {
  selected_item="${files[$current_selection]}"

  if [ ! -e "$directory/$selected_item" ]; then
    message="Error: File dosen't exist"
    return
  fi

  read -p "Are you sure aboute delete file \"$selected_item\"? (Y/n): " confirm
  if [[ "$confirm" != "Y" ]]; then
    message="Delete canceled"
    return
  fi

  rm -- "$directory/$selected_item"
  message="File deleted"
  read_files
}

change_file_name() {
  selected_item="${files[$current_selection]}"

  read -p "Are you want change name of fle \"$selected_item\" (Y/n): " confirm
  if [[ "$confirm" != "Y" ]]; then
    message="Change name canceled"
    return
  fi

  read -p "Enter new name of file: " new_name

  if [[ -z "$new_name" ]]; then
    message="Error! No new name provided!"
    return
  fi

  mv -- "$directory/$selected_item" "$directory/$new_name"
  message="File renemed"

  read_files
}

move_file() {
  selected_item="${files[$current_selection]}"

  if [ ! -e "$directory/$selected_item" ]; then
    message="Error: File does not exist"
    return
  fi

  read -p "Enter new directory for the file: $(pwd)/" target_directory

  if [ ! -d "$target_directory" ]; then
    message="Error: Target directory does not exist"
    return
  fi

  mv "$directory/$selected_item" "$target_directory" >>debug.txt 2>&1

  if [ $? -eq 0 ]; then
    message="File \"$selected_item\" moved to \"$target_directory\"."
  else
    message="Error: Operation failed"
  fi

  read_files
}

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
  "c") #change_file_name
    change_file_name
    ;;
  "m")
    move_file
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
