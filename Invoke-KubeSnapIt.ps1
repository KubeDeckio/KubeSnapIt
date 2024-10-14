#!/usr/bin/env pwsh

# Import functions from the Private directory
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object { . $_.FullName }

function Invoke-KubeSnapIt {
    [CmdletBinding()]
    param (
        [string]$Namespace = "",
        [string]$OutputPath = "./snapshots",
        [string]$InputPath = "", # Input path for restoring snapshots or first snapshot for comparison
        [string]$ComparePath = "", # Second path for comparing two snapshots (optional)
        [switch]$AllNamespaces,
        [string]$Labels = "",
        [string]$Objects = "", # Comma-separated list of kind/name objects
        [switch]$DryRun,
        [switch]$Restore, # Trigger restore operation
        [switch]$Compare, # Trigger comparison between snapshots or with live cluster
        [switch]$CompareWithCluster, # Compare a snapshot with the current cluster state
        [switch]$Help
    )

    # Display help message if the Help switch is used
    if ($Help) {
        Write-Host ""
        Write-Host "KubeSnapIt Parameters:"
        Write-Host "  -Namespace           Specify the Kubernetes namespace to take a snapshot from."
        Write-Host "  -OutputPath          Path to save the snapshot files."
        Write-Host "  -InputPath           Path to restore snapshots from or the first snapshot for comparison."
        Write-Host "  -ComparePath         Path to the second snapshot for comparison (optional)."
        Write-Host "  -AllNamespaces       Capture all namespaces. If this is provided, -Namespace will be ignored."
        Write-Host "  -Labels              Specify labels to filter Kubernetes objects (e.g., app=nginx)."
        Write-Host "  -Objects             Comma-separated list of specific objects in the kind/name format (e.g., pod/my-pod, deployment/my-deployment)."
        Write-Host "  -DryRun              Simulate taking or restoring the snapshot without saving or applying files."
        Write-Host "  -Restore             Restore snapshots from the specified directory or file."
        Write-Host "  -Compare             Compare two snapshots or compare a snapshot with the current cluster state."
        Write-Host "  -CompareWithCluster  Compare a snapshot with the current cluster state instead of another snapshot."
        Write-Host "  -Verbose             Show detailed output during the snapshot, restore, or comparison process."
        Write-Host "  -Help                Display this help message."
        return
    }

    # Check if kubectl is installed for actions that require it
    if (($Restore -or $CompareWithCluster) -and (-not (Get-Command "kubectl" -ErrorAction SilentlyContinue))) {
        Write-Host "'kubectl' is not installed or not found in your system's PATH." -ForegroundColor Red
        Write-Host "Please install 'kubectl' before running KubeSnapIt." -ForegroundColor Red
        Write-Host "You can install 'kubectl' from: https://kubernetes.io/docs/tasks/tools/install-kubectl/" -ForegroundColor Yellow
        return
    }

    # Handle Restore operation
    if ($Restore) {
        if (-not $InputPath) {
            Write-Host "Error: You must specify an input path for the restore operation." -ForegroundColor Red
            return
        }
        # Call the Restore-KubeSnapshot function
        Show-KubeTidyBanner
        Restore-KubeSnapshot `
            -InputPath $InputPath `
            -Verbose:$Verbose
        return
    }

    # Handle Compare operation
    if ($Compare) {
        if (-not $InputPath) {
            Write-Host "Error: You must specify a snapshot path for comparison." -ForegroundColor Red
            return
        }

        # Comparison with the current cluster state
        if ($CompareWithCluster) {
            Write-Verbose "Comparing snapshot with current cluster state: $InputPath"
            Show-KubeTidyBanner
            CompareFiles `
                -LocalFile $InputPath `
                -Verbose:$Verbose
        }
        # Comparison between two snapshots
        elseif ($ComparePath) {
            Write-Verbose "Comparing two snapshots: $InputPath and $ComparePath"
            Show-KubeTidyBanner
            CompareFiles `
                -LocalFile $InputPath `
                -CompareFile $ComparePath `
                -Verbose:$Verbose
        }
        else {
            Write-Host "Error: You must specify either -CompareWithCluster or a second snapshot for comparison (-ComparePath)." -ForegroundColor Red
        }
        return
    }

    # Handle Snapshot operation (default)
    if ($Namespace -or $AllNamespaces) {
        # Set output path and create directory if it doesn't exist
        try {
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                Write-Verbose "Output directory created: $OutputPath"
            }
            else {
                Write-Verbose "Output directory already exists: $OutputPath"
            }
        }
        catch {
            Write-Host "Error creating output directory: $_" -ForegroundColor Red
            return  # Exit the function if directory creation fails
        }

        Write-Verbose "Starting snapshot process..."
        if ($DryRun) {
            Write-Host "Dry run enabled. No files will be saved." -ForegroundColor Yellow
        }

        # Call the snapshot function
        Show-KubeTidyBanner
        try {
            Save-KubeSnapshot `
                -Namespace $Namespace `
                -AllNamespaces:$AllNamespaces `
                -Labels $Labels `
                -Objects $Objects `
                -OutputPath $OutputPath `
                -DryRun:$DryRun `
                -Verbose:$Verbose
        }
        catch {
            Write-Host "Error occurred during the snapshot process: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Error: You must specify either -Namespace or -AllNamespaces." -ForegroundColor Red
        return
    }
}
