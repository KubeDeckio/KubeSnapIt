#!/usr/bin/env pwsh

# Import functions from the Private directory
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object { . $_.FullName }

function Invoke-KubeSnapIt {
    [CmdletBinding()]
    param (
        [string]$Namespace = "",
        [string]$OutputPath = "./snapshots",
        [switch]$AllNamespaces,
        [string]$Labels = "",
        [string]$Objects = "",  # New parameter to accept comma-separated kind/name objects
        [switch]$DryRun,
        [switch]$Help
    )

    # Display help message if the Help switch is used
    if ($Help) {
        Write-Host ""
        Write-Host "KubeSnapIt Parameters:"
        Write-Host "  -Namespace           Specify the Kubernetes namespace to take a snapshot from."
        Write-Host "  -OutputPath          Path to save the snapshot files."
        Write-Host "  -AllNamespaces       Capture all namespaces. If this is provided, -Namespace will be ignored."
        Write-Host "  -Labels              Specify labels to filter Kubernetes objects (e.g., app=nginx)."
        Write-Host "  -Objects     Comma-separated list of specific objects in the kind/name format (e.g., pod/my-pod, deployment/my-deployment)."
        Write-Host "  -DryRun              Simulate taking the snapshot without saving files."
        Write-Host "  -Verbose             Show detailed output during the snapshot process."
        Write-Host "  -Help                Display this help message."
        return
    }

    # Check if kubectl is installed
    if (-not (Get-Command "kubectl" -ErrorAction SilentlyContinue)) {
        Write-Host "'kubectl' is not installed or not found in your system's PATH." -ForegroundColor Red
        Write-Host "Please install 'kubectl' before running KubeSnapIt." -ForegroundColor Red
        Write-Host "You can install 'kubectl' from: https://kubernetes.io/docs/tasks/tools/install-kubectl/" -ForegroundColor Yellow
        return
    }

    # Validate input and assign defaults
    if (-not $Namespace -and -not $AllNamespaces) {
        Write-Host "Error: You must specify either -Namespace or -AllNamespaces." -ForegroundColor Red
        return
    }

    # Set output path and create directory if it doesn't exist
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force
    }

    # Call the function to take a snapshot, passing relevant parameters
    Write-Verbose "Starting snapshot process..."
    if ($DryRun) {
        Write-Host "Dry run enabled. No files will be saved." -ForegroundColor Yellow
    }

    if ($Namespace -or $AllNamespaces) {
        # Call the snapshot function
        Show-KubeTidyBanner

        # Call Save-KubeSnapshot with the new Objects parameter
        Save-KubeSnapshot `
            -Namespace $Namespace `
            -AllNamespaces:$AllNamespaces `
            -Labels $Labels `
            -Objects $Objects `
            -OutputPath $OutputPath `
            -DryRun:$DryRun `
            -Verbose:$Verbose
    } else {
        Write-Host "Error: You must specify either -Namespace or -AllNamespaces to take a snapshot." -ForegroundColor Red
    }
}
