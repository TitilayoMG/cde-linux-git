#!/bin/bash

# exit the script when there's error
set -e

source_dir="/mnt/c/Users/DELL/Downloads/"
destination_dir="/mnt/c/Users/DELL/Documents/json_and_csv"

echo "About to move both csv and json files from Documents/json_and_csv/ to /mnt/c/Users/DELL/Downloads/"

mv "$source_dir"*.csv "$destination_dir"
mv "$source_dir"*.json "$destination_dir"

echo "Successfully moved all json and csv files from Downloads/ to Documents/json_and_csv"