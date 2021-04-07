#!/bin/bash

if ! [ -d ~/instantos/notes ]; then
    mkdir ~/instantos/notes
fi
cd ~/instantos/notes

maketodo() {
    for task in $(ls -N); do

        if grep -q "\.do$" <<< $task; then
            task=$TEMP$task
            task=":g [ ] $(sed "s/\.do//" <<< $task)"
            DO=$DO$task'\n'
            if [ "$TASK" != "" ]; then TEMP=""; fi

        elif grep -q "\.done$" <<< $task; then
            task=$TEMP$task
            task=":r [x] $(sed "s/\.done//" <<< $task)"
            DONE=$DONE$task'\n'
            if [ "$TASK" != "" ]; then TEMP=""; fi

        else
            TEMP=$TEMP$task' '
        fi

    done

    OUT=$1$DO$DONE
    OUT=${OUT::-2}
    echo -e $OUT
}

while [ "$TASK" != ":r Ok" ]; do

    TASK="$( maketodo ":g Options\n:r Ok\n" \
    | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' )"

    if grep -q ":g \[ \] ." <<< $TASK; then
        TASK="$(sed "s/:g \[ \] //" <<< $TASK)"
        cp "$TASK.do" "$TASK.done"
        rm "$TASK.do"

    elif grep -q ":r \[x\] ." <<< $TASK; then
        TASK="$(sed "s/:r \[x\] //" <<< $TASK)"
        cp "$TASK.done" "$TASK.do"
        rm "$TASK.done"
    fi

    if [ "$TASK" == ":g Options" ]; then

        TASK="$( echo -e ":y Open\n:g Add\n:r Remove\n:g Clear Done\n:r Back" \
        | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' )"

        case "$TASK" in
            ":y Open")

                TASK="$( maketodo "" \
                | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' )"

                if grep -q ":g \[ \] ." <<< $TASK; then
                    TASK="$(sed "s/:g \[ \] //" <<< $TASK)"
                    exec ~/.config/instantos/default/editor $(pwd)/"$TASK.do"

                elif grep -q ":r \[x\] ." <<< $TASK; then
                    TASK="$(sed "s/:r \[x\] //" <<< $TASK)"
                    exec ~/.config/instantos/default/editor $(pwd)/"$TASK.done"
                fi
                ;;

            ":g Add")

                NAME="$(imenu -i 'Note')"
                touch "$NAME.do"
                ;;

            ":r Remove")

                TASK="$( maketodo "" \
                | instantmenu -w -1 -h -1 -c -l 20 -bw 3 -q 'instantNOTES' )"

                if grep -q ":g \[ \] ." <<< $TASK; then
                    TASK="$(sed "s/:g \[ \] //" <<< $TASK)"
                    rm "$TASK.do"

                elif grep -q ":r \[x\] ." <<< $TASK; then
                    TASK="$(sed "s/:r \[x\] //" <<< $TASK)"
                    rm "$TASK.done"
                fi
                ;;

            ":g Clear Done")

                rm *.done
                ;;

        esac

    fi

done
