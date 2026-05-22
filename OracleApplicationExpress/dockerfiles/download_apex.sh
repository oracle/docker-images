#!/bin/bash

# Variables
DOWNLOAD_LINK=$1
DESTINATION_FOLDER=$2

# Check if both arguments are provided
if [ -z "$DOWNLOAD_LINK" ] || [ -z "$DESTINATION_FOLDER" ]; then
    echo "Usage: $0 <download_link> <destination_folder>"
    exit 1
fi

# Create the destination folder if it does not exist
mkdir -p "$DESTINATION_FOLDER"

# Download the file
curl -L "$DOWNLOAD_LINK" -o /tmp/downloaded.zip

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download the file from $DOWNLOAD_LINK"
    exit 1
fi

# Unzip the file to the destination folder
unzip /tmp/downloaded.zip -d "$DESTINATION_FOLDER"

# Check if the unzip was successful
if [ $? -ne 0 ]; then
    echo "Failed to unzip the file to $DESTINATION_FOLDER"
    exit 1
fi

# Cleanup
rm /tmp/downloaded.zip

echo "Download and unzip completed successfully."
