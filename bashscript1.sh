#!/bin/bash

# Azure Storage Account base URL
BASE_URL="https://<storageaccountname>.blob.core.windows.net/<container_name>/<virtual-directory_name>"

# Shared Access Signature (SAS) token
SAS_TOKEN="Enter Sas Token"

# Local directory containing the folders
LOCAL_DIR="/SFTP/READSOFT/VENDOR/OUT"

# Folders to be processed
FOLDERS=("client-korea" "client-japan")

# Function to generate a unique suffix
generate_suffix() {
    echo $(date +%s%N)
}

# Loop through each folder
for folder in "${FOLDERS[@]}"; do
    echo "Processing folder: $folder"

    # Full path to the local folder
    local_folder_path="${LOCAL_DIR}/${folder}"

    # Check if folder exists
    if [ -d "$local_folder_path" ]; then
        # Loop through each XML file in the folder
        for file in "${local_folder_path}"/*.xml; do
            # Skip if not a file
            [ -f "$file" ] || continue

            # Generate a unique suffix
            suffix=$(generate_suffix)

            # Extract filename
            filename=$(basename -- "$file")

            # New filename with the unique suffix
            new_filename="${filename%.*}_${suffix}.xml"

            # Destination URL
            dest_url="${BASE_URL}/${folder}/${new_filename}${SAS_TOKEN}"

            echo "Copying $file to $dest_url"
            sudo azcopy copy "$file" "$dest_url"
        done
    else
        echo "Folder not found: $local_folder_path"
    fi
done

echo "All files copied successfully."
