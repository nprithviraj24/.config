#!/bin/bash
printthis(){
    echo "$1"
}

generateqr (){

    printf "$@" | curl -F-=\<- qrenco.de
}


# Make sure remote desktop has rsync 
syncRemote() {
    clear_vars() {
            unset SYNC_DESTINATION
            unset TEMP_VAR
            unset SYNC_SOURCE
    }
    usage(){
        echo 'usage: syncRemote --src /your/path --dst /your/dest/path --ignore "*.pt"  --max-size 200m'
    }

    clear_vars
    sync_MAX_SIZE=200m

# ` symbol- command substitution. The `command` construct makes available the output of command for assignment to a variable. 
# This is also known as backquotes or backticks.
    TEMP_VAR=`getopt -o d:s:, --long dst:,src:,max-size:,ignore: -- "$@"`
    eval set -- "$TEMP_VAR"
    echo $TEMP_VAR
    # echo $?

    while true; do
        case "$1" in
            --src)
                case "$2" in
                    "--"* ) 
                        # echo " Source is empty "
                        # clear_vars
                        # return 1;; 
                        shift 2;;
                    "") 
                        # echo " Source cannot be empty " 
                        # clear_vars
                        # return 1;; 
                        shift 2;;
                    *)
                        SYNC_SOURCE=$2                    
                        # echo "Source 2:  ""$2"; 
                        shift 2;;
                esac ;;

            --dst)
                case "$2" in
                    # "") echo "This is some val "; shift 1 ;;
                    "--"* ) 
                        echo "Destination cannot be empty ";
                        echo "Source 2:  ""$2"; 
                        clear_vars
                        return 1;; #shift 1 ;;
                    "")
                        echo "Destination cannot be empty ";
                        echo "Source 2:  ""$2"; 
                        clear_vars
                        return 1;; #shift 1 ;;
                    *) 
                        SYNC_DESTINATION=$2
                        # echo "Dest: ""$2";
                        shift 2;;
                esac ;;

            --max-size)
                case "$2" in
                    "--"* ) 
                        echo " Using default max-size: ""$sync_MAX_SIZE"
                        echo $TEMP_VAR;
                        shift 1;;
                    "") 
                        echo " Using default max-size: ""$sync_MAX_SIZE"
                        echo $TEMP_VAR;
                        shift 1;;
                    *)
                        sync_MAX_SIZE=$2                    
                        shift 2;;
                esac ;;

            # --ignore)
            #     case "$2" in
            #         "--"* ) 
            #             echo "Empty field for --ignore"
            #             usage
            #             clear_vars
            #             return 1;;
            #         "") 
            #             echo "Empty field for --ignore"
            #             usage
            #             clear_vars
            #             return 1;;
            #         *)
            #             sync_IGNORE=$2                    
            #             shift 2;;
            #     esac ;;

            --) shift ; break ;;
            *) 
                echo "Unknown Options: ""$@" ; 
                # break ;
                return 1;;
                #exit 1 ;;
        esac
    done

    if [ -z "$SYNC_DESTINATION" ]
    then
        echo "Destination cannot be empty!!"
        clear_vars
        return 1
    fi

    if [ -z "$SYNC_SOURCE" ]
    then
        echo "Source is Empty, using ""$(pwd)"" as source."
        $SYNC_SOURCE=$(pwd)
        # clear_vars
        # return 1
    fi

    echo 'Watches established in folder -->' "$SYNC_SOURCE"
    echo "Maximum size : ""$sync_MAX_SIZE"

    while inotifywait -r -e modify,create,delete,move $SYNC_SOURCE; do
        rsync -avz --max-size="$sync_MAX_SIZE" "$SYNC_SOURCE""/"  "$SYNC_DESTINATION" 
    done

} 
