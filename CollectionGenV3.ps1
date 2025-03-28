do {
    Clear-Host  # Clears the console for a fresh start

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

    # Get all files with relevant extensions
    $Files = Get-ChildItem -Path $SearchDirectory -Recurse -File -Include *.zip,*.7z,*.rar

    # Total files count for progress tracking
    $TotalFiles = $Files.Count
    $CurrentFile = 0

    # Initialize results with the placeholder as the first entry
    $Results = @("/Roms/Game Boy Advance (MGBA)/Placeholder.zip")

    Write-Host "Searching for matching files... Please wait."

    # Search for matching filenames first (faster than scanning file contents)
    foreach ($File in $Files) {
        $CurrentFile++
        Write-Progress -Activity "Searching files" -Status "Processing file $CurrentFile of $TotalFiles" -PercentComplete (($CurrentFile / $TotalFiles) * 100)

        $RelativeDirectory = $File.DirectoryName -replace [regex]::Escape($SearchDirectory), "" -replace "\\", "/"  
        $RelativeFilePath = $File.Name

        # Check if the filename contains any of the specified keywords
        if ($Keywords | Where-Object { $File.Name -match $_ }) {
            $Results += "/Roms$RelativeDirectory/$RelativeFilePath"
        }
    }

    # Clear progress bar
    Write-Progress -Activity "Searching files" -Completed
    Write-Host "Search complete."

    # Display results
    if ($Results.Count -gt 1) {  # Ensure we have results other than the placeholder
        $Results | ForEach-Object { Write-Output $_ }
    } else {
        Write-Host "No matching files found."
    }

    # Ask the user if they want to save results
    $SaveResults = Read-Host "Do you want to save results to a file? (Y/N)"

    if ($SaveResults -match "^[Yy]$") {
        # Clean up the collection name to create a valid filename (allow spaces)
        $SafeCollectionName = $CollectionName -replace '[^\w\s-]', ''  # Preserves spaces
        $OutputFile = Join-Path $OutputDirectory "$SafeCollectionName.txt"

        # Save the results to the file
        $Results | Out-File -Encoding UTF8 $OutputFile
        Write-Host "Results saved to: $OutputFile"
    }

    # Ask the user if they want to create another collection
    $RepeatSearch = Read-Host "Do you want to create another collection? (Y/N)"

} while ($RepeatSearch -match "^[Yy]$")  # Loop until the user says "N"

Write-Host "Exiting script. Have a great day!"
