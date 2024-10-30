function Get-KubectlSnapshot {
    param (
        [string]$Namespace,
        [string]$ResourceKind,
        [string]$ResourceName
    )

    Write-Host "Fetching current cluster state for $ResourceKind/$ResourceName in namespace $Namespace`n" -ForegroundColor Green

    $kubectlCmd = "get $ResourceKind $ResourceName -n $Namespace -o yaml"

    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "kubectl"
        $processInfo.Arguments = $kubectlCmd
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo

        # Start the kubectl process
        $process.Start() | Out-Null

        # Capture output and error
        $output = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()

        $process.WaitForExit()

        if ($stderr) {
            Write-Host "`nError fetching cluster snapshot:`n" -ForegroundColor Red
            Write-Host $stderr -ForegroundColor Red
            return $null
        }

        # Return the YAML content from the cluster
        return $output

    } catch {
        Write-Host "Unexpected error while fetching the snapshot: $_" -ForegroundColor Red
        return $null
    }
}

function Read-YamlFile {
    param (
        [string]$FilePath
    )

    # Check if FilePath is provided
    if (-not $FilePath) {
        Write-Error "Error: No file path provided. Please specify the path to a YAML file."
        return $null
    }

    # Check if the file exists
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Error: File not found at path '$FilePath'. Please check the file path and try again."
        return $null
    }

    # Try to read and parse the YAML file
    try {
        $yamlContent = Get-Content -Path $FilePath -Raw | ConvertFrom-Yaml
    }
    catch {
        Write-Error "Error: Unable to read or parse the YAML file at '$FilePath'. Ensure the file is in correct YAML format."
        return $null
    }

    # Ensure the required fields are available
    if (-not $yamlContent.kind -or -not $yamlContent.metadata.name) {
        Write-Error "Error: The YAML file at '$FilePath' is missing required fields ('kind' or 'metadata.name')."
        return $null
    }

    # Set namespace to 'default' if not specified
    $namespace = if ($yamlContent.metadata.namespace) { $yamlContent.metadata.namespace } else { "default" }

    # Return the extracted information as a PSCustomObject
    return [PSCustomObject]@{
        Kind      = $yamlContent.kind
        Name      = $yamlContent.metadata.name
        Namespace = $namespace
    }
}

function Remove-UnwantedBlocks {
    param (
        [string[]]$lines
    )

    $result = @()
    $insideStatusBlock = $false

    foreach ($line in $lines) {
        # Skip the 'status' block
        if ($line -match "^\s*status:") {
            $insideStatusBlock = $true
            continue
        }

        # Skip the 'creationTimestamp' line
        if ($line -match "^\s*creationTimestamp:") {
            continue
        }

        # Detect the end of the 'status' block (next unindented key or end of file)
        if ($insideStatusBlock -and $line -match "^\S") {
            $insideStatusBlock = $false
        }

        # If not inside 'status', add the line to the result
        if (-not $insideStatusBlock) {
            $result += $line
        }
    }

    return $result
}

function Compare-Lines {
    param (
        [string]$LocalFile,       # The local manifest file path
        [string]$CompareFile,     # The file to compare against
        [switch]$IsCluster        # Switch to indicate if the second file is from the cluster
    )
    
    $content1 = Get-Content $LocalFile -Raw
    $content2 = Get-Content $CompareFile -Raw

    # Determine labels based on whether we are comparing with the cluster
    $file1Label = "File1"
    $file2Label = if ($IsCluster) { "Cluster" } else { "File2" }

    # Split into lines and remove trailing whitespace
    $lines1 = $content1 -split "`n" | ForEach-Object { $_.TrimEnd() }
    $lines2 = $content2 -split "`n" | ForEach-Object { $_.TrimEnd() }

    # Remove unwanted blocks like 'status' and 'creationTimestamp'
    $lines1 = Remove-UnwantedBlocks -lines $lines1
    $lines2 = Remove-UnwantedBlocks -lines $lines2

    # Create hashsets of the lines for easy comparison, ignoring line order
    $set1 = @{ }
    $set2 = @{ }

    # Track line numbers for File1 and File2 (or Cluster)
    for ($i = 0; $i -lt $lines1.Length; $i++) {
        $line = $lines1[$i]
        $set1[$line.TrimStart()] = @{ LineNumber = $i + 1; Content = $line }
    }
    for ($i = 0; $i -lt $lines2.Length; $i++) {
        $line = $lines2[$i]
        $set2[$line.TrimStart()] = @{ LineNumber = $i + 1; Content = $line }
    }

    # Table to store the differences
    $comparisonResults = @()

    # Replace spaces with visible marker for leading/trailing whitespace issues
    function ShowWhitespace($line) {
        return $line -replace " ", "␣"
    }

    # Compare lines in File1 against File2 (or Cluster)
    foreach ($line in $set1.Keys) {
        if (-not $set2.ContainsKey($line)) {
            $comparisonResults += [PSCustomObject]@{
                LineNumber = $set1[$line].LineNumber
                File       = $file1Label
                Content    = ShowWhitespace($set1[$line].Content)
                Difference = "Only in $file1Label"
            }
        } elseif ($set1[$line].Content -ne $set2[$line].Content) {
            if ($set1[$line].Content.TrimStart() -eq $set2[$line].Content.TrimStart()) {
                $comparisonResults += [PSCustomObject]@{
                    LineNumber = "$($set1[$line].LineNumber)/$($set2[$line].LineNumber)"
                    File       = "Both Files"
                    Content    = "Leading whitespace difference"
                    Difference = "${file1Label}: $($set1[$line].Content -replace ' ', '␣')`n${file2Label}: $($set2[$line].Content -replace ' ', '␣')"
                }
            } else {
                $comparisonResults += [PSCustomObject]@{
                    LineNumber = "$($set1[$line].LineNumber)/$($set2[$line].LineNumber)"
                    File       = "Both Files"
                    Content    = "Content difference"
                    Difference = "${file1Label}: $($set1[$line].Content -replace ' ', '␣')`n${file2Label}: $($set2[$line].Content -replace ' ', '␣')"
                }
            }
        }
    }

    # Compare lines in File2 (or Cluster) against File1 to find lines only in File2/Cluster
    foreach ($line in $set2.Keys) {
        if (-not $set1.ContainsKey($line)) {
            $comparisonResults += [PSCustomObject]@{
                LineNumber = $set2[$line].LineNumber
                File       = $file2Label
                Content    = ShowWhitespace($set2[$line].Content)
                Difference = "Only in $file2Label"
            }
        }
    }

    # Set the max width for each box
    $boxWidth = 50

    # Display file path information
    Write-Host "File1 = $LocalFile" -ForegroundColor Cyan
    if ($IsCluster) {
        Write-Host "Cluster" -ForegroundColor Cyan
    } else {
        Write-Host "File2 = $CompareFile" -ForegroundColor Cyan
    }
    
    # Add a note for whitespace representation
    Write-Host "`nNote: Spaces are represented as '␣' in the output." -ForegroundColor Magenta

# Simple formatted output for the results
Write-Host ""
Write-Host "==================== Comparison Summary ====================" -ForegroundColor Magenta

if ($comparisonResults.Count -gt 0) {
    foreach ($result in $comparisonResults) {
        $lineFormatted = "Line: $($result.LineNumber)"
        $fileFormatted = "File: $($result.File)"
        $contentFormatted = "Content: $($result.Content)"

        Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
        Write-Host "$lineFormatted" -ForegroundColor Yellow
        Write-Host "$fileFormatted" -ForegroundColor Cyan
        Write-Host "$contentFormatted" -ForegroundColor Red
    }
    Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
} else {
    Write-Host "No differences found" -ForegroundColor Green
}
Write-Host "============================================================" -ForegroundColor Magenta

}

function Compare-Files {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LocalFile,         # The local manifest file path
        [string]$CompareFile        # The second file to compare against (optional)
    )

    # Check if LocalFile exists
    if (-not (Test-Path -Path $LocalFile)) {
        Write-Error "Error: Local file not found at path '$LocalFile'. Please check the file path and try again."
        return
    }

    # Parse the YAML file to extract the kind, name, and namespace
    $resourceInfo = Read-YamlFile -FilePath $LocalFile
    if (-not $resourceInfo) {
        Write-Error "Error: Could not extract resource information from '$LocalFile'. Please ensure the file is in a valid YAML format."
        return
    }

    # If CompareFile is not provided, fetch the cluster snapshot for comparison
    if (-not $CompareFile) {
        try {
            # Attempt to fetch the cluster snapshot
            $clusterSnapshot = Get-KubectlSnapshot -Namespace $resourceInfo.Namespace -ResourceKind $resourceInfo.Kind -ResourceName $resourceInfo.Name
        }
        catch {
            Write-Error "Error: Failed to fetch the cluster snapshot. Ensure that 'kubectl' is configured correctly and accessible."
            return
        }

        # Check if the snapshot retrieval was successful
        if (-not $clusterSnapshot) {
            Write-Error "Error: No data retrieved from the cluster snapshot. Verify resource details (namespace, kind, name) and cluster access."
            return
        }

        # Attempt to write the cluster snapshot to a temporary file
        try {
            $CompareFile = "$env:TEMP\$($resourceInfo.Name)-cluster-snapshot.yaml"
            $clusterSnapshot | Out-File -FilePath $CompareFile -Force
        }
        catch {
            Write-Error "Error: Unable to write the cluster snapshot to temporary file '$CompareFile'. Check permissions and available space."
            return
        }
    }

    # Compare the local file with the provided comparison file (either cluster snapshot or another local file)
    Compare-Lines -LocalFile $LocalFile -CompareFile $CompareFile -IsCluster:($CompareFile -like "*-cluster-snapshot.yaml")

    # If we created a temporary cluster snapshot, clean it up after comparison
    if ($CompareFile -like "*-cluster-snapshot.yaml") {
        Remove-Item $CompareFile -Force
    }
}

