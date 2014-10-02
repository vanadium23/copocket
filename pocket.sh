#!/bin/bash
#-------------------------------------------------------
CONSUMER_KEY="32888-4ce66c1f7828c8de8cf68db1"
#-------------------------------------------------------
if [ ! -f access_token.txt ]; then
	CODE=`curl -s -H "Content-Type: application/json" -X POST -d '{"consumer_key":"'$CONSUMER_KEY'","redirect_uri":"void:ok"}' https://getpocket.com/v3/oauth/request`
	CODE=`echo $CODE|cut -c 6-`
	echo Request-token: $CODE
	echo "Requiring authorization! Go to following url:"
	echo "https://getpocket.com/auth/authorize?request_token=$CODE&redirect_uri=https://gist.github.com/vanadium23/5186f0e8b6cd9e2d14b9"
	echo "Press enter when you have authorized the application."
	read null
	ACCESS_TOKEN=`curl -H "Content-Type: application/json" -X POST -d '{"consumer_key":"'$CONSUMER_KEY'","code":"'$CODE'"}' https://getpocket.com/v3/oauth/authorize`
	echo "$ACCESS_TOKEN" | sed 's/access_token=\(.*\)&username=\(.*\)/\1/g' > access_token.txt
	echo "Saved your access_token"
	exit
fi
ACCESS_TOKEN=$(<access_token.txt)
CODE=`curl -s -H "Content-Type: application/json" -X POST -d '{"consumer_key":"'$CONSUMER_KEY'","access_token": "'$ACCESS_TOKEN'"}' https://getpocket.com/v3/get | tr ',' '\n' | grep -c -o 'is_article":"1"'`
echo Unread pocket articles: $CODE

