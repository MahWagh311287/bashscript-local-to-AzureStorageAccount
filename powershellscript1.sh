# Install and import the Azure PowerShell module if not already installed
# Install-Module -Name Az -AllowClobber -Force -Scope CurrentUser if not already installed
# Install-Module -Name Az -Force -AllowClobber
# Import-Module Az
# Connect-AzAccount -Tenant <Enter Tenant ID> if not connected.

# Set your Azure Storage Account details
$storageAccountName = "enter storage account name"
$containerName = "enter container name"
$directoryName = "enter virtual directory name"
$resourceGroup = <Enter Resource Group Name>

# Mapping of subdirectories to local paths
$subdirectoryToLocalPathMapping = @{
    "client-korea" = "C:\_LES_\CLIENTS\CRITEO\MASTER_DATA\CRITEO AUSTRALIA"
    "client-japan" = "C:\_LES_\CLIENTS\CRITEO\MASTER_DATA\CRITEO BRASIL"




    # Add more mappings if necessary
}

# Get Azure Storage Account Key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -AccountName $storageAccountName).Value[0]

# Create Azure Storage Context
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

foreach ($subdirectory in $subdirectoryToLocalPathMapping.Keys) {
    # Retrieve all XML blobs in the 'aps-input' folder for the current subdirectory
    $xmlBlobs = Get-AzStorageBlob -Container $containerName -Context $ctx | 
                 Where-Object { $_.Name -match "^$directoryName/$subdirectory/[^/]+\.xml$" } | 
                 Sort-Object LastModified -Descending

    # Select the latest XML blob
    $latestXmlBlob = $xmlBlobs | Select-Object -First 1

    if ($latestXmlBlob) {
        $blobName = $latestXmlBlob.Name
        $localPath = $subdirectoryToLocalPathMapping[$subdirectory]

        # Ensure the local directory is set and not null
        if (-not $localPath) {
            Write-Host "Local directory not found for blob: $blobName"
            Continue
        }

        $localFileName = Join-Path -Path $localPath -ChildPath $blobName.Split('/')[-1]

        # Ensure the local directory exists, create if not
        if (-not (Test-Path -Path $localPath -PathType Container)) {
            New-Item -Path $localPath -ItemType Directory -Force | Out-Null
        }

        # Download the Blob
        Get-AzStorageBlobContent -Container $containerName -Blob $blobName -Destination $localFileName -Context $ctx -Force
        Write-Host "Downloaded blob: $blobName to $localFileName"
    } else {
        Write-Host "No XML file found for subdirectory: $subdirectory"
    }
}

Write-Host "XML file transfers completed successfully."
