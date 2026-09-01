# file location
cd "$(dirname "$0")"

file="test.txt"

echo "Testing the file location in bash script" > "$file"

#confirm if the file exist and print the data
if [ -f "$file" ]; then
	echo "File saved and found successfully"
	cat "$file"
else
	echo "File not found"
fi



