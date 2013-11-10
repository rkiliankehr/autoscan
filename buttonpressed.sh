#!/bin/sh

# This script is started by scanbuttond whenever a scanner button has been pressed.
# Scanbuttond passes the following parameters to us:
# $1 ... the button number
# $2 ... the scanner's SANE device name, which comes in handy if there are two or 
#        more scanners. In this case we can pass the device name to SANE programs 
#        like scanimage.

exec >/tmp/buttonpressed.log 2>&1
set -vx 

logger "Starting buttonpressed.sh with ID="$(id)"."

BUTTON="$1"
SCANNER="$2"

TMPDIR="/var/spool/autoscan"

. /opt/autoscan/.autoscan-config

# Create temporary working directory if not present.
mkdir -p "$TMPDIR"
if [ $? != 0 ]
then
    logger Could not create working directory "$TMPDIR".
    exit 1
fi
 
# Aquire lock for safely performing a scan.

LOCKFILE="$TMPDIR/.lockfile"
TMPLOCK=${LOCKFILE}.$$

echo $$ > $TMPLOCK
if ln $TMPLOCK $LOCKFILE 2>&-; then
    :
else
    logger "Error: buttonpressed.sh: Scanning already in progress for scanner '$SCANNER'."
    rm $TMPLOCK
    exit 1
fi

#trap "rm -rf ${TMPDIR}" 0 1 2 3 15
trap "rm -rf ${LOCKFILE} ${TMPLOCK}" 0 1 2 3 15

TIME=$(date "+%Y%m%d-%H%M%S")
SCANDIR="$TMPDIR/scan.$TIME.$$"
rm -rf "$SCANDIR"
mkdir -p "$SCANDIR"

BINDIR=/opt/autoscan

# Scan options:
#    --mode Color|Gray|Lineart [Lineart]
#        Selects the scan mode (e.g., lineart, monochrome, or color).
#    --source Flatbed|ADF|ADF Duplex [Flatbed]
#        Selects the scan source (such as a document-feeder).
#    --resolution 100|200|300|600|1200|2400dpi [100]
#        Sets the resolution of the scanned image.


case $BUTTON in
    1)  echo "Button $BUTTON has been pressed on '$SCANNER'."
		
	DPI=300
	MODE=Gray
	SCANFILE="$SCANDIR/scan.001.tif"
	scanimage \
	    --device-name "$SCANNER" \
	    --format tiff \
	    --mode $MODE \
	    --resolution $DPI \
	    > $SCANFILE
	if [ $? != 0 ]; then
	    echo "Scanning failed."
	    rm -rf "$SCANDIR"
	    $BINDIR/autoscan-alert "$@"
	    exit 1  
	fi
	nohup $BINDIR/autoscan-process "$SCANFILE" >/dev/null 2>&1 &
	exit
	;;

    2)  echo "Button $BUTTON has been pressed on '$SCANNER'."
		
	DPI=200
	MODE=Color
	SCANFILE="$SCANDIR/scan.001.tif"
	scanimage \
	    --device-name "$SCANNER" \
	    --format tiff \
	    --mode $MODE \
	    --resolution $DPI \
	    > $SCANFILE
	if [ $? != 0 ]; then
	    echo "Scanning failed."
	    rm -rf "$SCANDIR"
	    $BINDIR/autoscan-alert "$@"
	    exit 1  
	fi
	nohup $BINDIR/autoscan-process "$SCANFILE" >/dev/null 2>&1 &
	exit
	;;

    3)  echo "Button $BUTTON has been pressed on '$SCANNER'."
		
	DPI=300
	MODE=Gray
	SCANFMT="${SCANDIR}/scan.%03d.tif"
	scanimage \
	    --device-name "$SCANNER" \
	    --format tiff \
	    --mode $MODE \
	    --resolution $DPI \
	    --source=ADF \
	    --batch="$SCANFMT"
	# scanimage exit code seems to be the number of pages scanned.
        # Hence the following exit code check seems to make sense.
	if [ $? == 0 ]; then
	    echo "Scanning failed."
	    rm -rf "$SCANDIR"
	    $BINDIR/autoscan-alert "$@"
	    exit 1  
	fi
	nohup $BINDIR/autoscan-process-dir "$SCANDIR" >/dev/null 2>&1 &
	exit
	;;
esac

