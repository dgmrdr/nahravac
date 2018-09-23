#!/bin/bash
# author : dgmrdr
# (anti-c) all rights destroyed

VERSION="0.3"

# CHANGELOG:
# ver 0.3 [ 2018-09-23 ] - detect path with artist name, zip mp3
# ver 0.2 [ 2018-07-25 ] - change path order
# ver 0.1 [ 2018-07-18 ] - initial commit

set -e
if [ $# -ne 5 ]
then
	echo "Usage: nahravac.sh SRC DST 'Artist' 'Album' 'Song prefix'"
	echo "Example: bash nahravac.sh '/media/digimurder/9016-4EF8/STEREO/FOLDER03' '/media/digimurder/HddKragro01/TREKY/' 'Pterodaktyl' '2018_09_19_Skusky' 'skuska'"
	exit 1
fi

SRC=${1%/} # remove last slash
DST=${2%/} # remove last slash
ARTIST=$3
ALBUM=$4
PREFIX=$5


LAME_PRESET="--preset cbr 192" # optimal for shitty practice records ;)

LAME_BIN=`which lame`
MID3_BIN=`which mid3v2`
ZIP_BIN=`which zip`

# - - - - - - - - - -
# Basic checks
# - - - - - - - - - -
if [ -z "$LAME_BIN" ]; then
	echo "Can't find lame"
	exit 1
fi
if [ -z "$MID3_BIN" ]; then
	echo "Can't find mid3v2 (sudo apt-get install python-mutagen)"
	exit 1
fi
if [ -z "$ZIP_BIN" ]; then
	echo "Can't find zip (sudo apt-get install zip)"
	exit 1
fi

if [ ! -d $SRC ]; then
	echo "Source dir '$SRC' not exists !" >&2
	exit 1;
fi

# - - - - - - - - - -
# DST check
# - - - - - - - - - -

if [ "$(basename $DST)" == "$ARTIST" ]; then
	DST="$(dirname $DST)"
fi

if [ ! -d $DST ]; then
	echo "Destination dir '$DST' not exists !" >&2
	exit 1;
fi

if [ ! -w $DST ]; then
	echo "Destination dir '$DST' not writable !" >&2
	exit 1;
fi

# - - - - - - - - - -
# START
# - - - - - - - - - -
echo "Starting... $(basename 0)"
echo ""

FILES=($(ls $SRC/*.wav))

num=0
cnt=${#FILES[*]}
cnt_fail=0
cnt_pass=0
regex="([0-9]{2})([0-9]{2})([0-9]{2})-([0-9]{3}).wav"

wavpath="$DST/$ARTIST/$ALBUM/wav/"
mp3path="$DST/$ARTIST/$ALBUM/mp3/"
zipfile="$DST/$ARTIST/$ALBUM/${ARTIST}_${ALBUM}_mp3.zip"

echo "Found $cnt .wav files in $SRC :"
for file in "${FILES[@]}";
do
	if [[ $file =~ $regex ]]; then

		year="20${BASH_REMATCH[1]}"
		date="$year-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
		part="${BASH_REMATCH[4]}"
		name="${PREFIX}_${date}_${part}"
		song="${PREFIX} ${date} ${part}"


		wavfile="$wavpath/$name.wav"
		mp3file="$mp3path/$name.mp3"

		num=$((num+1))
		echo -e "\tTRACK [$num/$cnt]"
		echo -e "\t$file => $dstfile"

		# - - - - - - - - - -
		# wav
		# - - - - - - - - - -
		if [ ! -d "$wavpath" ]; then

			echo -e "\t\tmkdir -p \"$wavpath\""
			mkdir -p "$wavpath"
		fi

		if [ ! -f "$wavfile" ]; then
			echo -e "\t\tcp \"$file\" \"$wavfile\""
			cp "$file" "$wavfile"
		fi

		# - - - - - - - - - -
		# mp3
		# - - - - - - - - - -

		if [ ! -d "$mp3path" ]; then

			echo -e "\t\tmkdir -p \"$mp3path\""
			mkdir -p "$mp3path"
		fi
		if [ ! -f "$mp3file" ]; then
			echo -e "\t\tencoding $mp3file"
			echo -e "\t\t$LAME_BIN $LAME_PRESET \"$wavfile\" \"$mp3file\""
			echo ""
			$LAME_BIN $LAME_PRESET "$wavfile" "$mp3file"
		fi
		echo -e "\t\tTAG $mp3file"
		mid3v2 -a "$ARTIST" -A "$ALBUM" -t "$song" -T "$num/$cnt" --date="$date" "$mp3file"

		cnt_pass=$((cnt_pass+1))
	else
		echo -e "\t$file => FAILED MATCH"
		cnt_fail=$((cnt_fail+1))
	fi
done

echo "Passed : ($cnt_pass/$cnt) Failed: ($cnt_fail/$cnt)"

# - - - - - - - - - -
# ZIP mp3folder
# - - - - - - - - - -
echo "$ZIP_BIN -r \"$zipfile\" \"$mp3path\""
$ZIP_BIN -r "$zipfile" "$mp3path"
exit $?
