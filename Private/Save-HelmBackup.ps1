function Save-HelmBackup {
    param (
        [string]$Namespace,
        [string]$OutputPath,
        [switch]$DryRun,
        [switch]$Verbose,
        [switch]$AllNamespaces,
        [switch]$AllNonSystemNamespaces,
        [switch]$SnapshotHelm,           # Perform a full Helm snapshot
        [switch]$SnapshotHelmUsedValues # Perform only Helm used values snapshot
    )

    # Set the verbose preference based on the switch
    if ($Verbose) {
        $VerbosePreference = "Continue"
    }

    # Check if Helm is installed
    if (!(Get-Command "helm" -ErrorAction SilentlyContinue)) {
        Write-Host "'helm' is not installed or not found in your system's PATH." -ForegroundColor Red
        Write-Host "Please install 'helm' before running Save-HelmBackup." -ForegroundColor Red
        Write-Host "You can install 'helm' from: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
        return
    }

    # Check if kubectl is installed
    if (!(Get-Command "kubectl" -ErrorAction SilentlyContinue)) {
        Write-Host "'kubectl' is not installed or not found in your system's PATH." -ForegroundColor Red
        Write-Host "Please install 'kubectl' before running Save-HelmBackup." -ForegroundColor Red
        Write-Host "You can install 'kubectl' from: https://kubernetes.io/docs/tasks/tools/install-kubectl/" -ForegroundColor Yellow
        return
    }

    # Function to run Helm command and return output
    function Invoke-HelmCommand {
        param (
            [string]$command # Helm command without the 'helm' part
        )
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "helm"
        $processInfo.Arguments = $command
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo

        # Start the Helm process
        $process.Start() | Out-Null

        # Capture output and error
        $output = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        if ($stderr) {
            Write-Host "Error running Helm command: $stderr" -ForegroundColor Red
        }

        return $output
    }

    # Function to fetch used values
    function Get-HelmUsedValues {
        param (
            [string]$ReleaseName,
            [string]$NamespaceOption
        )

        $helmUsedValuesCmd = "get values $ReleaseName $NamespaceOption --all -o yaml"
        Write-Verbose "Running command: helm $helmUsedValuesCmd"
        $usedValuesOutput = Invoke-HelmCommand $helmUsedValuesCmd

        if ($usedValuesOutput) {
            return $usedValuesOutput
        } else {
            Write-Host "No used values found for release '$ReleaseName'." -ForegroundColor Yellow
            return $null
        }
    }

    # Function to process a namespace
    function Backup-HelmNamespace {
        param (
            [string]$Namespace
        )

        $namespaceOption = ""
        if ($Namespace) {
            $namespaceOption = "-n $Namespace"
        }

        $helmListCmd = "list $namespaceOption --output json"
        Write-Verbose "Running command: helm $helmListCmd"
        $releasesOutput = Invoke-HelmCommand $helmListCmd

        if ($releasesOutput) {
            $releases = $releasesOutput | ConvertFrom-Json

            if ($releases.Count -eq 0) {
                Write-Host "No Helm releases found in the namespace '$Namespace'." -ForegroundColor Yellow
                return
            }

            foreach ($release in $releases) {
                $releaseName = $release.name
                $releaseNamespace = $release.namespace
                $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

                if ($DryRun) {
                    Write-Host "Dry run: Found Helm release '$releaseName' in namespace '$releaseNamespace'."
                } else {
                    # Full Helm snapshot (values, manifest, and history)
                    if ($SnapshotHelm) {
                        # Fetch values
                        $helmGetValuesCmd = "get values $releaseName $namespaceOption -o yaml"
                        Write-Verbose "Running command: helm $helmGetValuesCmd"
                        $valuesOutput = Invoke-HelmCommand $helmGetValuesCmd
                        if ($valuesOutput) {
                            $safeReleaseName = $releaseName -replace "[:\\/]", "_"
                            $valuesFile = Join-Path -Path $OutputPath -ChildPath "${safeReleaseName}_values_$timestamp.yaml"
                            $valuesOutput | Out-File -FilePath $valuesFile -Force
                            Write-Host "Helm release '$releaseName' values saved: $valuesFile" -ForegroundColor Green
                        }

                        # Fetch manifest
                        $helmGetManifestCmd = "get manifest $releaseName $namespaceOption"
                        Write-Verbose "Running command: helm $helmGetManifestCmd"
                        $manifestOutput = Invoke-HelmCommand $helmGetManifestCmd
                        if ($manifestOutput) {
                            $manifestFile = Join-Path -Path $OutputPath -ChildPath "${safeReleaseName}_manifest_$timestamp.yaml"
                            $manifestOutput | Out-File -FilePath $manifestFile -Force
                            Write-Host "Helm release '$releaseName' manifest saved: $manifestFile" -ForegroundColor Green
                        }

                        # Fetch history
                        $helmHistoryCmd = "history $releaseName $namespaceOption --output yaml"
                        Write-Verbose "Running command: helm $helmHistoryCmd"
                        $historyOutput = Invoke-HelmCommand $helmHistoryCmd
                        if ($historyOutput) {
                            $historyFile = Join-Path -Path $OutputPath -ChildPath "${safeReleaseName}_history_$timestamp.yaml"
                            $historyOutput | Out-File -FilePath $historyFile -Force
                            Write-Host "Helm release '$releaseName' history saved: $historyFile" -ForegroundColor Green
                        }
                    }

                    # Only Helm used values snapshot
                    if ($SnapshotHelmUsedValues) {
                        $usedValuesOutput = Get-HelmUsedValues -ReleaseName $releaseName -NamespaceOption $namespaceOption
                        if ($usedValuesOutput) {
                            $safeReleaseName = $releaseName -replace "[:\\/]", "_"
                            $usedValuesFile = Join-Path -Path $OutputPath -ChildPath "${safeReleaseName}_used_values_$timestamp.yaml"
                            $usedValuesOutput | Out-File -FilePath $usedValuesFile -Force
                            Write-Host "Helm release '$releaseName' used values saved: $usedValuesFile" -ForegroundColor Green
                        }
                    }
                }
            }
        } else {
            Write-Host "No Helm releases found in the namespace '$Namespace'." -ForegroundColor Yellow
        }
    }

    try {
        # Determine the namespace option
        if ($AllNamespaces) {
            $namespaces = kubectl get namespaces -o json | ConvertFrom-Json
            $allClusterNamespaces = $namespaces.items | ForEach-Object { $_.metadata.name }
        } elseif ($AllNonSystemNamespaces) {
            $namespaces = kubectl get namespaces -o json | ConvertFrom-Json
            $allClusterNamespaces = $namespaces.items | Where-Object { $_.metadata.name -notmatch "^(kube-system|kube-public|kube-node-lease|default)$" } | ForEach-Object { $_.metadata.name }
        } elseif ($Namespace) {
            $allClusterNamespaces = @($Namespace)
        } else {
            Write-Host "No namespace specified." -ForegroundColor Red
            return
        }

        # Process each namespace
        $allClusterNamespaces | ForEach-Object {
            Write-Host "Processing namespace: $_"
            Backup-HelmNamespace -Namespace $_
        }
    }
    catch {
        Write-Host "Error occurred while backing up Helm releases: $_" -ForegroundColor Red
    }
}