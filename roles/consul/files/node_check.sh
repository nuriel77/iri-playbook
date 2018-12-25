#!/bin/bash
# Custom health check for IRI full nodes

function usage(){
    cat <<EOF

This script will run curl commands to the API endpoint.
If any of the tests fails this script will return failure.

-a [address]       API endpoint
-t [seconds]       Seconds until connection timeout
-n [integer]       Minimum neighbors to expect
-m [version]       Minimum version to expect
-w [seconds]       Maximum allowed duration for API response
-p                 Check if node allows PoW (attachToTangle)
-k                 Skip TLS verification
-i                 Ignore/skip REMOTE_LIMIT_API commands check
-u                 Ignore unsynced node (e.g. PoW only node)
-h                 Print help and exit

example:

  $0 -a http://host-name.example.com:14265 -t 3

EOF
}

while getopts ":a:t:n:r:m:w:pukih" opt; do
    case "${opt}" in
        a)
            ADDRESS=$OPTARG
            ;;
        h)
            usage
            exit 0
            ;;
        i)
            IGNORE_REMOTE_LIMIT_API=1
            ;;
        r)
            REQUIRED_APP_NAME=$OPTARG
            ;;
        m)
            MIN_API_VERSION=$OPTARG
            ;;
        k)
            TLS_SKIP_VERIFY=1
            ;;
        n)
            MINIMUM_NEIGHBORS=$OPTARG
            ;;
        t)
            TIMEOUT=$OPTARG
            ;;
        w)
            API_DURATION=$OPTARG
            ;;
        p)
            CHECK_POW=1
            ;;
        u)
            IGNORE_UNSYNCED=1
            ;;
        :)
            echo "Option -$OPTARG requires an argument" >&2
            exit 3
            ;;
        *)
            usage
            exit 3
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$ADDRESS" ]]; then
    echo "ERROR: Missing address"
    exit 3
fi

: ${TIMEOUT:=3}
: ${MINIMUM_NEIGHBORS:=2}
: ${MIN_API_VERSION:=1.5.0}
: ${API_DURATION:=3}
: ${CHECK_POW:=0}
: ${REQUIRED_APP_NAME:=IRI}

API_VERSION=1.5.6
PAYLOAD='{"command": "getNodeInfo"}'
REMOTE_LIMIT_API=(getNeighbors addNeighbors removeNeighbors attachToTangle interruptAttachingToTangle)

# check node info
DATA=$(curl $TLS_SKIP_VERIFY --retry 2 -m $TIMEOUT -s "$ADDRESS" -H "X-IOTA-API-Version: $API_VERSION" -H 'Content-Type: application/json' -d "$PAYLOAD")
RC=$?
if [[ $RC -ne 0 ]]; then
    if [[ $RC -eq 28 ]]; then
        echo "Operation timed out"
        exit 2
    elif [[ $RC -eq 7 ]]; then
        echo "Connection refused"
        exit 2
    else
        echo "Error contacting host, exited $RC: '$DATA'"
        exit 2
    fi
elif ! echo "$DATA" | python -m json.tool >/dev/null; then
    echo "Invalid JSON returned: '$DATA'"
    exit 2
fi

LMI=$(echo "$DATA"| jq -r .latestMilestoneIndex)
LSSMI=$(echo "$DATA"| jq -r .latestSolidSubtangleMilestoneIndex)
NEIGHBORS=$(echo "$DATA"| jq -r .neighbors)
APP_VERSION=$(echo "$DATA"| jq -r .appVersion)
APP_NAME=$(echo "$DATA" | jq -r .appName)
DURATION=$(echo "$DATA" | jq -r .duration)

# check node info
if (( $(awk 'BEGIN {print ("'$MIN_API_VERSION'" >= "'$APP_VERSION'")}') )); then
    echo "Host app version should be minimum '$MIN_API_VERSION' but is '$APP_VERSION'"
    exit 2
elif [[ "$APP_NAME" != "$REQUIRED_APP_NAME" ]]; then
    echo "Invalid appName: $APP_NAME"
    exit 2
elif [[ $DURATION -gt $API_DURATION ]]; then
    echo "Response too slow, took $DURATION seconds"
    exit 2
elif [[ $(expr $LMI - $LSSMI) -gt 1 ]] && [[ -z "$IGNORE_UNSYNCED" ]]; then
    echo "No sync: latestMilestoneIndex: $LMI and latestSolidSubtangleMilestoneIndex: $LSSMI"
    exit 2
elif [[ $NEIGHBORS -lt $MINIMUM_NEIGHBORS ]]; then
    echo "Too few neighbors: $NEIGHBORS"
    exit 2
fi

if [[ $CHECK_POW -eq 1 ]]; then
    if (( $(awk 'BEGIN {print ("'$API_VERSION'" > "1.5.6")}') )); then
        if [[ $(echo "$DATA" | jq -r '.features' | jq 'contains(["RemotePOW"])') != "true" ]]; then
            echo "PoW disabled"
            exit 2
        fi
    else
        PAYLOAD="{\"command\": \"attachToTangle\"}"
        CODE=$(curl $TLS_SKIP_VERIFY --retry 2 -m $TIMEOUT -s "$ADDRESS" -w "%{http_code}" -H "X-IOTA-API-Version: $API_VERSION" -H 'Content-Type: application/json' -d "$PAYLOAD" -o /dev/null)
        RC=$?
        if [[ $RC -ne 0 ]]; then
            if [[ $RC -eq 28 ]]; then
                echo "Operation timed out"
                exit 2
            elif [[ $RC -eq 7 ]]; then
                echo "Connection refused"
                exit 2
            else
                echo "Error contacting host, exited $RC: '$DATA'"
                exit 2
            fi
        elif [[ $CODE -eq 401 ]]; then
            echo "PoW disabled"
            exit 2
        fi
    fi
fi

# Exit now if don't need to check limited commands
if [[ -n "$IGNORE_REMOTE_LIMIT_API" ]]; then
    exit 0
fi

# check limited commands
for cmd in "${REMOTE_LIMIT_API[@]}"; do
    PAYLOAD="{\"command\": \"$cmd\"}"
    CODE=$(curl $TLS_SKIP_VERIFY --retry 2 -m $TIMEOUT -s "$ADDRESS" -w "%{http_code}" -H "X-IOTA-API-Version: $API_VERSION" -H 'Content-Type: application/json' -d "$PAYLOAD" -o /dev/null)
    RC=$?
    if [[ $RC -eq 28 ]]; then
        echo "Operation timed out"
        exit 2
    elif [[ $RC -eq 7 ]]; then
        echo "Connection refused"
        exit 2
    elif [[ $CODE -ne 401 ]]; then
        echo "Error: command '$cmd' is not blocked on this node"
        exit 2
    fi
    sleep .1
done
