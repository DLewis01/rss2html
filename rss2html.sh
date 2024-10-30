#!/bin/bash

# Variables
DEBUG=0
RSS_URL="https://my.com/my.rss" #i.e. http://online.wsj.com/xml/rss/3_7011.xml
OUTPUT_DIR="/var/www/html/rss"  #maybe a webdirectory to turn it into a html page, or /tmp if you want it for other purposes.

#dont modify these
OUTPUT_FILE="$OUTPUT_DIR/index.html"
RSS_FILE="${RSS_URL##*/}"  #will output the my.rss part of $RSS_URL
TEMP_FILE="/tmp/$RSS_FILE"

BODY_OUTPUT_FILE="./rss_include.inc"
TEMP_FILE="/tmp/rss_status.rss"
has_items=0  # Flag to track if any items were found

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Fetch the RSS feed
curl -s "$RSS_URL" -o "$TEMP_FILE"

if [ $DEBUG -eq 1 ]
then
    cat "$TEMP_FILE"
fi

# Start HTML output for the full page
echo "<!DOCTYPE html>" > "$FULL_OUTPUT_FILE"
echo "<html lang='en'>" >> "$FULL_OUTPUT_FILE"
echo "<head>" >> "$FULL_OUTPUT_FILE"
echo "  <meta charset='UTF-8'>" >> "$FULL_OUTPUT_FILE"
echo "  <meta name='viewport' content='width=device-width, initial-scale=1.0'>" >> "$FULL_OUTPUT_FILE"
echo "  <title>AWS Status Monitor</title>" >> "$FULL_OUTPUT_FILE"
echo "  <style>body { font-family: Arial, sans-serif; } h1 { color: #ff9900; } .status { margin-bottom: 10px; }</style>" >> "$FULL_OUTPUT_FILE"
echo "</head>" >> "$FULL_OUTPUT_FILE"
echo "<body>" >> "$FULL_OUTPUT_FILE"

# Start HTML output for the body-only file
echo "<div class='status-feed'>" > "$BODY_OUTPUT_FILE"
echo "  <h4 style=\"color: #ff9900; font-family: Arial, sans-serif;\">AWS Service Status</h4>" >> "$BODY_OUTPUT_FILE"



echo "<div class='status-feed'>" >> "$FULL_OUTPUT_FILE"
echo "  <h1>AWS Service Status</h1>" >> "$FULL_OUTPUT_FILE"

echo "Local date $(date +'%d/%m/%Y') <br>" >> "$FULL_OUTPUT_FILE"
echo "Local date $(date +'%d/%m/%Y') <br>" >> "$BODY_OUTPUT_FILE"



# Parse RSS feed and convert it to HTML
inside_item=0
description=""
inside_description=0

while read -r line; do
  # Remove CDATA section markers
  line=$(echo "$line" | sed -e 's/<!\[CDATA\[//g' -e 's/\]\]>//g')

  if [[ "$line" =~ \<item\> ]]; then
    inside_item=1
    has_items=1  # Set flag if any items are found
  fi

  if [[ "$line" =~ \</item\> ]]; then
    inside_item=0
    inside_description=0
  fi

  if [[ "$inside_item" -eq 1 ]]; then
    if [[ "$line" =~ \<title\>(.*)\<\/title\> ]]; then
      title="${BASH_REMATCH[1]}"
      if [[ "$title" != "AWS Service Status RSS Feed" ]]; then
        echo "    <div class='status'>" >> "$FULL_OUTPUT_FILE"
        echo "    <div class='status'>" >> "$BODY_OUTPUT_FILE"
        echo "      <strong>${title}</strong><br>" >> "$FULL_OUTPUT_FILE"
        echo "      <strong>${title}</strong><br>" >> "$BODY_OUTPUT_FILE"
      fi
    elif [[ "$line" =~ \<pubDate\>(.*)\<\/pubDate\> ]]; then
      pubDate="${BASH_REMATCH[1]}"
      echo "      <em>${pubDate}</em><br>" >> "$FULL_OUTPUT_FILE"
      echo "      <em>${pubDate}</em><br>" >> "$BODY_OUTPUT_FILE"
    elif [[ "$line" =~ \<description\>(.*)\<\/description\> ]]; then
      # If <description> and </description> are on the same line
      description="${BASH_REMATCH[1]}"
      echo "      <p>${description}</p>" >> "$FULL_OUTPUT_FILE"
      echo "      <p>${description}</p>" >> "$BODY_OUTPUT_FILE"
      echo "    </div>" >> "$FULL_OUTPUT_FILE"
      echo "    </div>" >> "$BODY_OUTPUT_FILE"
    elif [[ "$line" =~ \<description\> ]]; then
      # Start description collection if <description> is found without </description>
      inside_description=1
      description="${line#<description>}"  # Remove <description> tag
    elif [[ "$line" =~ \</description\> ]]; then
      # End description collection
      inside_description=0
      description="${description} ${line%</description>}"  # Remove </description> tag
      echo "      <p>${description}</p>" >> "$FULL_OUTPUT_FILE"
      echo "      <p>${description}</p>" >> "$BODY_OUTPUT_FILE"
      echo "    </div>" >> "$FULL_OUTPUT_FILE"
      echo "    </div>" >> "$BODY_OUTPUT_FILE"
    elif [[ "$inside_description" -eq 1 ]]; then
      # Continue appending lines to description if inside_description flag is set
      description="${description} ${line}"
    fi
  fi
done < "$TEMP_FILE"




# If no items were found, display "No recent issues"
if [ $has_items -eq 0 ]; then
  echo "    <p>No recent issues</p>" >> "$FULL_OUTPUT_FILE"
  echo "    <p>No recent issues</p>" >> "$BODY_OUTPUT_FILE"
fi

# Close HTML tags for both files
echo "  </div>" >> "$FULL_OUTPUT_FILE"
echo "</body>" >> "$FULL_OUTPUT_FILE"
echo "</html>" >> "$FULL_OUTPUT_FILE"

echo "  </div>" >> "$BODY_OUTPUT_FILE"

# Clean up
rm "$TEMP_FILE"

echo "AWS status page has been updated at $FULL_OUTPUT_FILE (full) and $BODY_OUTPUT_FILE (body-only)."
cp $FULL_OUTPUT_FILE ./
#cp $BODY_OUTPUT_FILE ./
