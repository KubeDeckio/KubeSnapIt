#!/usr/bin/env pwsh

# MARKER: NEW PARAM BLOCK

# Dot Source all functions in all ps1 files located in this module
# Define the path to the local Private directory and Krew storage directory for KubeSnapIt
$localPrivateDir = "$PSScriptRoot\Private"  # Local Private directory
$krewStorageDir = "$HOME/.krew/store/KubeSnapIt"  # Krew storage directory

# Check if the local Private directory exists
if (Test-Path -Path $localPrivateDir) {
    Write-Verbose "Executing scripts from local Private directory."

    # Get all .ps1 files in the local Private directory
    $localScripts = Get-ChildItem -Path "$localPrivateDir/*.ps1" 2>$null

    # Execute each .ps1 script found in the local Private directory
    foreach ($script in $localScripts) {
        Write-Verbose "Executing script: $($script.FullName)"
        . $script.FullName  # Call the script
    }
}
else {
    Write-Verbose "Local Private directory not found, checking Krew storage."

    # Check if the KubeSnapIt storage directory exists
    if (Test-Path -Path $krewStorageDir) {
        Write-Verbose "Checking for available versions in $krewStorageDir."

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
                $scripts = Get-ChildItem -Path "$kubePrivateDir/*.ps1" 2>$null

                # Execute each .ps1 script found
                foreach ($script in $scripts) {
                    Write-Verbose "Executing script: $($script.FullName)"
                    . $script.FullName  # Call the script
                }
            }
            else {
                Write-Error "No Private directory found for the latest version: $($latestVersionDir.Name). Exiting."
                exit 1
            }
        }
        else {
            Write-Error "No version directories found in $krewStorageDir. Exiting."
            exit 1
        }
    }
    else {
        Write-Error "Krew storage directory for KubeSnapIt not found. Exiting."
        exit 1
    }
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
        [string]$Labels = "",
        [string]$Objects = "",
        [switch]$DryRun,
        [switch]$Restore,
        [switch]$CompareWithCluster,  # Switch for comparing with the cluster
        [switch]$CompareSnapshots,      # Switch for comparing two snapshots
        [switch]$Force,
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
        Write-Host "  -Labels              Specify labels to filter Kubernetes objects (e.g., app=nginx)."
        Write-Host "  -Objects             Comma-separated list of specific objects in the kind/name format (e.g., pod/my-pod, deployment/my-deployment)."
        Write-Host "  -DryRun              Simulate taking or restoring the snapshot without saving or applying files."
        Write-Host "  -Restore             Restore snapshots from the specified directory or file."
        Write-Host "  -CompareWithCluster  Compare a snapshot with the current cluster state."
        Write-Host "  -CompareSnapshots     Compare two snapshots."
        Write-Host "  -Force               Force the action without prompting for confirmation."
        Write-Host "  -Help                Display this help message."
        return
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
    } else {
        Write-Host "You are not connected to any Kubernetes cluster." -ForegroundColor Red
        Write-Host "Please configure a Kubernetes cluster to connect to." -ForegroundColor Red
        Write-Host "Instructions to set up a cluster can be found here: https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/" -ForegroundColor Yellow
        Write-Host "You can set the current context using the command: 'kubectl config use-context <context-name>'." -ForegroundColor Yellow
        exit
    }

    # Determine the operation type using switch
    switch ($true) {
        # Handle Restore operation
        { $Restore } {
            if (-not $InputPath) {
                Write-Host "Error: You must specify an input path for the restore operation." -ForegroundColor Red
                return
            }
            # Call the Restore-KubeSnapshot function
            Restore-KubeSnapshot -InputPath $InputPath -Force $Force -Verbose:$Verbose
            return
        }

        # Handle Compare with Cluster operation
        { $CompareWithCluster } {
            if (-not $InputPath) {
                Write-Host "Error: You must specify a snapshot path for comparison." -ForegroundColor Red
                return
            }

            Write-Verbose "Comparing snapshot with current cluster state: $InputPath"
            Compare-Files -LocalFile $InputPath -Verbose:$Verbose
            return
        }

        # Handle Compare Snapshots operation
        { $CompareSnapshots } {
            if (-not $InputPath) {
                Write-Host "Error: You must specify a snapshot path for comparison." -ForegroundColor Red
                return
            }

            # Ensure ComparePath is provided for snapshot comparison
            if (-not [string]::IsNullOrWhiteSpace($ComparePath)) {
                Write-Verbose "Comparing two snapshots: $InputPath and $ComparePath"
                Compare-Files -LocalFile $InputPath -CompareFile $ComparePath -Verbose:$Verbose
                return
            } else {
                Write-Host "Error: You must specify a second snapshot for comparison (-ComparePath)." -ForegroundColor Red
                return
            }
        }

        # Handle Snapshot operation
        { $Namespace -or $AllNamespaces } {
            # Set output path and create directory if it doesn't exist
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                Write-Verbose "Output directory created: $OutputPath"
            }

            Write-Verbose "Starting snapshot process..."
            if ($DryRun) {
                Write-Host "Dry run enabled. No files will be saved." -ForegroundColor Yellow
            }

            # Call the snapshot function
            try {
                Save-KubeSnapshot -Namespace $Namespace -AllNamespaces:$AllNamespaces -Labels $Labels -Objects $Objects -OutputPath $OutputPath -DryRun:$DryRun -Verbose:$Verbose
            } catch {
                Write-Host "Error occurred during the snapshot process: $_" -ForegroundColor Red
            }
            return
        }

        # If none of the operations match, display an error
        default {
            Write-Host "Error: You must specify either -Restore, -CompareWithCluster, or -CompareSnapshots with a valid operation." -ForegroundColor Red
            return
        }
    }
}


Invoke-KubeSnapIt -InputPath "C:\Users\rhooper\OneDrive - Intercept\Documents\Git\KubeDeck\snapshot\ConfigMap_task-scheduler-configmap_2024-10-22_15-04-47.yaml" -CompareWithCluster -verbose
