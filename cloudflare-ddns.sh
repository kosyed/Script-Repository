#!/usr/bin/env bash

# https://github.com/kosyed/script-repository/cloudflare-ddns
# Script updates selected DNS Record Name to Client WAN IP, works well as a cron job "0 0 * * * /home/pi/cloudflare-ddns.sh"
# Resource: https://1.1.1.1/help
# Resource: https://api.cloudflare.com/#dns-records-for-a-zone-properties

# Required: TOKEN or EMAIL + GLOBALKEY
TOKEN=""                                         # My Profile > API Tokens > API Tokens > Create Token
EMAIL=""                                         # My Profile > Communication > Email Address
GLOBALKEY=""                                     # My Profile > API Tokens > API Keys > Global API Key > View

# Required:
ZONE_ID=""                                       # Domain > Overview > API > Zone ID
NAME=""                                          # Domain > DNS > Name

# Additional:
ID=""                                            # Unique per record NAME. Retrieved if empty, save in script to optimise
TYPE="A"                                         # "A" for IPv4, "AAAA" for IPv6
TTL="1"                                          # "1" equals auto
PROXIED="false"                                  # "false" to not hide IP behind Cloudflare

######## SCRIPT ########
if [ -z "$ZONE_ID" ] || [ -z "$NAME" ]; then
	echo "Required: ZONE_ID and NAME"
	exit 1
fi

if [ "$TYPE" == "A" ]; then
	IPTYPE="IPv4"
	IPADDRESS="1.1.1.1"
	else
	if [ "$TYPE" == "AAAA" ]; then
		IPTYPE="IPv6"
		IPADDRESS="2606:4700:4700::1111"
		else
		echo "Only A and AAAA TYPE is currently supported"
		exit 1
	fi
fi

MYIP="$(dig @$IPADDRESS ch txt whoami.cloudflare +short | tr -d '"')"

if [ -z "$MYIP" ] || [[ "$MYIP" == *"timed out"* ]]; then
	echo "Client WAN $TYPE Retrieval Error"
	exit 1
	else
	CONTENT="$(dig @$IPADDRESS $TYPE $NAME +short)"
	if [ -z "$CONTENT" ] || [[ "$CONTENT" == *"timed out"* ]]; then
		echo "$NAME $TYPE Retrieval Error"
		exit 1
		else
		MYIPCHECK="$(echo "$MYIP" | wc -l )"
		CONTENTCHECK="$(echo "$CONTENT" | wc -l )"
	fi
fi

if [ "$MYIPCHECK" = "1" ]; then
	echo "$MYIP - Client WAN"
	else
	MYIP="$(echo "$MYIP" | head -n1 )"
	echo "$MYIP - Client WAN has multiple entries, using first value"
fi

if [ "$CONTENTCHECK" = "1" ]; then
	echo "$CONTENT - $NAME"
	else
	CONTENT="$(echo "$CONTENT" | head -n1 )"
	echo "$CONTENT - $NAME has multiple entries, using first value"
fi

if [ "$CONTENT" == "$MYIP" ]; then
	echo "$IPTYPE Unchanged"
	exit 0
	else
	echo "$IPTYPE Has Changed"
fi

if [ -z "$TTL" ] || [ -z "$PROXIED" ]; then
	echo "TTL or PROXIED not set, using defaults"
	TTL="1"
	PROXIED="false"
fi

if [ -z "$TOKEN" ] && [ -z "$GLOBALKEY" ]; then
	echo "Required: TOKEN or EMAIL + GLOBALKEY"
	exit 1
	else
	if [ -z "$TOKEN" ]; then
		AUTHTYPE="EMAIL + GLOBALKEY"
		else
		EMAIL=""
		GLOBALKEY=""
		AUTHTYPE="TOKEN"
	fi
fi

echo "Using $AUTHTYPE Authorization"
API="https://api.cloudflare.com/client/v4"

if [ -z "$ID" ]; then
	ID="$(curl -s -X GET "$API/zones/$ZONE_ID/dns_records?name=$NAME" \
	-H "Authorization: Bearer $TOKEN" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $GLOBALKEY" \
	-H "Content-Type: application/json" )"
	IDSUCCESS="$(echo $ID | grep -oP '(?<="success":)[^,]*' )"
	if [ "$IDSUCCESS" = "true" ]; then
		ID="$(echo $ID | grep -oP '\w+(?=","type":"'$TYPE'")' )"
		echo "ID Retrieved, save in script to optimise - $ID"
		else
		echo "ID Retrieval Error"
		exit 1
	fi
fi

SUCCESS="$(curl -s -X PUT "$API/zones/$ZONE_ID/dns_records/$ID" \
-H "Authorization: Bearer $TOKEN" \
-H "X-Auth-Email: $EMAIL" \
-H "X-Auth-Key: $GLOBALKEY" \
-H "Content-Type: application/json" \
--data '{"type":"'"$TYPE"'","name":"'"$NAME"'","content":"'"$MYIP"'","ttl":'$TTL',"proxied":'$PROXIED'}' | grep -oP '(?<="success":)[^,]*' )"

if [ "$SUCCESS" = "true" ]; then
	echo "Record Updated"
	exit 0
	else
	echo "Record Update Error"
	exit 1
fi
