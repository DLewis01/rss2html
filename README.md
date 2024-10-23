# rss2html
A small bash script to turn a RSS feed into a html page

Put this script in a non world accessible account that has permission to write to your web directory
chmod +x rss2html.sh 

change this line to be the rss feed you want to convert
RSS_URL="https://my.com/all.rss"

Change this line to the directory you want to write the file to.
OUTPUT_DIR="/var/www/html/aws"

If you want it to run at a specific time, call it from a cron job.
