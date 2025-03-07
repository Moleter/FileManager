#!/bin/bash

stty -echo -icanon time 0 min 0
tput civis # cursor off

current_selection=0
directory="$(pwd)"
files=( $(ls) )
columns=$(tput cols)
left_width=$((columns / 2 - 2))
right_width=$((columns / 2 - 2))

draw_screen() {
    tput reset
    tput cup 0 0
    echo "$directory"
    
    for i in "${!files[@]}"; do
        tput cup $((i+2)) 2
        if [ "$i" -eq "$current_selection" ]; then
            tput rev 
            echo "> ${files[$i]}"
            tput sgr0 
        else
            echo "  ${files[$i]}"
        fi
    done

    count=0
    selected_item="${files[$current_selection]}"
    if [ -d "$directory/$selected_item" ]; then
        subfiles=( $(ls "$directory/$selected_item") )
        tput cup 0 $((left_width + 4))
        echo "Zawartość: $slected_item"
        for j in "${!subfiles[@]}"; do
            tput cup $((j+2)) $((left_width +4))
            echo " ${subfiles[$j]}"

            ((count++))
            if [ "$count" -ge 10 ]; then
                tput cup $((j+2)) $((left_width +4))
                break
            fi
        done
    fi
    
    tput cup $(( ${#files[@]} + 4 )) 0
    echo "Strzałki: Nawigacja | Enter: Otwórz | q: Wyjście"
}

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
            selected_item="${files[$current_selection]}"
            if [ -d "$directory/$selected_item" ]; then
                directory="$directory/$selected_item"
                files=( $(ls "$directory") )
                current_selection=0
            fi
            ;;
        "[D") #left
            directory="$(dirname "$directory")"
            files=( $(ls "$directory") )
            current_selection=0
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

