# CDE Linux Git — Simple ETL Pipeline

A Bash script that run a simple ETL pipeline, scheduled to run automatically every day at midnight using
`cron` and a small standalone Bash script, separate from the ETL pipeline, that moves
all CSV and JSON files from one folder into another. 

---

## 1. Project Overview

This project implements a simple **Extract → Transform → Load (ETL)**
workflow entirely in a single Bash script- `etl.sh`.

| Stage | What happens |
|-------|--------------|
| **Extract** | Downloads a CSV file from a URL (stored in `.env`) and saves it to `raw/` |
| **Transform** | Renames the `Variable_code` column to `variable_code`, then keeps only `Year`, `Value`, `Units`, `variable_code`, saving the result to `transformed/` |
| **Load** | Copies the transformed file into `Gold/`|

Every stage prints a status message to the terminal (and append to `cron.log` when
run via cron) confirming success or failure, so the pipeline is easy to
audit.
---

## 2. Folder Structure

```
cde-linux-git/
├── Gold/
│   └── 2023_year_finance.csv         # Final, load-ready output
├── raw/
│   └── annual-enterprise-survey-2023-financial-year-provisional.csv  # Raw downloaded file
├── transformed/
│   └── 2023_year_finance.csv         # Cleaned/selected columns
├── .env                               # Environment variables (NOT committed to git)
├── .gitignore                         # Excludes .env, log
├── cron.log                           # Output log from scheduled cron runs
├── etl.sh                             # Main bash ETL script
├── move_files.sh                      # moves all CSV and JSON files from one folder to another
└── README.md                          # This file
```

---

## 3. Prerequisites

- Linux / WSL 
- `curl` (for downloading the file)
- `python3` (standard library only — no extra packages needed)
- `cron` (for scheduling — installed by default on most Linux distros)

---

## 4. Environment Variables (`.env`)

The download URL is stored in a `.env` file in the project root, which `etl.sh` loads with `source .env`.

Create a `.env` file (this file is git-ignored and should never be committed) with the following content:

```bash
csv_url="https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv"
```

---

## 5. The ETL Script (`etl.sh`)

### 5.1 Script Safety & Setup

```bash
set -e
```
Causes the script to **exit immediately** if any command fails, preventing
it from silently continuing with bad/missing data.

```bash
cd "$(dirname "$0")"
```
Moves into the directory where the script itself lives, so it can be run
from anywhere and still find `.env`, `raw/`, `transformed/`, and
`Gold/` correctly.

```bash
source .env
```
Loads `csv_url` from `.env` into the current shell session.

### 5.2 Extract

```bash
file='raw/data.csv'
curl -o "$file" "$csv_url"
```
Downloads the CSV from `csv_url` and saves it as `raw/data.csv`.

```bash
if [ -f "$file" ]; then
    echo 'File Saved Successfully to raw/'
else
    echo 'File Not Saved Successfully to raw/'
fi
```
Confirms the file exists in `raw/` after the download, and prints a clear
success/failure message.

### 5.3 Transform

**Step 1 — Rename column:**
```bash
sed -i '1s/Variable_code/variable_code/' "$file"
```
Edits only the first line (the header row) of the CSV, replacing
`Variable_code` with `variable_code`.

**Step 2 — Select columns:**
```bash
python3 -c "..."
```
Reads the raw CSV with `csv.DictReader`, then writes out only the
`Year`, `Value`, `Units`, and `variable_code` columns using
`csv.DictWriter`, saving the result to:

```bash
transformed_file='transformed/2023_year_finance.csv'
```

**Step 3 — Confirm:**
```bash
if [ -f "$transformed_file" ]; then
    echo "Transformed File Exists In transformed/"
else
    echo "File Not Found In transformed/"
fi
```

### 5.4 Load

```bash
gold_file='Gold/2023_year_finance.csv'
cp "$transformed_file" "$gold_file"
```
Copies the transformed file into the `Gold/` folder 

```bash
if [ -f "$gold_file" ]; then
    echo "Successfully Saved the Transformed File to Gold/"
else
    echo "File Not Found in Gold/"
fi
```
Confirms the final file landed in `Gold/`.

### 5.5 Running the Script Manually
Expected output looks like:

```
Working directory set to: /path/to/cde-linux-git
The bash script is running in /path/to/cde-linux-git
File Successfully Downloaded to raw/
File Saved Successfully to raw/
Variable_code Column Successfully Renamed to variable_code
File Successfully Transformed and Saved to transformed/
Transformed File Exists In transformed/
Successfully Loaded the Transformed File to Gold
Successfully Saved the Transformed File to Gold/
```

---

## 6. Scheduling with Cron

### 6.1 Crontab Syntax

A crontab line has the format:

```
* * * * * command-to-run
│ │ │ │ │
│ │ │ │ └── day of week (0–6, Sunday=0)
│ │ │ └──── month (1–12)
│ │ └────── day of month (1–31)
│ └──────── hour (0–23)
└────────── minute (0–59)
```

### 6.2 Scheduling with cron

```bash
0 0 * * * /mnt/c/Users/DELL/Documents/de_github_projects/cde-linux-git/etl.sh >> /mnt/c/Users/DELL/Documents/de_github_projects/cde-linux-git/cron.log 2>&1
```

Breakdown:
- `0 0 * * *` → minute `0`, hour `0`, every day, every month, every weekday
  → runs **once a day at 12:00 AM (midnight)**.
- `/mnt/c/Users/DELL/Documents/de_github_projects/cde-linux-git/etl.sh` → the absolute path to the       script 
- `>> cron.log` → appends all standard output to `cron.log` instead of
  discarding it.
- `2>&1` → redirects standard **error** into the same stream as standard
  output, so error messages are captured in `cron.log` too, not lost.

### 6.3 How to Set It Up

```bash
crontab -e
```
Opens your personal crontab in a nano editor. Add the line from §6.2 (with the
correct absolute path for your machine), save, and exit.

Verify it was saved:
```bash
crontab -l
```

### 6.4 Checking It Ran

After midnight, check the log:
```bash
cat cron.log
```
You should see the same step-by-step output described in §5.5, appended
with each day's run.

---


## 7. File-Moving Script (`move_files.sh`)

A small standalone Bash script that moves all CSV and JSON files from one folder into another. It works whether there's one matching file or many, since Bash's glob expansion
(`*.csv`, `*.json`) passes every match to `mv` in a single call.

### 7.1 Script Breakdown

```bash
set -e
```
Exits immediately if any command fails 

```bash
source_dir="/mnt/c/Users/DELL/Downloads/"
destination_dir="/mnt/c/Users/DELL/Documents/json_and_csv"
```
Defines the two folders involved. As written, files are moved **out of**
`Documents/json_and_csv/` and **into** `Downloads/`.

```bash
mv "$source_dir"*.csv "$destination_dir"
mv "$source_dir"*.json "$destination_dir"
```
Moves all `.csv` files, then all `.json` files, from `source_dir` to
`destination_dir`. Because `*.csv` and `*.json` are shell globs, this
naturally handles **any number** of matching files — one, several, or
none — without needing a loop.
```

```

## 8. `.gitignore`

The `.gitignore` file should include:

```
.env
cron.log
```

This keeps secrets (the download URL) and log out of version
control, so the git repo only tracks code and documentation.

---

## 9. Future Improvements
- Add email/Slack notification on failure.