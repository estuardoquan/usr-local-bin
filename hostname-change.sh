#!/bin/sh

log_change()
{
    local LOG=/var/log/hostname.log
    printf "%s: %s\n" "$(date)" "${1}" >> ${LOG}
}


LOGONLY=0
NSUPDATE_KEY=/var/tmp/nsupdate.key
STATE=/var/lib/hostname/state

OPT=$(getopt -o k:s: --long key:,log-only,state: -n "$0" -- "$@")

if [ $? -ne 0 ]; then
    exit 1
fi

eval set -- "${OPT}"

while true; do
    case "$1" in
        -k|--key)
            NSUPDATE_KEY=$2
            shift 2
            ;;
        -s|--state)
            STATE=$2
            shift 2
            ;;   
        --log-only)
            LOGONLY=1
            shift
            ;;   
        --)
            shift 
            break
            ;;
        *)
            echo "Unexpected option: $1"
            exit 1
            ;;
    esac
done



mkdir -p "$(dirname ${STATE})"

CURRENT=$(hostname)
PREVIOUS=$(cat ${STATE} 2>/dev/null)

if [ -z "${PREVIOUS}" ]; then
    log_change "initialized hostname is now ${CURRENT}"
    
    if [ ${LOGONLY} == 0 ]; then
        hostname-nsupdate.sh | nsupdate -k ${NSUPDATE_KEY}
    fi
else
    if [ "${CURRENT}" != "${PREVIOUS}" ]; then
        log_change "started hostname change from ${PREVIOUS} to ${CURRENT}"
        
        if [ ${LOGONLY} == 0]; then
            hostname-nsupdate.sh -d --host ${PREVIOUS} | nsupdate -k ${NSUPDATE_KEY}

            sleep 30

            hostname-nsupdate.sh | nsupdate -k ${NSUPDATE_KEY}
        fi

        printf "%s\n" "${CURRENT}" > ${STATE}

        log_change "finished"
    fi
fi

