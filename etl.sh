#!/bin/bash

# change the directory to the dir where this script is location
cd "$(dirname "$0")"

# loads the variables from .env file
source .env

# The saved file path
file='raw/data.csv'

# Download the csv file through the link in the variable saved in .env file
curl -o "$file" "$csv_url"

# checks if the file successfully saved
if [ -f "$file" ]; then
	echo 'File saved successfully'
else
	echo 'File not saved successfully'
fi






