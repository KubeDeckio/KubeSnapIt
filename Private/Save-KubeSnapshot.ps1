function Save-KubeSnapshot {
    param (
        [string]$Namespace,
        [switch]$AllNamespaces,
        [string]$Labels,
        [string]$OutputPath,
        [switch]$DryRun,
        [string]$Objects # Accept comma-separated list of objects
    )

    # Import the PowerShell-YAML module if not already loaded
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Import-Module powershell-yaml
    }

    # Define resource kinds
    $namespacedResources = @(
        "deployments", 
        "daemonsets", 
        "statefulsets", 
        "configmaps", 
        "secrets", 
        "services", 
        "ingresses", 
        "persistentvolumeclaims", 
        "horizontalpodautoscalers", 
        "roles", 
        "rolebindings", 
        "serviceaccounts", 
        "cronjobs", 
        "jobs", 
        "networkpolicies", 
        "poddisruptionbudgets", 
        "resourcequotas", 
        "limitranges"
    )

    $clusterScopedResources = @(
        "persistentvolumes", 
        "clusterroles", 
        "clusterrolebindings", 
        "namespaces"
    )

    # Command to capture all pods if no specific pod is provided
    $unmanagedPodsCmd = "get pods --output=json"

    # Set namespace option based on parameters
    if ($AllNamespaces) {
        $namespaceOption = "--all-namespaces"
        $unmanagedPodsCmd += " --all-namespaces"
    } elseif ($Namespace) {
        $namespaceOption = "-n $Namespace"
        $unmanagedPodsCmd += " -n $Namespace"
    } else {
        $namespaceOption = ""
    }

    if ($Labels) {
        $labelOption = "-l $Labels"
        $unmanagedPodsCmd += " -l $Labels"
    } else {
        $labelOption = ""
    }

    if (-not $DryRun) {
        try {
            # Function to run kubectl command and return output
            function Invoke-KubectlCommand {
                param (
                    [string]$command     # kubectl command without the 'kubectl' part
                )
                $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                $processInfo.FileName = "kubectl"
                $processInfo.Arguments = $command
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
                    Write-Host "Error running kubectl command: $stderr" -ForegroundColor Red
                }

                return $output
            }

            # If specific objects are provided, process them first
            if ($Objects) {
                $ObjectsArray = $Objects -split ","

                foreach ($object in $ObjectsArray) {
                    $kind, $name = $object.Trim() -split "/"
                    $kubectlCmd = "get $kind $name $namespaceOption -o yaml"
                    Write-Verbose "Running command: kubectl $kubectlCmd"
                    $resourceOutput = Invoke-KubectlCommand $kubectlCmd

                    if ($resourceOutput) {
                        $resourceOutputYaml = $resourceOutput | ConvertFrom-Yaml
                        $resourceName = $resourceOutputYaml.metadata.name
                        $kind = $resourceOutputYaml.kind
                        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

                        # Sanitize the resourceName by replacing invalid characters with underscores
                        $safeResourceName = $resourceName -replace "[:\\/]", "_"

                        # Generate a filename based on the kind and name of the resource
                        $resourceFile = Join-Path -Path $OutputPath -ChildPath "${kind}_${safeResourceName}_$timestamp.yaml"

                        Write-Verbose "Saving $kind '$resourceName' snapshot to: $resourceFile"
                        $resourceOutput | Out-File -FilePath $resourceFile -Force
                        Write-Host "$kind '$resourceName' snapshot saved: $resourceFile" -ForegroundColor Green
                    }
                }
            } else {
                # Capture namespaced resources if not in AllNamespaces mode
                if (-not $AllNamespaces -and $Namespace) {
                    foreach ($resource in $namespacedResources) {
                        $kubectlCmd = "get $resource $namespaceOption $labelOption -o json"
                        Write-Verbose "Running command: kubectl $kubectlCmd"
                        $resourceOutput = Invoke-KubectlCommand $kubectlCmd

                        # Skip if the resource does not exist (i.e., no items)
                        if (-not $resourceOutput -or $resourceOutput -eq "null" -or $resourceOutput.Contains('"items": []')) {
                            Write-Verbose "No $resource found in this namespace. Skipping."
                            continue
                        }

                        # Convert JSON to objects for easier processing
                        $resourceOutputJson = $resourceOutput | ConvertFrom-Json

                        # Process each individual item in the resource output
                        foreach ($item in $resourceOutputJson.items) {
                            $resourceName = $item.metadata.name
                            $kind = $item.kind
                            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

                            # Sanitize the resourceName by replacing invalid characters with underscores
                            $safeResourceName = $resourceName -replace "[:\\/]", "_"

                            # Generate a filename based on the kind and name of the resource
                            $resourceFile = Join-Path -Path $OutputPath -ChildPath "${kind}_${safeResourceName}_$timestamp.yaml"

                            # Convert the item back to YAML and save it
                            $item | ConvertTo-Yaml | Out-File -FilePath $resourceFile -Force
                            Write-Verbose "Saving $kind '$resourceName' snapshot to: $resourceFile"
                            Write-Host "$kind '$resourceName' snapshot saved: $resourceFile" -ForegroundColor Green
                        }
                    }
                }

                # Capture cluster-scoped resources if AllNamespaces is specified
                if ($AllNamespaces) {
                    foreach ($resource in $clusterScopedResources) {
                        $kubectlCmd = "get $resource -o json" # No namespace option for cluster-scoped resources
                        Write-Verbose "Running command: kubectl $kubectlCmd"
                        $resourceOutput = Invoke-KubectlCommand $kubectlCmd

                        # Skip if the resource does not exist (i.e., no items)
                        if (-not $resourceOutput -or $resourceOutput -eq "null" -or $resourceOutput.Contains('"items": []')) {
                            Write-Verbose "No $resource found. Skipping."
                            continue
                        }

                        # Convert JSON to objects for easier processing
                        $resourceOutputJson = $resourceOutput | ConvertFrom-Json

                        # Process each individual item in the resource output
                        foreach ($item in $resourceOutputJson.items) {
                            $resourceName = $item.metadata.name
                            $kind = $item.kind
                            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

                            # Sanitize the resourceName by replacing invalid characters with underscores
                            $safeResourceName = $resourceName -replace "[:\\/]", "_"

                            # Generate a filename based on the kind and name of the resource
                            $resourceFile = Join-Path -Path $OutputPath -ChildPath "${kind}_${safeResourceName}_$timestamp.yaml"

                            # Convert the item back to YAML and save it
                            $item | ConvertTo-Yaml | Out-File -FilePath $resourceFile -Force
                            Write-Verbose "Saving $kind '$resourceName' snapshot to: $resourceFile"
                            Write-Host "$kind '$resourceName' snapshot saved: $resourceFile" -ForegroundColor Green
                        }
                    }
                }

                # Capture unmanaged pods (those without ownerReferences)
                Write-Verbose "Running command for unmanaged pods: $unmanagedPodsCmd"
                $unmanagedPodsOutput = Invoke-KubectlCommand $unmanagedPodsCmd
                if ($unmanagedPodsOutput) {
                    $unmanagedPodsOutputJson = $unmanagedPodsOutput | ConvertFrom-Json
                    foreach ($pod in $unmanagedPodsOutputJson.items) {
                        if (-not $pod.metadata.ownerReferences) {
                            $podName = $pod.metadata.name
                            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                            $unmanagedPodFile = Join-Path -Path $OutputPath -ChildPath "unmanaged_pod_${podName}_$timestamp.yaml"

                            $pod | ConvertTo-Yaml | Out-File -FilePath $unmanagedPodFile -Force
                            Write-Verbose "Saving unmanaged pod '$podName' snapshot to: $unmanagedPodFile"
                            Write-Host "Unmanaged pod '$podName' snapshot saved: $unmanagedPodFile" -ForegroundColor Green
                        }
                    }
                }
            }
        } catch {
            Write-Host "Error occurred while capturing the snapshot: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Dry run: No snapshot was taken."
    }
}
