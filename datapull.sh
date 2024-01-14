#!/bin/bash

# MySQL credentials
mysql_user="your_mysql_user"
mysql_password="your_mysql_password"
mysql_database="your_mysql_database"

# URL of the ZIP file
base_url="http://mis.nyiso.com/public/csv/damlbmp/"

# Calculate the previous month
prev_month=$(date -d "last month" +"%Y%m")

# Form the URL for the previous month
url="${base_url}${prev_month}01damlbmp_gen_csv.zip"

# Directory to store the downloaded and extracted files
download_dir="/path/to/download/directory"

# MySQL data file directory
mysql_data_dir="/var/lib/mysql-files/NYISO_Data"

# Check if the directories exist, create them if not
mkdir -p "$download_dir"

# Download the ZIP file
wget "$url" -P "$download_dir"

# Extract the contents of the ZIP file
unzip "$download_dir/${prev_month}01damlbmp_gen_csv.zip" -d "$download_dir"

# Move the CSV files to the MySQL data file directory
mv "$download_dir"/*.csv "$mysql_data_dir/"

# MySQL LOAD DATA INFILE command for each CSV file
for csv_file in "$mysql_data_dir"/*.csv; do
    mysql -u"$mysql_user" -p"$mysql_password" -D "$mysql_database" <<EOF
    LOAD DATA INFILE '$csv_file'
    INTO TABLE lmps_tmp
    FIELDS TERMINATED BY ','
    ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
    IGNORE 1 ROWS;
EOF
done

# MySQL procedure: Append data from lmps_tmp to lmps_test
mysql -u"$mysql_user" -p"$mysql_password" -D "$mysql_database" <<EOF
INSERT INTO lmps_test SELECT * FROM lmps_tmp;
TRUNCATE TABLE lmps_tmp;
EOF

# Additional cleanup (optional)
# Remove the downloaded ZIP files and extracted files
rm "$download_dir"/*.zip
rm "$mysql_data_dir"/*.csv

# Save this script and make it executable:
# chmod +x script_name.sh

# You can then run this script as a cron job:
# For example, to run every day at 2 AM, add the following line to your crontab:
# 0 2 * * * /path/to/script_name.sh
