function Restore-HelmBackup {
    param (
        [string]$ManifestFilePath, # Path to the manifest file to restore
        [string]$Namespace,        # Target namespace for the release
        [switch]$Verbose,          # Enable verbose output
        [switch]$DryRun            # Simulate the restore process without applying changes
    )

    # Set verbose preference
    if ($Verbose) {
        $VerbosePreference = "Continue"
    }

    # Check if kubectl is installed
    if (!(Get-Command "kubectl")) {
        Write-Host "'kubectl' is not installed or not found in your system's PATH." -ForegroundColor Red
        Write-Host "Please install 'kubectl' before running Restore-HelmBackup." -ForegroundColor Red
        Write-Host "You can install 'kubectl' from: https://kubernetes.io/docs/tasks/tools/install/" -ForegroundColor Yellow
        return
    }

    # Validate the manifest file path
    if (-not (Test-Path $ManifestFilePath)) {
        Write-Host "Manifest file not found at path '$ManifestFilePath'." -ForegroundColor Red
        return
    }

    # Extract release name and timestamp from manifest file name
    $manifestFileName = [System.IO.Path]::GetFileNameWithoutExtension($ManifestFilePath)
    if ($manifestFileName -notmatch "^(?<releaseName>.+)_manifest_(?<timestamp>\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})$") {
        Write-Host "Invalid manifest file naming convention: '$manifestFileName'." -ForegroundColor Red
        return
    }
    $releaseName = $matches['releaseName']
    $timestamp = $matches['timestamp']

    # Locate corresponding backend files based on timestamp
    $backupDir = [System.IO.Path]::GetDirectoryName($ManifestFilePath)
    $backendFile = Get-ChildItem -Path $backupDir -Filter "${releaseName}_backend_${timestamp}.yaml" | Select-Object -First 1

    # Log the files being used for restoration
    Write-Host "Using manifest file: $ManifestFilePath" -ForegroundColor Green
    if ($backendFile) {
        Write-Host "Using backend file: $($backendFile.FullName)" -ForegroundColor Green
    } else {
        Write-Host "No matching backend file found for release '$releaseName'." -ForegroundColor Yellow
    }

    # Check for namespace and create if needed
    if (-not $DryRun) {
        $namespaceCheck = kubectl get namespace $Namespace -o name
        if (-not $namespaceCheck) {
            Write-Verbose "Creating namespace '$Namespace'."
            kubectl create namespace $Namespace
            Write-Host "Namespace '$Namespace' created." -ForegroundColor Green
        } else {
            Write-Host "Namespace '$Namespace' exists." -ForegroundColor Green
        }
    }

    # Restore the manifest
    Write-Host "Restoring manifest for Helm release '$releaseName'..." -ForegroundColor Green
    if ($DryRun) {
        Write-Host "Dry run: Would apply manifest from file $ManifestFilePath." -ForegroundColor Yellow
    } else {
        $kubectlApplyCmd = "apply -f $ManifestFilePath"
        Write-Verbose "Running command: kubectl $kubectlApplyCmd"
        kubectl apply -f $ManifestFilePath
        Write-Host "Manifest for release '$releaseName' applied." -ForegroundColor Green
    }

    # Restore backend storage (if available)
    if ($backendFile) {
        Write-Host "Restoring backend storage for Helm release '$releaseName'..." -ForegroundColor Green
        if ($DryRun) {
            Write-Host "Dry run: Would apply backend storage from file $($backendFile.FullName)." -ForegroundColor Yellow
        } else {
            $kubectlApplyCmd = "apply -f $($backendFile.FullName)"
            Write-Verbose "Running command: kubectl $kubectlApplyCmd"
            kubectl apply -f $backendFile.FullName
            Write-Host "Backend storage for release '$releaseName' applied." -ForegroundColor Green
        }
    }

    Write-Host "Restore process for release '$releaseName' completed." -ForegroundColor Green
}