#!/bin/bash

#----------------------------------------------------
NOTES=~/instantos/notes
EDITOR=~/.config/instantos/default/editor
#----------------------------------------------------

[ -d $NOTES ] || mkdir $NOTES
cd $NOTES

maketodo() {
    for TASK in *; do

        if grep -q "\.note$" <<< $TASK; then
            TASK=":g [ ] ${TASK:: -5}"
            DO=$DO$TASK'\n'

        elif grep -q "\.done$" <<< $TASK; then
            TASK=":r [X] ${TASK:: -5}"
            DONE=$DONE$TASK'\n'
        
        elif [ -d "$TASK" ]; then
            TASK=":y $TASK"
            FOLDERS=$FOLDERS$TASK'\n'
        fi

    done
    
    START_FILL=$(ls | wc -l)
    START_FILL=$((START_FILL-$3))
    END_FILL=0

    if [ $# -gt 1 ] && [ $2 -eq 0 ]; then
        OUT=$DO$DONE
        START_FILL=$((START_FILL-$(ls -d */ | wc -l)))
    else
        OUT=$FOLDERS$DO$DONE
    fi

    if [ $START_FILL -lt 0 ]; then
        END_FILL=$(echo ${START_FILL#-})
        START_FILL=0
    fi
    
    for (( c=0; c < $START_FILL; c++ )); do
        TEMP=$TEMP">\n"
    done

    OUT=$1$TEMP$OUT

    for (( c = 0; c != $END_FILL; c++ )); do
        OUT=$OUT">\n"
    done

    echo -e "${OUT::-2}"
}

cleanselected() {
    TEMP=$1

    if grep -q "^:g \[ \]" <<< $TASK; then
        TEMP="${TEMP:7}"
        echo -e "$TEMP.note"

    elif grep -q "^:r \[X\]" <<< $TASK; then
        TEMP="${TEMP:7}"
        echo -e "$TEMP.done"
    
    elif grep -q "^:y " <<< $TASK; then
        echo -e "$TEMP"

    else
        echo -e "${TEMP:4}"
    fi
}

reversesuffix() {
    if [ "$1" == ".note" ]; then
        echo -e ".done"
    elif [ "$1" == ".done" ]; then
        echo -e ".note"
    fi
}

EXIT=false
SUBDIR=false

while [ "$TASK" != "Ok" ]; do
    
    if ! $SUBDIR; then
        TASK="$( maketodo ":y Options\n:b Ok\n" 1 2 \
        | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i -g 2 )"
    else
        TASK="$( maketodo ":y Options\n:r Back\n:b Ok\n" 1 3 \
        | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i -g 2 )"
    fi

    if [ "$TASK" == "" ]; then
        EXIT=true
    fi

    TASK="$( cleanselected "$TASK" )"
    SUFFIX="${TASK: -5}"

    if [ "${TASK: -5:1}" == "." ]; then
        TASK="${TASK:: -5}"
        cp "$TASK$SUFFIX" "$TASK$(reversesuffix $SUFFIX)"
        rm "$TASK$SUFFIX"

    elif grep -q "^:y " <<< $TASK; then
        cd "${TASK:4}"
        SUBDIR=true

    elif [ "$TASK" == "Back" ]; then
        cd ..
        if [ "$(pwd)" == "$NOTES" ]; then
            SUBDIR=false
        fi
    fi

    if [ "$TASK" == "Options" ]; then

        TASK="$( echo -e ":g Add\n:r Delete\n:b Open\n:y Rename\n:g Clear Done\n:r Back" \
        | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i )"

        TASK="$( cleanselected "$TASK" )"

        case "$TASK" in
            "Add")
                TASK="$( echo -e ":b Note\n:y Folder\n:r Back" \
                | instantmenu -w 150 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i )"
                
                TASK="$( cleanselected "$TASK" )"

                case "$TASK" in
                    "Note")
                        NAME="$( imenu -i 'Note' )"
                        if [ -z "$NAME" ] || [ "${NAME: :1}" == "." ]; then
                            notify-send "Please follow file naming rules when creating notes"
                        else
                            touch "$NAME.note"
                        fi
                        ;;
                    
                    *"Folder")
                        NAME="$( imenu -i 'Folder' )"
                        if [ -z "$NAME" ] || [ "${NAME: :1}" == "." ]; then
                            notify-send "Please follow folder naming rules when creating folders"
                        else
                            mkdir "$NAME"
                        fi
                        ;;
                esac
                ;;

            "Delete")

                TASK="$( maketodo ":r Back\n" 1 1 \
                | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i -g 2 )"

                TASK="$( cleanselected "$TASK" )"
                
                if [ "${TASK: -5:1}" == "." ]; then
                    rm "$TASK"

                elif grep -q "^:y " <<< $TASK; then
                    rm -rf "${TASK:4}"
                fi
                ;;

            "Open")

                TASK="$( maketodo ":r Back\n" 0 1\
                | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i -g 2 )"
                
                TASK="$( cleanselected "$TASK" )"

                if [ "${TASK: -5:1}" == "." ]; then
                    exec $EDITOR $(pwd)/"$TASK"
                fi
                ;;

            "Rename")

                TASK="$( maketodo ":r Back\n" 1 1 \
                | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i -g 2 )"

                TASK="$( cleanselected "$TASK" )"
                SUFFIX="${TASK: -5}"

                if [ "${TASK: -5:1}" == "." ]; then
                    TASK="${TASK:: -5}"

                    NAME="$( imenu -i "Rename" -it "$TASK" )"

                    if [ "$NAME" != "" ]; then
                        mv "$TASK$SUFFIX" "$NAME$SUFFIX"
                    fi

                elif grep -q "^:y " <<< $TASK; then
                    TASK=${TASK:4}

                    NAME="$( imenu -i "Rename" -it "$TASK" )"

                    if [ "$NAME" != "" ]; then
                        mv "$TASK" "$NAME"
                    fi
                fi
                ;;

            "Clear Done")

                rm *.done
                ;;

        esac

    fi

    if $EXIT; then
        exit
    fi

done
