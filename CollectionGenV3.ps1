# Ask user for the collection name (used as the output file name)
$CollectionName = Read-Host "Enter the name of the collection"

# Ask user for multiple keywords (comma-separated)
$KeywordInput = Read-Host "Enter keywords to search for (separate with commas)"

# Convert input keywords into an array, trimming whitespace
$Keywords = $KeywordInput -split "," | ForEach-Object { $_.Trim() }

# Get the root directory of the drive where the script is running
$DriveRoot = (Get-Location).Drive.Name + ":\"

# Define the search and output directories
$SearchDirectory = Join-Path $DriveRoot "Roms"
$OutputDirectory = Join-Path $DriveRoot "Collections"

# Ensure the 'Roms' directory exists
if (!(Test-Path $SearchDirectory)) {
    Write-Host "The 'Roms' directory does not exist in the root of drive $DriveRoot. Please check the path."
    exit
}

# Ensure the 'Collections' directory exists, or create it
if (!(Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

# Get all files and count them for progress tracking
$Files = Get-ChildItem -Path $SearchDirectory -Recurse -File
$TotalFiles = $Files.Count
$CurrentFile = 0

# Initialize result storage
$Results = @()

# Search for files containing any of the keywords
Write-Host "Searching for matching files..."
foreach ($File in $Files) {
    $CurrentFile++
    Write-Progress -Activity "Searching files" -Status "Processing file $CurrentFile of $TotalFiles" -PercentComplete (($CurrentFile / $TotalFiles) * 100)

    $RelativeDirectory = $File.DirectoryName -replace [regex]::Escape($SearchDirectory), "" -replace "\\", "/"  # Convert to Unix-style path
    $RelativeFilePath = $File.Name

    # Check if the file contains any of the specified keywords
    foreach ($Keyword in $Keywords) {
        if (Select-String -Path $File.FullName -Pattern $Keyword -Quiet) {
            $Results += "/Roms$RelativeDirectory/$RelativeFilePath"
            break  # Stop checking once a match is found for this file
        }
    }
}

# Clear progress bar
Write-Progress -Activity "Searching files" -Completed
Write-Host "Search complete."

# Display results
if ($Results) {
    $Results | ForEach-Object { Write-Output $_ }
} else {
    Write-Host "No matching files found."
}

# Ask the user if they want to save results
$SaveResults = Read-Host "Do you want to save results to a file? (Y/N)"

if ($SaveResults -match "^[Yy]$") {
    # Clean up the collection name to create a valid filename
    $SafeCollectionName = $CollectionName -replace '[^\w\s-]', '' -replace ' ', '_'
    $OutputFile = Join-Path $OutputDirectory "$SafeCollectionName.txt"

    # Save the results to the file
    $Results | Out-File -Encoding UTF8 $OutputFile
    Write-Host "Results saved to: $OutputFile"
}
