#!/bin/bash

#----------------------------------------------------
NOTES=~/instantos/notes
EDITOR=~/.config/instantos/default/editor
#----------------------------------------------------

if ! [ -d $NOTES ]; then
    mkdir $NOTES
fi
cd $NOTES

maketodo() {
    for TASK in *; do

        if grep -q "\.note$" <<< $TASK; then
            TASK=":g [ ] ${TASK:: -5}"
            DO=$DO$TASK'\n'

        elif grep -q "\.done$" <<< $TASK; then
            TASK=":r [X] ${TASK:: -5}"
            DONE=$DONE$TASK'\n'
        fi

    done

    OUT=$1$DO$DONE
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


while [ "$TASK" != "Ok" ]; do

    TASK="$( maketodo ":y Options\n:b Ok\n" \
    | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i )"
    
    EXIT=false
    if [ "$TASK" == "" ]; then
        EXIT=true
    fi

    TASK="$( cleanselected "$TASK" )"
    SUFFIX="${TASK: -5}"

    if [ "${TASK: -5:1}" == "." ]; then
        TASK="${TASK:: -5}"
        cp "$TASK$SUFFIX" "$TASK$(reversesuffix $SUFFIX)"
        rm "$TASK$SUFFIX"
    fi

    if [ "$TASK" == "Options" ]; then

        TASK="$( echo -e ":g Add\n:r Remove\n:b Open\n:y Rename\n:g Clear Done\n:r Back" \
        | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i )"

        TASK="$( cleanselected "$TASK" )"

        case "$TASK" in
            "Add")

                NAME="$(imenu -i 'Note')"
                if ! touch "$NAME.note"; then
                    notify-send "Please follow file naming rules when creating notes"
                fi
                ;;

            "Remove")

                TASK="$( maketodo ":r Back\n" \
                | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i )"

                TASK="$( cleanselected "$TASK" )"
                
                if [ "${TASK: -5:1}" == "." ]; then
                    rm "$TASK"
                fi
                ;;

            "Open")

                TASK="$( maketodo ":r Back\n" \
                | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i )"
                
                TASK="$( cleanselected "$TASK" )"

                if [ "${TASK: -5:1}" == "." ]; then
                    exec $EDITOR $(pwd)/"$TASK"
                fi
                ;;

            "Rename")

                TASK="$( maketodo ":r Back\n" \
                | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' -i )"

                TASK="$( cleanselected "$TASK" )"
                SUFFIX="${TASK: -5}"

                if [ "${TASK: -5:1}" == "." ]; then
                    TASK="${TASK:: -5}"

                    NAME="$(imenu -i "Rename" -it "$TASK" )"

                    if [ "$NAME" != "" ]; then
                        mv "$TASK$SUFFIX" "$NAME$SUFFIX"
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
