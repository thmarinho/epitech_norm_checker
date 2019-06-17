#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
GRAY='\033[0;37m'
NC='\033[0m'            # No Color
HEADER_REGEXP='^/\*\036\*\* EPITECH PROJECT, (20(1[7-9]|[2-9]\d)|2[1-9]\d{2}|[3-9]\d{3})\036\*\* [^\036]+\036\*\* File description:\036\*\* [^\036]+\036\*/\036\036'

header_format()
{
    local file=$1

    if !(head -n 7 $file | tr '\n' '\036' | grep -qP "$HEADER_REGEXP") 2> /dev/null; then
        echo -ne "${RED}Major\t${NC}: "
        echo -ne "$file" | sed 's/^..//'
        echo -e ": $line: Missing or corrupted header"
    fi
}

line_length()
{
    local file=$1
    local line=1

    while read tmp; do
        local length=${#tmp}
        if (( $length > 80 )); then
            echo -ne "${RED}Major\t${NC}: "
            echo -ne "$file" | sed 's/^..//'
            echo -e ": $line: Too long line ($length > 80)"
        fi
        ((line++))
    done < $file
}

trailing_spaces()
{
    local file=$1
    local line=1

    while IFS= read -r tmp; do
        echo -e "$tmp" | grep " $" > /dev/null
        if (($? == 0)); then
            echo -ne "${GRAY}Implicit${NC}: "
            echo -n "$file" | sed 's/^..//'
            echo -e ": $line: Trailing space"
        fi
        ((line++))
    done < $file
}

useless_files()
{
    local extentions=( ".*.swp" "*.o" "*~" "*.gch" ".vscode*" )

    for extention in ${extentions[@]}; do
	    local tmp=$(find -type f -name $extention)
	    local length=${#tmp}
	    if (( length != 0 )); then
	        for i in $tmp; do
	            echo -ne "${RED}Major\t${NC}: "
	            echo -n "$i" | sed 's/^.\{2\}//'
	            echo -e ": Useless file"
	        done
	    fi
    done

}

functions_separator()
{
    local file=$1
    local line=1

    while IFS= read -r tmp; do
        if [[ ${tmp::1} == "}" ]]; then
            local next_line=$(sed "$((line + 1))q;d" $file)
            if ((  ${#next_line}  != 0 )); then
                echo -ne "${GREEN}Minor\t${NC}: "
                echo -n "$file" | sed 's/^..//'
                echo -e ": $((line + 1)): Missing empty line between functions"
            fi
        fi
        ((line++))
    done < $file
}

identation()
{
    local file=$1
    local line=1

    while IFS= read -r tmp; do
        local trimed_str=$(echo -e $tmp | sed "s/^[ \t]*//")
        local removed_spaces=$(( ${#tmp} - ${#trimed_str} ))
        if (( removed_spaces % 4 != 0 )); then
            echo -ne "${GREEN}Minor\t${NC}: "
            echo -n "$file" | sed 's/^..//'
            echo -e ": $((line)): Bad indentation"
        fi
        ((line++))
    done < $file
}

files=$(find -type f -name "*.c")

for file in $files; do
    header_format $file
    line_length $file           # Major
    trailing_spaces $file       # Implicit
    functions_separator $file   # Minor
    identation $file            # Minor
done
useless_files $files            # Major
