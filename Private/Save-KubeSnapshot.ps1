function Save-KubeSnapshot {
    param (
        [string]$Namespace,
        [switch]$AllNamespaces,
        [switch]$AllNonSystemNamespaces,
        [string]$Labels,
        [string]$OutputPath,
        [switch]$DryRun,
        [string]$Objects # Accept comma-separated list of objects
    )

    # Import the PowerShell-YAML module if not already loaded
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Import-Module powershell-yaml
    }

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
    }
    elseif ($AllNonSystemNamespaces) {
        # Get all non-system namespaces
        $namespaces = Invoke-KubectlCommand "get namespaces -o json" | ConvertFrom-Json
        $nonSystemNamespaces = $namespaces.items | Where-Object { $_.metadata.name -notmatch "^(kube-system|kube-public|kube-node-lease|default)$" } | Select-Object -ExpandProperty metadata | Select-Object -ExpandProperty name
    }
    elseif ($Namespace) {
        # Check if the namespace exists
        $namespaceCheck = Invoke-KubectlCommand "get namespace $Namespace" 2>$null
        if (-not $namespaceCheck) {
            Write-Host "Namespace '$Namespace' does not exist in the cluster." -ForegroundColor Red
            return
        }

        $namespaceOption = "-n $Namespace"
        $unmanagedPodsCmd += " -n $Namespace"
    }
    else {
        $namespaceOption = ""
    }

    if ($Labels) {
        $labelOption = "-l $Labels"
        $unmanagedPodsCmd += " -l $Labels"
    }
    else {
        $labelOption = ""
    }

    if (-not $DryRun) {
        try {
            $resourcesFound = $false  # Flag to track if any resources are found

            # Function to process resources in a namespace
            function Process-Namespace {
                param (
                    [string]$Namespace
                )

                $namespaceOption = "-n $Namespace"
                $unmanagedPodsCmd = "get pods -n $Namespace --output=json"

                # If specific objects are provided, process them first
                if ($Objects) {
                    $ObjectsArray = $Objects -split ","

                    foreach ($object in $ObjectsArray) {
                        $kind, $name = $object.Trim() -split "/"
                        $kubectlCmd = "get $kind $name $namespaceOption -o yaml"
                        Write-Verbose "Running command: kubectl $kubectlCmd"
                        $resourceOutput = Invoke-KubectlCommand $kubectlCmd

                        if ($resourceOutput) {
                            $resourcesFound = $true  # Resources found
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
                }
                else {
                    # Capture namespaced resources
                    foreach ($resource in $namespacedResources) {
                        $kubectlCmd = "get $resource $namespaceOption $labelOption -o json"
                        Write-Verbose "Running command: kubectl $kubectlCmd"
                        $resourceOutput = Invoke-KubectlCommand $kubectlCmd

                        # Skip if the resource does not exist (i.e., no items)
                        if (-not $resourceOutput -or $resourceOutput -eq "null" -or $resourceOutput.Contains('"items": []')) {
                            Write-Verbose "No $resource found in this namespace. Skipping."
                            continue
                        }

                        $resourcesFound = $true  # Resources found

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

                    # Capture unmanaged pods (those without ownerReferences)
                    Write-Verbose "Running command for unmanaged pods: $unmanagedPodsCmd"
                    $unmanagedPodsOutput = Invoke-KubectlCommand $unmanagedPodsCmd
                    if ($unmanagedPodsOutput) {
                        $resourcesFound = $true  # Resources found
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
            }

            # Process each namespace
            if ($AllNonSystemNamespaces) {
                foreach ($ns in $nonSystemNamespaces) {
                    Write-Host "Processing namespace: $ns"
                    Process-Namespace -Namespace $ns
                }
            } else {
                Process-Namespace -Namespace $Namespace
            }

            # Capture cluster-scoped resources if AllNamespaces is specified
            if ($AllNamespaces) {
                $clusterResourcesFound = $false  # Track if any cluster-scoped resources are found

                foreach ($resource in $clusterScopedResources) {
                    $kubectlCmd = "get $resource -o json" # No namespace option for cluster-scoped resources
                    Write-Verbose "Running command: kubectl $kubectlCmd"
                    $resourceOutput = Invoke-KubectlCommand $kubectlCmd

                    # Skip if the resource does not exist (i.e., no items)
                    if (-not $resourceOutput -or $resourceOutput -eq "null" -or $resourceOutput.Contains('"items": []')) {
                        Write-Verbose "No $resource found. Skipping."
                        continue
                    }

                    $clusterResourcesFound = $true  # Resources found

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

                # If no cluster-scoped resources were found
                if (-not $clusterResourcesFound) {
                    Write-Host "No cluster-scoped resources found." -ForegroundColor Yellow
                }
            }

            # If no resources were found in the namespace
            if (-not $resourcesFound) {
                Write-Host "No resources found in the namespace '$Namespace'." -ForegroundColor Yellow
            }

        }
        catch {
            Write-Host "Error occurred while capturing the snapshot: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Dry run: No snapshot was taken."
    }
}