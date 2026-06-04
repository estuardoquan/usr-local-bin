#!/bin/sh

log_change()
{
    local LOG=/var/log/hostname.log
    printf "%s: %s\n" "$(date)" "${1}" >> ${LOG}
}

STATE=/var/lib/hostname/state

mkdir -p "$(dirname ${STATE})"

CURRENT=$(hostname)
PREVIOUS=$(cat ${STATE} 2>/dev/null)

NSUPDATE_KEY=/home/admin/.ddns/acme-update.key

if [ -z "${PREVIOUS}" ]; then
    log_change "initialized hostname is now ${CURRENT}"
    
    hostname-nsupdate | nsupdate -k ${NSUPDATE_KEY}
else
    if [ "${CURRENT}" != "${PREVIOUS}" ]; then
        log_change "started hostname change from ${PREVIOUS} to ${CURRENT}"

        hostname-nsupdate -d --host ${PREVIOUS} | nsupdate -k ${NSUPDATE_KEY}

        sleep 30

        hostname-nsupdate | nsupdate -k ${NSUPDATE_KEY}

        printf "%s\n" "${CURRENT}" > ${STATE}

        log_change "finished"
    fi
fi

