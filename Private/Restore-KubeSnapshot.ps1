function Restore-KubeSnapshot {
    [CmdletBinding()]
    param (
        [string]$InputPath = "./snapshots",  # Path to the directory or a specific file
        [switch]$Force                      # Force switch to skip confirmation
    )

    # Ensure verbose output is only shown when requested
    $VerbosePreference = "SilentlyContinue"

    # Validate if the input path is a directory or a file
    if (-not (Test-Path -Path $InputPath)) {
        Write-Host "Error: The specified input path does not exist: $InputPath" -ForegroundColor Red
        return
    }

# Prompt for confirmation unless -Force is provided
if (-not $Force) {
    $confirmation = Read-Host "Are you sure you want to restore resources from $InputPath? Type 'yes' or 'y' to continue."
    if ($confirmation.ToLower() -notin @('yes', 'y')) {
        Write-Host "Restore operation canceled." -ForegroundColor Yellow
        return
    }
}

    # Determine if InputPath is a file or directory
    $isFile = Test-Path $InputPath -PathType Leaf
    $isDirectory = Test-Path $InputPath -PathType Container

    if ($isDirectory) {
        # Get the list of YAML files in the directory
        $yamlFiles = Get-ChildItem -Path $InputPath -Filter *.yaml

        if (-not $yamlFiles) {
            Write-Host "No YAML files found in the specified input directory: $InputPath" -ForegroundColor Yellow
            return
        }

    } elseif ($isFile) {
        # If it's a file, process the single file
        $yamlFiles = @((Get-Item $InputPath))  # Wrap single file in array for consistent processing

    } else {
        Write-Host "Error: Invalid input. Please provide a valid file or directory path." -ForegroundColor Red
        return
    }

    # Restore each resource from its YAML file
    foreach ($file in $yamlFiles) {
        $filePath = "`"$($file.FullName)`""  # Add quotes around the file path
        $kubectlCmd = "kubectl apply -f $filePath"

        Write-Host "Restoring resource from file: $filePath" -ForegroundColor Green
        Write-Verbose "Running command: $kubectlCmd"

        try {
            # Capture the output and errors using Start-Process for better control over success/failure
            $process = Start-Process -FilePath "kubectl" -ArgumentList "apply -f $filePath" -NoNewWindow -Wait -PassThru -ErrorAction Stop

            if ($process.ExitCode -ne 0) {
                throw "Failed to restore resource from: $filePath"
            }

            Write-Host "Resource from '$filePath' restored successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error occurred while restoring resource from: $filePath" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}
