#!/bin/bash

stty -echo -icanon time 0 min 0
tput civis # cursor off

#variables
current_selection=0
directory="$(pwd)"
files=()
columns=$(tput cols)
width=$((columns / 2 - 2))
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

    tput cup 0 $((width + 4))
    echo "Zawartość: $selected_item"
    for j in "${!subfiles[@]}"; do
      tput cup $((j + 2)) $((width + 4))
      echo " ${subfiles[$j]}"

      ((count++))
      if [ "$count" -ge $max_display ]; then
        break
      fi
    done
  fi

  if [ "${#subfiles[@]}" -gt "$max_display" ]; then
    tput cup $((j + 3)) $((width + 4))
    echo " ..."
  fi

}

draw_screen() {
  list_main_files
  list_side_files

  tput cup 12 0
  echo "Arrows: Navigation | d: Delate | c: Change name | m: Move file | q: Quit | a: Add file to list | X: Delate dictionery"

  tput cup 14 0
  echo "$message"

  tput cup 16 0
  echo "Zawartość listy do przeniesienia:"
  for f in "${files_to_move[@]}"; do
    echo "→ $f"
  done
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

delate_file() { #d
  selected_item="${files[$current_selection]}"

  if [ ! -e "$directory/$selected_item" ]; then
    message="Error: File dosen't exist"
    return
  fi

  if [ -d "$directory/$selected_item" ]; then
    message="Error: Can not delate directory, use \"X\""
    return
  fi

  read -rp "Are you sure aboute delete file \"$selected_item\"? (Y/n): " confirm
  if [[ "$confirm" != "Y" ]]; then
    message="Delete canceled"
    return
  fi

  rm -- "$directory/$selected_item"
  message="File deleted"
  read_files
}

change_file_name() { #r
  selected_item="${files[$current_selection]}"

  read -rp "Are you want change name of fle \"$selected_item\" (Y/n): " confirm
  if [[ "$confirm" != "Y" ]]; then
    message="Change name canceled"
    return
  fi

  read -rp "Enter new name of file: " new_name

  if [[ -z "$new_name" ]]; then
    message="Error! No new name provided!"
    return
  fi

  mv -- "$directory/$selected_item" "$directory/$new_name"
  message="File renemed"

  read_files
}

move_file() { #e
  selected_item="${files[$current_selection]}"

  if [[ ! -e "$directory/$selected_item" ]]; then
    message="Error: File does not exist"
    return
  fi

  read -rp "Enter new directory for the file: $(pwd)/" target_directory

  if [[ ! -d "$target_directory" ]]; then
    message="Error: Target directory does not exist"
    return
  fi

  if [[ $? -eq 0 ]]; then
    message="File \"$selected_item\" moved to \"$target_directory\"."
  else
    message="Error: Operation failed"
  fi

  read_files
}

add_file_to_list() { #a
  selected_item="${files[$current_selection]}"
  if [ ! -e "$directory/$selected_item" ]; then
    message="File soes not exist"
    return
  fi

  files_to_move+=("$directory/$selected_item")
  message="File added to list"
}

clear_files_from_list() { #c
  read -rp "Are you sure to clear files list? (Y/n): " confirm

  if [[ "$confirm" != "Y" ]]; then
    return
  fi

  message="Files form list clered"
  files_to_move=()
}

delete_files_from_list() { #D
  read -rp "Are you sure to delete files from list? (Y/n): " confirm

  if [[ "$confirm" != "Y" ]]; then
    return
  fi

  for file in files_to_move[@]; do
    rm -- file
  done

  message="Files form list deleted"
  files_to_move=()
}

delete_dict() { #X
  selected_item=${files[$current_selection]}

  if [ ! -e "$directory/$selected_item" ]; then
    message="Dict does not exist"
    return
  fi

  if [ ! -d "$directory/$selected_item" ]; then
    message="Error: Cannot delate file with this function - use \"d\""
    return
  fi

  read -rp "Are you sure to dalate dictionery with evrything that it contains \"$directory/$selected_item\"? (Y/n): " confirm

  if [ "$confirm" != Y ]; then
    message="Operation canceled"
    return
  fi

  rm -r "$directory/$selected_item"
  message="directory deleted"
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
  "r") #change_file_name
    change_file_name
    ;;
  "m")
    move_file
    ;;
  "q") # quite
    break
    ;;
  "a")
    add_file_to_list
    ;;
  "c")
    clear_files_from_list
    ;;
  "D")
    delete_files_from_list
    ;;
  "X")
    delete_dict
    ;;
  esac
  draw_screen
done

clear
stty echo icanon
tput cnorm
