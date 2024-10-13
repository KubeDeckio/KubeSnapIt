function Compare-Lines {
    param (
        [string]$File1Path,
        [string]$File2Path
    )
    
    $content1 = Get-Content $File1Path -Raw
    $content2 = Get-Content $File2Path -Raw

    # Split into lines and remove trailing whitespace
    $lines1 = $content1 -split "`n" | ForEach-Object { $_.TrimEnd() }
    $lines2 = $content2 -split "`n" | ForEach-Object { $_.TrimEnd() }

    # Find the index of "status:" in both files
    $indexStatus1 = $null
    $indexStatus2 = $null
    for ($i = 0; $i -lt $lines1.Length; $i++) {
        if ($lines1[$i] -match "^status:") {
            $indexStatus1 = $i
            break
        }
    }
    for ($i = 0; $i -lt $lines2.Length; $i++) {
        if ($lines2[$i] -match "^status:") {
            $indexStatus2 = $i
            break
        }
    }

    # Remove everything starting from "status:" in both files
    if ($indexStatus1 -ne $null) { $lines1 = $lines1[0..($indexStatus1 - 1)] }
    if ($indexStatus2 -ne $null) { $lines2 = $lines2[0..($indexStatus2 - 1)] }

    # Create hashsets of the lines for easy comparison, ignoring line order
    $set1 = @{ }
    $set2 = @{ }

    # Track line numbers for File1 and File2
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

    # Compare lines in File1 against File2
    foreach ($line in $set1.Keys) {
        if (-not $set2.ContainsKey($line)) {
            $comparisonResults += [PSCustomObject]@{
                LineNumber = $set1[$line].LineNumber
                File       = "File1"
                Content    = ShowWhitespace($set1[$line].Content)
                Difference = "Only in File1"
            }
        } elseif ($set1[$line].Content -ne $set2[$line].Content) {
            if ($set1[$line].Content.TrimStart() -eq $set2[$line].Content.TrimStart()) {
                $comparisonResults += [PSCustomObject]@{
                    LineNumber = "$($set1[$line].LineNumber)/$($set2[$line].LineNumber)"
                    File       = "Both Files"
                    Content    = "Leading whitespace difference"
                    Difference = "File1: $($set1[$line].Content -replace ' ', '␣')`nFile2: $($set2[$line].Content -replace ' ', '␣')"
                }
            } else {
                $comparisonResults += [PSCustomObject]@{
                    LineNumber = "$($set1[$line].LineNumber)/$($set2[$line].LineNumber)"
                    File       = "Both Files"
                    Content    = "Content difference"
                    Difference = "File1: $($set1[$line].Content -replace ' ', '␣')`nFile2: $($set2[$line].Content -replace ' ', '␣')"
                }
            }
        }
    }

    # Compare lines in File2 against File1 to find lines only in File2
    foreach ($line in $set2.Keys) {
        if (-not $set1.ContainsKey($line)) {
            $comparisonResults += [PSCustomObject]@{
                LineNumber = $set2[$line].LineNumber
                File       = "File2"
                Content    = ShowWhitespace($set2[$line].Content)
                Difference = "Only in File2"
            }
        }
    }

    # Set the max width for each box
    $boxWidth = 50

    # Display file path information
    Write-Host "File1 = $File1Path" -ForegroundColor Cyan
    Write-Host "File2 = $File2Path`n" -ForegroundColor Cyan
    
    # Add a note for whitespace representation
    Write-Host "Note: Spaces are represented as '␣' in the output." -ForegroundColor Magenta

    # Boxed output format for the results
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║               File Comparison Summary          ║" -ForegroundColor Magenta
    Write-Host "╠════════════════════════════════════════════════╣" -ForegroundColor Magenta

    if ($comparisonResults.Count -gt 0) {
        foreach ($result in $comparisonResults) {
            $lineFormatted = "Line: $($result.LineNumber)"
            $fileFormatted = "File: $($result.File)"
            $contentFormatted = "Content: $($result.Content)"
            $lineFormatted = $lineFormatted.PadRight($boxWidth - 4) + "║"
            $fileFormatted = $fileFormatted.PadRight($boxWidth - 4) + "║"
            $contentFormatted = $contentFormatted.PadRight($boxWidth - 4) + "║"

            Write-Host "║  $lineFormatted" -ForegroundColor Yellow
            Write-Host "║  $fileFormatted" -ForegroundColor Cyan
            Write-Host "║  $contentFormatted" -ForegroundColor Red
            Write-Host "║"  (" " * ($boxWidth - 4))  "║" -ForegroundColor Magenta
        }
        Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Magenta
    } else {
        Write-Host "║  No differences found                        ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Magenta
    }
}

function CompareFiles {
    param (
        [string]$File1Path,
        [string]$File2Path
    )
    
    Write-Host "Comparing '$File1Path' and '$File2Path': `n" -ForegroundColor Green
    Compare-Lines -File1Path $File1Path -File2Path $File2Path
}
