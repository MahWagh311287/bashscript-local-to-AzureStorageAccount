#!/bin/bash

# Define variables
storageAccount="enter storage account name"
containerName="enter container name"
sourceDirectory="Invoice"  # Source directory where XML files are currently stored
targetDirectory="Invoice/Imported" # Target directory where you want to move the XML files within the same container
localDirectory="/SFTP/READSOFT/INVOICE/IN"

# Generate SAS token for the source directory
sasToken="Enter SAS Token"

# Debugging command to print the Azure CLI command with SAS token
echo "Debugging command with SAS token:"
az storage blob list --container-name "$containerName" --prefix "$sourceDirectory/" --query "[?ends_with(name, '.xml')].name" --account-name "$storageAccount" --sas-token "$sasToken" --output tsv

# List XML files in the source directory
echo "Listing XML files in the source directory..."
xmlFiles=$(az storage blob list --container-name "$containerName" --prefix "$sourceDirectory/" --query "[?ends_with(name, '.xml')].name" --account-name "$storageAccount" --sas-token "$sasToken" --output tsv)

# Upload .xml files into local directory
azcopy copy "https://${storageAccount}.blob.core.windows.net/${containerName}/${sourceDirectory}/*${sasToken}" "${localDirectory}" --include-pattern="*.xml" --recursive=false

if [ -z "$xmlFiles" ]; then
    echo "No XML files found in the source directory. Exiting script."
    exit 1
fi

# Copy XML files to the target directory within the same container
echo "Copying XML files to the target directory..."
for file in $xmlFiles; do
    echo "Copying file: $file"
    az storage blob copy start --source-uri "https://$storageAccount.blob.core.windows.net/$containerName/$file$sasToken" --destination-container "$containerName" --destination-blob "$targetDirectory/${file##*/}" --account-name "$storageAccount" --sas-token "$sasToken" || {
        echo "Error copying file: $file"
        exit 1
    }
done

# Wait for the copy operations to complete
echo "Waiting for the copy operations to complete..."
while true; do
    allCopied=true
    for file in $xmlFiles; do
        targetBlob="$targetDirectory/${file##*/}"
        copyStatus=$(az storage blob show --container-name "$containerName" --name "$targetBlob" --query "properties.copy.status" --account-name "$storageAccount" --sas-token "$sasToken"  --output tsv)
        if [ "$copyStatus" != "success" ]; then
            allCopied=false
            break
        fi
    done
    if $allCopied; then
        break
    else
        sleep 5
    fi
done

# Remove XML files from the source directory
echo "Removing XML files from the source directory..."
for file in $xmlFiles; do
    echo "Removing file: $file"
    az storage blob delete --container-name "$containerName" --name "$file" --account-name "$storageAccount"  --sas-token "$sasToken"

done