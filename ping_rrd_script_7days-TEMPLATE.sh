#!/bin/bash
AUTHOR='philipp.hanselmann@gmail.com'
VERSION='1.0'
## Changelog
# 1.0 - Inital version


DEBUG=true
SCRIPT_NAME=$(basename "$0" .sh)

HOSTS=("google.com" "youtube.com" "chatgpt.com" "facebook.com" "20min.ch" "instagram.com" "linkedin.com" "live.com" )

COLORS=("FF0000" "00FF00" "0000FF" "FFFF00" "FF00FF" "00FFFF" "800000" "808080") # Up to 8 colors

#pnac.swisstopo.admin.ch
#– Kernsystem für das AGNES-Netzwerk (swisstopo PNAC), in das Zimmerwald per NTRIP-Stream integriert ist (Monitoring, Referenz­koordinaten).
#
#swipos.ch
#– SWIPOS-Portal für Offline-RINEX-Downloads und nachträgliche Positionierung; essentiell für Post-Processing der Zimmerwald-Daten.
#
#igs-ip.net
#– Globaler IGS-NTRIP-Caster: liefert Echtzeit-Korrekturen und Rohdaten aller IGS-Stationen, darunter auch Zimmerwald.
#
#products.igs-ip.net
#– IGS-Products-Caster: synchronisierte Produkte (SSR-Korrekturen, präzise Ephemeriden), genutzt für hochgenaue Auswertungen der Zimmerwald-Station.
#
#mgex.igs-ip.net
#– MGEX-NTRIP-Caster des IGS Multi-GNSS-Experiments; wichtig, wenn Zimmerwald-Empfänger Multi-GNSS-Signale verarbeiten.
#
#euref-ip.net
#– Europäischer EUREF-IP-Caster (BKG-Instanz): zusätzliche regionale Korrekturdaten zur Absicherung und Vergleich.
#
#register.rtcm-ntrip.org
#– Zentrale Registrierungs­stelle für NTRIP-Zugänge (EUREF/IP & IGS); wichtig für Verwaltung von Nutzer­accounts und Zugriffs­rechte.
#
#ntrip.gnsslab.cn
#– China-NTRIP-Caster (Wuhan); nur relevant, wenn man globale Multi-GNSS-Vergleiche mit chinesischen Stationen benötigt.
#



RRD_FILE="${SCRIPT_NAME}-${#HOSTS[@]}.rrd"

INTERVAL=30  # Measurement interval in seconds, must evenly divide 60

DURATION_24H=86400  # 24 hours in seconds
DURATION_7D=604800  # 7 days in seconds


# Check if rrdtool is available
if ! command -v rrdtool &>/dev/null; then
    echo "Error: 'rrdtool' is not installed. Please install it to use this script."
    exit 1
fi


# Function to create RRD file dynamically
function create_rrd_file() {
    if [[ ! -f $RRD_FILE ]]; then
        echo "Creating RRD file for ${#HOSTS[@]} host(s):"
        echo "  ${HOSTS[@]}"
        local DS_ARGS=()
        for i in "${!HOSTS[@]}"; do
            DS_ARGS+=(DS:host$((i+1)):GAUGE:$((INTERVAL * 2)):0:U)
        done
        rrdtool create $RRD_FILE \
            --step $INTERVAL \
            "${DS_ARGS[@]}" \
            RRA:AVERAGE:0.5:1:$((DURATION_7D / INTERVAL))
        echo "  RRD file ${PWD}/${RRD_FILE} created."
    else
        echo "  RRD file ${PWD}/${RRD_FILE} already exists."
    fi
}



function update_rrd_database_once() {
    PING_TIMES=()
    for HOST in "${HOSTS[@]}"; do
        PING_TIME=$(ping -c 1 -W 1 $HOST | grep 'time=' | sed -n 's/.*time=\([0-9.]*\).*/\1/p')
        PING_TIMES+=("${PING_TIME:-U}")
        $DEBUG && echo "$HOST: PING_TIME :$PING_TIME"
    done
    UPDATE_STRING=$(IFS=:; echo "${PING_TIMES[*]}")
    $DEBUG && echo "Collected PING_TIMES: $UPDATE_STRING"
    rrdtool update $RRD_FILE N:$UPDATE_STRING
}


function update_rrd_database_daemon() {
    while true; do
        update_rrd_database_once
        sleep $INTERVAL
    done
}

function configure_cronjob() {
    # Calculate the number of iterations (N) for the given INTERVAL
    local ITERATIONS=$((60 / INTERVAL))
    if ((60 % INTERVAL != 0)); then
        echo "Error: INTERVAL ($INTERVAL) must evenly divide 60 seconds."
        return 1
    fi

    # Dynamically create the cron job command
    local CRON_CMD="* * * * * for i in {1..$ITERATIONS}; do $(realpath $0) --update-rrd-cron; sleep $INTERVAL; done"

    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -qF "$CRON_CMD"; then
        echo "Cron job is already configured. No changes made."
        return 0
    fi

    # Add cron job safely without removing other entries
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo "Cron job configured to update RRD database every $INTERVAL seconds."
    echo "Check cron jobs entries with crontab -l"
}


function create_graphs() {
    local TIMESTAMP=$(date +"%Y%m%d_%H%M")
    local OUTPUT_24H="${TIMESTAMP}_ping_24h.png"
    local OUTPUT_7D="${TIMESTAMP}_ping_7d.png"

    # Generate definitions and lines dynamically for each host
    local DEF_ARGS=()
    local LINE_ARGS=()
    for i in "${!HOSTS[@]}"; do
        DEF_ARGS+=(DEF:host$((i+1))=$RRD_FILE:host$((i+1)):AVERAGE)
        LINE_ARGS+=(LINE1:host$((i+1))#${COLORS[i]}:"$((i+1))\:${HOSTS[i]}")
    done


    TIMESTAMP=" $(date '+%Y-%m-%d %H:%M')"
    # 24-hour graph
    rrdtool graph $OUTPUT_24H \
        --start end-$DURATION_24H --end now \
        --width 800 --height 400 \
        --title "Ping response times (Last 24 hours, update:${TIMESTAMP})" \
        --vertical-label "ms" \
        --x-grid MINUTE:30:HOUR:1:HOUR:1:0:%H:%M \
        HRULE:50#00FF00:"Warning" \
        HRULE:80#FF0000:"Critical" \
        --lower-limit 0 \
        "${DEF_ARGS[@]}" \
        "${LINE_ARGS[@]}"
    echo "Graph for last 24 hours created at $OUTPUT_24H"


    # Generate the graph for 7 days with a date overlay
    rrdtool graph $OUTPUT_7D \
        --start end-$DURATION_7D --end now \
        --width 800 --height 400 \
        --title "Ping response times (Last 7 days, update:${TIMESTAMP})" \
        --vertical-label "ms" \
        --x-grid DAY:1:DAY:1:DAY:1:0:%A \
        --lower-limit 0 \
        "${DEF_ARGS[@]}" \
        "${LINE_ARGS[@]}"
#     echo "Graph for last 7 days created at $OUTPUT_7D"


}

# Function to create and display graphs using feh
function create_graph_and_show() {
    if ! command -v feh &> /dev/null; then
        echo "Error: 'feh' is not installed. Please install 'feh' to use this feature."
        exit 1
    fi

    create_graphs

    local TIMESTAMP=$(date +"%Y%m%d_%H%M")
    local OUTPUT_24H="${TIMESTAMP}_ping_24h.png"
    local OUTPUT_7D="${TIMESTAMP}_ping_7d.png"

    feh $OUTPUT_24H $OUTPUT_7D
}

# Parse command-line arguments
case "$1" in
    --create-rrd-database)
        create_rrd_file
        ;;
    --update-rrd-daemon)
        update_rrd_database_daemon
        ;;
    --update-rrd-cron-setup)
        configure_cronjob
        ;;
    --update-rrd-cron)
        update_rrd_database_once
        ;;
    --create-graph)
        create_graphs
        ;;
    --show-graph)
        create_graph_and_show
        ;;
    *)
        echo "Usage: $0 [OPTION]              (version:${VERSION}, ${AUTHOR})"
        echo "Options:"
        echo "  --create-rrd-database      Create the RRD database file"
        echo "  --update-rrd-daemon        Start updating the RRD database in a loop"
        echo "  --update-rrd-cron-setup    Configure a cron job to update the RRD database every ${INTERVAL} seconds"
        echo "  --update-rrd-cron          Update the RRD database once (used by the cron job)"
        echo "  --create-graph             Create the graph for ping response times"
        echo "  --show-graph               Create a temporary graph and open it with feh"

        # Add database existence check with filename
        if [[ ! -f $RRD_FILE ]]; then
            echo -e "\nError: RRD database file '$RRD_FILE' not found!"
            echo "Run '$0 --create-rrd-database' first to initialize the database."
        else
            echo -e "\nDatabase:$RRD_FILE "
        fi

        ;;
esac
