#!/bin/bash
printthis(){
    echo "$1"
}

generateqr (){

    printf "$@" | curl -F-=\<- qrenco.de
}

# Make sure remote desktop has rsync 
syncRemote() {
    echo 'Watched established in folder -->' "$(pwd)"
    while inotifywait -r -e modify,create,delete,move $(pwd); do
        rsync -avz "$(pwd)""/"  "$1" 
    done
} 