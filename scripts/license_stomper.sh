#!/bin/bash

FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

# Check if the file exists
if [ ! -f "$FILE" ]; then
  echo "Error: File '$FILE' does not exist."
  exit 1
fi

# Use sed to replace the line
sed -i "s/\.data\.status\.toLowerCase() !== 'active'/\.data\.status\.toLowerCase() == 'active'/g" "$FILE"

echo "Replacement completed in file: $FILE"
