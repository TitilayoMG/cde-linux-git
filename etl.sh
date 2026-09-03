#!/bin/bash

# exit the script when there's error
set -e

# change the directory to the dir where this script is located
cd "$(dirname "$0")"
echo "Working directory set to: $(pwd)"
echo "The bash script is running in $(pwd)"

# loads the variables from .env file
source .env
echo "Successfully loads the variable from .env file"

# The raw file path
file='raw/data.csv'

# Download the csv file through the link in the variable saved in .env file
curl -o "$file" "$csv_url"
echo 'File Successfully Downloaded to raw/'

# checks if the file successfully saved to raw/
if [ -f "$file" ]; then
	echo 'File Saved Successfully to raw/'
else
	echo 'File Not Saved Successfully to raw/'
fi

# Transformation
# column renaming
sed -i '1s/Variable_code/variable_code/' "$file"
echo 'Variable_code Column Successfully Renamed to variable_code'


# Transformed path
transformed_file='transformed/2023_year_finance.csv'

# select few columns and save them in a saparate file
python3 -c "import csv; f='$file'; out='$transformed_file'; r=csv.DictReader(open(f, newline='')); w=csv.DictWriter(open(out,'w',newline=''), fieldnames=['Year','Value','Units','variable_code'], extrasaction='ignore'); w.writeheader(); w.writerows(r)"
echo "File Successfully Transformed and Saved to transformed/"


# Confirm if the transformed file is saved to transformed path
if [ -f "$transformed_file" ]; then
	echo "Transformed File Exists In transformed/"
else
	echo "File Not Found In transformed/"
fi

# Gold file path
gold_file='Gold/2023_year_finance.csv'

# Load transformed file to Gold dir
cp "$transformed_file" "$gold_file"
echo "Successfully Loaded the Transformed File to Gold"

# confirm if the transformed file was successfully loaded to Gold dir
if [ -f "$gold_file" ]; then
	echo "Successfully Saved the Transformed File to Gold/"
else
	echo "File Not Found in Gold/"
fi