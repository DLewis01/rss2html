#!/bin/bash

# Variables
RSS_URL="https://my.com/all.rss"
OUTPUT_DIR="/var/www/html/aws"
OUTPUT_FILE="$OUTPUT_DIR/index.html"
TEMP_FILE="/tmp/aws_status.rss"

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Fetch the RSS feed
curl -s "$RSS_URL" -o "$TEMP_FILE"

# Start HTML output
echo "<!DOCTYPE html>" > "$OUTPUT_FILE"
echo "<html lang='en'>" >> "$OUTPUT_FILE"
echo "<head>" >> "$OUTPUT_FILE"
echo "  <meta charset='UTF-8'>" >> "$OUTPUT_FILE"
echo "  <meta name='viewport' content='width=device-width, initial-scale=1.0'>" >> "$OUTPUT_FILE"
echo "  <title>AWS Status Monitor</title>" >> "$OUTPUT_FILE"
echo "  <style>body { font-family: Arial, sans-serif; } h1 { color: #ff9900; } .status { margin-bottom: 10px; }</style>" >> "$OUTPUT_FILE"
echo "</head>" >> "$OUTPUT_FILE"
echo "<body>" >> "$OUTPUT_FILE"
echo "  <h1>AWS Service Status</h1>" >> "$OUTPUT_FILE"

# Parse RSS feed and convert it to HTML
echo "  <div class='status-feed'>" >> "$OUTPUT_FILE"
inside_item=0

while read -r line; do
  # Remove CDATA section markers
  line=$(echo "$line" | sed -e 's/<!\[CDATA\[//g' -e 's/\]\]>//g')

  if [[ "$line" =~ \<item\> ]]; then
    inside_item=1
  fi

  if [[ "$line" =~ \</item\> ]]; then
    inside_item=0
  fi

  if [[ "$inside_item" -eq 1 ]]; then
    if [[ "$line" =~ \<title\>(.*)\<\/title\> ]]; then
      title="${BASH_REMATCH[1]}"
      if [[ "$title" != "RSS Feed" ]]; then
        echo "    <div class='status'>" >> "$OUTPUT_FILE"
        echo "      <strong>${title}</strong><br>" >> "$OUTPUT_FILE"
      fi
    elif [[ "$line" =~ \<pubDate\>(.*)\<\/pubDate\> ]]; then
      pubDate="${BASH_REMATCH[1]}"
      echo "      <em>${pubDate}</em><br>" >> "$OUTPUT_FILE"
    elif [[ "$line" =~ \<description\>(.*)\<\/description\> ]]; then
      description="${BASH_REMATCH[1]}"
      echo "      <p>${description}</p>" >> "$OUTPUT_FILE"
      echo "    </div>" >> "$OUTPUT_FILE"
    fi
  fi
done < "$TEMP_FILE"

echo "  </div>" >> "$OUTPUT_FILE"

# End HTML output
echo "</body>" >> "$OUTPUT_FILE"
echo "</html>" >> "$OUTPUT_FILE"

# Clean up
rm "$TEMP_FILE"

echo "RSS page has been updated at $OUTPUT_FILE"
