#!/usr/bin/env pwsh

# MARKER: NEW PARAM BLOCK

# Dot Source all functions in all ps1 files located in this module
# Define the path to the local Private directory and Krew storage directory for KubeSnapIt
$localPrivateDir = "$PSScriptRoot/Private"  # Local Private directory
$krewStorageDir = "$HOME/.krew/store/KubeSnapIt"  # Krew storage directory
$foundScripts = $false  # Flag to track if any scripts were found and executed

# Check if the local Private directory exists and source scripts if available
if (Test-Path -Path $localPrivateDir) {
    Write-Verbose "Executing scripts from local Private directory."

    # Get all .ps1 files in the local Private directory
    $localScripts = Get-ChildItem -Path "$localPrivateDir/*.ps1"

    # Execute each .ps1 script found in the local Private directory
    foreach ($script in $localScripts) {
        Write-Verbose "Executing script: $($script.FullName)"
        . $script.FullName  # Call the script
        $foundScripts = $true
    }
}

# If no scripts found in local directory, check Krew storage directory
if (-not $foundScripts -and (Test-Path -Path $krewStorageDir)) {
    Write-Verbose "Local Private directory empty or missing. Checking Krew storage directory."

    # Get all version directories (assuming they follow a vX.X.X naming pattern)
    $versionDirs = Get-ChildItem -Path $krewStorageDir -Directory | Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' }

    # Check if any version directories were found
    if ($versionDirs) {
        # Get the latest version directory based on the version number
        $latestVersionDir = $versionDirs | Sort-Object { [Version]$_.Name.Substring(1) } -Descending | Select-Object -First 1

        Write-Verbose "Latest version found: $($latestVersionDir.Name)"

        # Construct the path to the Private directory for the latest version
        $kubePrivateDir = Join-Path -Path $latestVersionDir.FullName -ChildPath "Private"

        # Check if the Private directory exists in the latest version
        if (Test-Path -Path $kubePrivateDir) {
            # Get all .ps1 files in the Private directory
            $scripts = Get-ChildItem -Path "$kubePrivateDir/*.ps1"

            # Execute each .ps1 script found
            foreach ($script in $scripts) {
                Write-Verbose "Executing script: $($script.FullName)"
                . $script.FullName  # Call the script
                $foundScripts = $true
            }
        }
        else {
            Write-Verbose "No Private directory found for the latest version: $($latestVersionDir.Name)."
        }
    }
    else {
        Write-Verbose "No version directories found in $krewStorageDir."
    }
}

# If no scripts were found and sourced, throw an error
if (-not $foundScripts) {
    Write-Error "Error: Unable to source any .ps1 files from either the local Private directory or Krew storage directory. Exiting."
    exit 1
}

function Invoke-KubeSnapIt {
    # START PARAM BLOCK
    [CmdletBinding()]
    param (
        [string]$Namespace = "",
        [string]$OutputPath = "./snapshots",
        [string]$InputPath = "", 
        [string]$ComparePath = "",
        [switch]$AllNamespaces,
        [switch]$AllNonSystemNamespaces,
        [string]$Labels = "",
        [string]$Objects = "",
        [switch]$DryRun,
        [switch]$Restore,
        [switch]$CompareWithCluster,
        [switch]$CompareSnapshots,
        [switch]$Force,
        [switch]$UI,
        [switch]$SnapshotHelm,
        [switch]$SnapshotHelmUsedValues,
        [switch]$RestoreHelmSnapshot,
        [Alias("h")] [switch]$Help
    )
    # END PARAM BLOCK

    # Display help message if the Help switch is used
    if ($Help) {
        Write-Host ""
        Write-Host "KubeSnapIt Parameters:"
        Write-Host "  -Namespace           Specify the Kubernetes namespace to take a snapshot from."
        Write-Host "  -OutputPath          Path to save the snapshot files."
        Write-Host "  -InputPath           Path to restore snapshots from or the first snapshot for comparison."
        Write-Host "  -ComparePath         Path to the second snapshot for comparison (optional)."
        Write-Host "  -AllNamespaces       Capture all namespaces. If this is provided, -Namespace will be ignored."
        Write-Host "  -AllNonSystemNamespaces Capture all non-system namespaces. If this is provided, -Namespace and -AllNamespaces will be ignored."
        Write-Host "  -Labels              Specify labels to filter Kubernetes objects (e.g., app=nginx)."
        Write-Host "  -Objects             Comma-separated list of specific objects in the kind/name format (e.g., pod/my-pod, deployment/my-deployment)."
        Write-Host "  -DryRun              Simulate taking or restoring the snapshot without saving or applying files."
        Write-Host "  -Restore             Restore snapshots from the specified directory or file."
        Write-Host "  -CompareWithCluster  Compare a snapshot with the current cluster state."
        Write-Host "  -CompareSnapshots    Compare two snapshots."
        Write-Host "  -Force               Force the action without prompting for confirmation."
        Write-Host "  -SnapshotHelm        Backup Helm releases and their values."
        Write-Host "  -SnapshotHelmUsedValues  Backup Helm release values."
        write-Host "  -RestoreHelmSnapshot Restore Helm release from a snapshot."
        Write-Host "  -Help                Display this help message."
        return
    }

    if (!$UI) {
        Show-KubeSnapItBanner
    }

    # Check if kubectl is installed for actions that require it
    if (!(Get-Command "kubectl" -ErrorAction SilentlyContinue)) {
        Write-Host "'kubectl' is not installed or not found in your system's PATH." -ForegroundColor Red
        Write-Host "Please install 'kubectl' before running KubeSnapIt." -ForegroundColor Red
        Write-Host "You can install 'kubectl' from: https://kubernetes.io/docs/tasks/tools/install-kubectl/" -ForegroundColor Yellow
        exit
    }

    # Get the current Kubernetes context
    $context = kubectl config current-context

    if ($context) {
        # Add lines and styling to make it stand out
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host "YOU ARE CONNECTED TO A KUBERNETES CLUSTER" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Kubernetes Context: $context" -ForegroundColor Green
        # Get cluster details from current context
        $clusterInfo = kubectl config view -o jsonpath="{.contexts[?(@.name=='$context')].context.cluster}"
        Write-Host "Kubernetes Cluster: $clusterInfo" -ForegroundColor Green
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host ""
    }
    else {
        Write-Host "You are not connected to any Kubernetes cluster." -ForegroundColor Red
        Write-Host "Please configure a Kubernetes cluster to connect to." -ForegroundColor Red
        Write-Host "Instructions to set up a cluster can be found here: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/" -ForegroundColor Yellow
        Write-Host "You can set the current context using the command: 'kubectl config use-context <context-name>'." -ForegroundColor Yellow
        exit
    }

    # Determine the operation type using switch
    switch ($true) {
        { $Restore } {
            if (-not $InputPath) {
                Write-Host "Error: Input path required for restore." -ForegroundColor Red
                return
            }
            Restore-KubeSnapshot -InputPath $InputPath -Force $Force -Verbose:$Verbose
            return
        }

        { $CompareWithCluster } {
            if (-not $InputPath) {
                Write-Host "Error: Snapshot path required for comparison." -ForegroundColor Red
                return
            }
            Compare-Files -LocalFile $InputPath -Verbose:$Verbose
            return
        }

        { $CompareSnapshots } {
            if (-not $InputPath -or -not $ComparePath) {
                Write-Host "Error: Both -InputPath and -ComparePath required for snapshot comparison." -ForegroundColor Red
                return
            }
            Compare-Files -LocalFile $InputPath -CompareFile $ComparePath -Verbose:$Verbose
            return
        }

        { $SnapshotHelm } {
            if (-not ($Namespace -or $AllNamespaces -or $AllNonSystemNamespaces)) {
                Write-Host "Error: -Namespace, -AllNamespaces, or -AllNonSystemNamespaces is required with -SnapshotHelm." -ForegroundColor Red
                return
            }
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                Write-Verbose "Output directory created: $OutputPath"
            }
            Write-Verbose "Starting Helm backup..."
            if ($DryRun) { Write-Host "Dry run enabled. No files will be saved." -ForegroundColor Yellow }

            # Helm backup function call
            try {
                Save-HelmBackup -Namespace $Namespace -AllNamespaces:$AllNamespaces -AllNonSystemNamespaces:$AllNonSystemNamespaces -OutputPath $OutputPath -DryRun:$DryRun -Verbose:$Verbose -SnapshotHelm
            }
            catch {
                Write-Host "Error during Helm backup: $_" -ForegroundColor Red
            }
            return
        }

        # Only Helm used values snapshot
        { $SnapshotHelmUsedValues } {
            if (-not ($Namespace -or $AllNamespaces -or $AllNonSystemNamespaces)) {
                Write-Host "Error: -Namespace, -AllNamespaces, or -AllNonSystemNamespaces is required with -SnapshotHelmUsedValues." -ForegroundColor Red
                return
            }
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                Write-Verbose "Output directory created: $OutputPath"
            }
            Write-Verbose "Starting Helm used values backup..."
            if ($DryRun) { Write-Host "Dry run enabled. No files will be saved." -ForegroundColor Yellow }

            try {
                Save-HelmBackup `
                    -Namespace $Namespace `
                    -AllNamespaces:$AllNamespaces `
                    -AllNonSystemNamespaces:$AllNonSystemNamespaces `
                    -OutputPath $OutputPath `
                    -DryRun:$DryRun `
                    -Verbose:$Verbose `
                    -SnapshotHelmUsedValues
            }
            catch {
                Write-Host "Error during Helm used values backup: $_" -ForegroundColor Red
            }
            return
        }

        # Only Helm used values snapshot
        { $SnapshotHelmUsedValues -and $SnapshotHelm } {
            if (-not ($Namespace -or $AllNamespaces -or $AllNonSystemNamespaces)) {
                Write-Host "Error: -Namespace, -AllNamespaces, or -AllNonSystemNamespaces is required with -SnapshotHelm and -SnapshotHelmUsedValues." -ForegroundColor Red
                return
            }
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                Write-Verbose "Output directory created: $OutputPath"
            }
            Write-Verbose "Starting Helm backup..."
            if ($DryRun) { Write-Host "Dry run enabled. No files will be saved." -ForegroundColor Yellow }
        
            try {
                Save-HelmBackup `
                    -Namespace $Namespace `
                    -AllNamespaces:$AllNamespaces `
                    -AllNonSystemNamespaces:$AllNonSystemNamespaces `
                    -OutputPath $OutputPath `
                    -DryRun:$DryRun `
                    -Verbose:$Verbose `
                    -SnapshotHelm `
                    -SnapshotHelmUsedValues
            }
            catch {
                Write-Host "Error during Helm backup: $_" -ForegroundColor Red
            }
            return
        }

        { $RestoreHelmSnapshot } {
            if (-not $InputPath) {
                Write-Host "Error: Input path required for restore." -ForegroundColor Red
                return
            }
            Restore-HelmBackup -ManifestFilePath:$InputPath -Namespace:$Namespace -DryRun:$DryRun -Verbose:$Verbose
            return
        }

        { $Namespace -or $AllNamespaces -or $AllNonSystemNamespaces } {
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                Write-Verbose "Output directory created: $OutputPath"
            }
            Write-Verbose "Starting snapshot..."
            if ($DryRun) { Write-Host "Dry run enabled. No files will be saved." -ForegroundColor Yellow }

            # Snapshot function call
            try {
                Save-KubeSnapshot -Namespace $Namespace -AllNamespaces:$AllNamespaces -AllNonSystemNamespaces:$AllNonSystemNamespaces -Labels $Labels -Objects $Objects -OutputPath $OutputPath -DryRun:$DryRun -Verbose:$Verbose
            }
            catch {
                Write-Host "Error during snapshot: $_" -ForegroundColor Red
            }
            return
        }

        default {
            Write-Host "Error: Specify -Restore, -CompareWithCluster, -CompareSnapshots, or -SnapshotHelm with necessary parameters." -ForegroundColor Red
            return
        }
    }
}