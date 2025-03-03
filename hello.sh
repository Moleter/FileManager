#!/user/bin/bash

stty -echo -icanon time 0 min 0
clear

current_selection=0
directory="$(pwd)"
files=( $(ls -1) )

# Funkcja do rysowania ekranu
draw_screen() {
    clear
    tput cup 0 0
    echo "Aktualny katalog: $directory"
    
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
        "[A")
            ((current_selection > 0)) && ((current_selection--))
            ;;
        "[B")
            ((current_selection < ${#files[@]} - 1)) && ((current_selection++))
            ;;
        "q")
            break
            ;;
    esac
    draw_screen
done

stty echo icanon
tput cnorm  
clear
