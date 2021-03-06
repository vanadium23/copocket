#!/bin/bash
#-------------------------------------------------------
CONSUMER_KEY="32888-4ce66c1f7828c8de8cf68db1"
#-------------------------------------------------------
if [ ! -f access_token.txt ]; then
    CODE=`curl -s -H "Content-Type: application/json" -X POST -d '{"consumer_key":"'$CONSUMER_KEY'","redirect_uri":"void:ok"}' https://getpocket.com/v3/oauth/request`
    CODE=`echo $CODE|cut -c 6-`
    URL="https://getpocket.com/auth/authorize?request_token=$CODE&redirect_uri=https://gist.github.com/vanadium23/5186f0e8b6cd9e2d14b9"
    if which xdg-open > /dev/null; then
        xdg-open "$URL"
    elif which gnome-open > /dev/null; then
        gnome-open "$URL"
    else
        echo "Can't find browser. Please, go to following url:"
        echo "$URL"
    fi
    echo "Press enter when you have authorized the application."
    read null
    ACCESS_TOKEN=`curl -H "Content-Type: application/json" -X POST -d '{"consumer_key":"'$CONSUMER_KEY'","code":"'$CODE'"}' https://getpocket.com/v3/oauth/authorize`
    echo "$ACCESS_TOKEN" | sed 's/access_token=\(.*\)&username=\(.*\)/\1/g' > access_token.txt
    echo "Saved your access_token"
    exit
fi
ACCESS_TOKEN=$(<access_token.txt)

function print_help {
    echo -e "Welcome to copocket"
    echo -e "List of availible commands:"
    echo -e "\t count [article|image|video] - view count of items in your pocket"
    echo -e "\t add url - add item to your pocket"
    echo -e "\t view [article|image|video] - view table of items"
}

function retrieve {
    local DATA='{"consumer_key":"'$CONSUMER_KEY'","access_token": "'$ACCESS_TOKEN'"'
    TYPE='item'
    case $1 in
        article|image|video )
            DATA="$DATA,\"contentType\":\"$1\""
            TYPE="$1"
            ;;
    esac
    DATA="$DATA}"
    LIST=`curl -s -H "Content-Type: application/json" -X POST -d "$DATA" https://getpocket.com/v3/get`
}

function items_count {
    retrieve $1
    if which jq > /dev/null; then
        local COUNT=`echo $LIST | jq '.list | length'`
    else
        local COUNT=`echo $LIST | tr ',' '\n' | grep -c -o 'item_id":'`
    fi
    echo "Unread pocket "$TYPE"s: $COUNT"
}

function items_view {
    if which jq > /dev/null; then
        retrieve $1
        local COUNT=`echo $LIST | jq '.list | length'`
        if [[ COUNT -eq 0 ]]; then
            echo "Sorry, you don't have "$TYPE"s in yout pocket :-("
        elif [[ COUNT -le 10 ]]; then
            (echo -e '"id@title@word count"' && echo $LIST | jq '.list[] | .item_id + "@" + .resolved_title + "@" + .word_count') | column -t -s @ -o ' | '
        else
            (echo -e '"id@title@word count"' && echo $LIST | jq '.list[] | .item_id + "@" + .resolved_title + "@" + .word_count') | column -t -s @ -o ' | ' | less
        fi
    else 
        echo "This functionality require jq to be installed (http://stedolan.github.io/jq/)";
    fi
}

# Main
case $1 in
    "count" )
        items_count $2
        ;;
    "view" )
        items_view $2
        ;;
    "add" )
        ;;
    *)
        print_help
        ;;
esac
