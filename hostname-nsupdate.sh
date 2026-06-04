#!/bin/bash

ip_list() {
    ip -4 -o addr show scope global \
        | awk '$2 !~ /^(docker|br-|veth|virbr|tun|tap)/ {print $4}' \
        | cut -d/ -f1
}

usage() {

    printf "%s\n" \
        "nsupdate value wrapper" \
        "ddns.sh [OPTIONS]"
    printf "\t%s\n" \
        "-d | --delete      Only perform delete action" \
        "-a | --addresses   List of addresses to add" \
        "-h | --help        Display this message" \
        "--host             The name of the host" \
        "--key              Key file to update dns" \
        "--url              Destination DNS" \
        "--zone             Zone to change"
}

DELETE=0
HOST=$(hostname)
NSUPDATE_KEY=~/.ddns/acme-update.key
NSUPDATE_SERVER=bind9.local
NSUPDATE_ZONE=local
OPT=$(getopt -o dha: --long delete,addresses:,help,host:,key:,url:,zone: -n "$0" -- "$@")
ADDRESSES=$(ip_list)

if [ $? -ne 0 ]; then
    exit 1
fi

# 2. Use eval to set the positional parameters to the parsed options
eval set -- "$OPT"

# 3. Process each option in a loop
while true; do
    case "$1" in
        -d|--delete)
            DELETE=1
            shift
            ;;
        -a|--addresses)
            ADDRESSES=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --host)
            HOST=$2
            shift 2
            ;;
        --key)
            NSUPDATE_KEY=$2
            shift 2
            ;;
        --url)
            NSUPDATE_SERVER=$2
            shift 2
            ;;
        --zone)
            NSUPDATE_ZONE=$2
            shift 2
            ;;
        --)
            shift # Remove the -- marker
            break
            ;;
        *)
            echo "Unexpected option: $1"
            exit 1
            ;;
    esac
done

printf "%s\n" \
    "server ${NSUPDATE_SERVER}" \
    "update delete ${HOST}.${NSUPDATE_ZONE} A" 

if [ $DELETE = 0 ]; then
    for IP in $ADDRESSES; do
        printf "%s\n" \
            "update add ${HOST}.${NSUPDATE_ZONE} 300 A ${IP}"
    done
fi

printf "%s\n" \
    "show" \
    "send"
