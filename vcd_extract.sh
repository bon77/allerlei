#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <TOC file>"
    exit 1
fi

TOC_FILE="$1"
BASE_NAME="${TOC_FILE%.*}"  # Remove file extension
DATA_FILE="${BASE_NAME}.data"
BLOCK_SIZE=2048  # Set to 2 KB for faster extraction

if [ ! -f "$DATA_FILE" ]; then
    echo "Error: Data file $DATA_FILE not found!"
    exit 1
fi

if [ ! -d "trash" ]; then
    mkdir trash
fi


# Extract track offsets and sizes from TOC file
TRACK_NUM=1
while read -r line; do
    if [[ "$line" =~ DATAFILE ]]; then
        OFFSET=0
        LENGTH=0

        # Extract file offset (if present) and length
        if [[ "$line" =~ DATAFILE[[:space:]]\"[^\"]+\"[[:space:]]#([0-9]+)[[:space:]]([0-9]+:[0-9]+:[0-9]+) ]]; then
            OFFSET=${BASH_REMATCH[1]}
        fi

        # Extract length (last number in the line)
        if [[ "$line" =~ ([0-9]+)[[:space:]]*$ ]]; then
            LENGTH=${BASH_REMATCH[1]}
        fi

        if [ "$TRACK_NUM" -gt 1 ] && [ "$LENGTH" -gt 0 ]; then
            OUTPUT_FILE="${BASE_NAME}_track$((TRACK_NUM-1)).mpg"
            OFFSET_BLOCKS=$(( OFFSET / BLOCK_SIZE ))
            LENGTH_BLOCKS=$(( LENGTH / BLOCK_SIZE ))

            echo "Extracting track $TRACK_NUM to $OUTPUT_FILE (Offset: $OFFSET_BLOCKS blocks, Length: $LENGTH_BLOCKS blocks)"
            echo "running: \"dd if="$DATA_FILE" of="$OUTPUT_FILE" bs=$BLOCK_SIZE skip="$OFFSET_BLOCKS" count="$LENGTH_BLOCKS" status=progress\""
            dd if="$DATA_FILE" of="$OUTPUT_FILE" bs=$BLOCK_SIZE skip="$OFFSET_BLOCKS" count="$LENGTH_BLOCKS" status=progress
        fi

        ((TRACK_NUM++))
    fi
done < "$TOC_FILE"
mv -v "${TOC_FILE}" trash/
mv -v "${DATA_FILE}" trash/

echo "Extraction complete!"

