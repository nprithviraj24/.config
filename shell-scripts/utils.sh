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
    echo "Maximum size :  200mb "
    
    if [[ -z $3  && -z $4 ]] 
    then
	    while inotifywait -r -e modify,create,delete,move $(pwd); do
		rsync -avz --max-size=200m "$(pwd)""/"  "$1" 
	    done
    fi
    if [ ! -z "$3" ] && [ ! -z "$4" ] $$ [ "$3" == "--ignore" ]
    then
	    while inotifywait -r -e modify,create,delete,move $(pwd); do
		rsync -avz --exclude="$4" "$(pwd)""/"  "$1" 
	    done
    else
	    echo "Usage syncRemote:abc:~/asdf --ignore *.pt"
    fi

} 
