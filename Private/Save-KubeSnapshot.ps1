function Save-KubeSnapshot {
    param (
        [string]$Namespace,
        [switch]$ClusterResources,
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
        param ([string]$command)
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "kubectl"
        $processInfo.Arguments = $command
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null

        $output = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        if ($stderr) {
            Write-Host "Error running kubectl command: $stderr" -ForegroundColor Red
        }

        return $output
    }

    # Function to save CRD instances
    function Save-CRDInstances {
        param (
            [string]$crdName,
            [string]$crdInstancesOutput,
            [string]$OutputPath,
            [string]$Scope, # "Cluster" or "Namespaced"
            [string]$Namespace = "" # Optional namespace for namespaced CRDs
        )
        if (-not $crdInstancesOutput -or $crdInstancesOutput -match "items: \[\]") {
            Write-Verbose "No instances found for $Scope-scoped CRD: $crdName"
            return
        }

        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $scopedLabel = $Scope.ToLower()
        $namespaceLabel = if ($Namespace) { "_${Namespace}" } else { "" }
        $crdFile = Join-Path -Path $OutputPath -ChildPath "${crdName}${namespaceLabel}_${scopedLabel}_instances_${timestamp}.yaml"
        $crdInstancesOutput | Out-File -FilePath $crdFile -Force
        Write-Host "$Scope-scoped CRD instances of '$crdName' saved to: $crdFile" -ForegroundColor Green
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
        "namespaces",
        "customresourcedefinitions"
    )

    # Namespace configuration
    if ($ClusterResources) {
        $namespaceOption = "--all-namespaces"
    } elseif ($AllNonSystemNamespaces) {
        $namespaces = Invoke-KubectlCommand "get namespaces -o json" | ConvertFrom-Json
        $nonSystemNamespaces = $namespaces.items | Where-Object { $_.metadata.name -notmatch "^(kube-system|kube-public|kube-node-lease|default)$" } | Select-Object -ExpandProperty metadata | Select-Object -ExpandProperty name
    } elseif ($Namespace) {
        $namespaceCheck = Invoke-KubectlCommand "get namespace $Namespace" 2>$null
        if (-not $namespaceCheck) {
            Write-Host "Namespace '$Namespace' does not exist in the cluster." -ForegroundColor Red
            return
        }
        $namespaceOption = "-n $Namespace"
    } else {
        $namespaceOption = ""
    }

    if ($Labels) {
        $labelOption = "-l $Labels"
    } else {
        $labelOption = ""
    }

    if (-not $DryRun) {
        try {
            # Function to process namespaced resources
            function Process-Namespace {
                param ([string]$Namespace)
                foreach ($resource in $namespacedResources) {
                    $kubectlCmd = "get $resource -n $Namespace $labelOption -o json"
                    Write-Verbose "Running command: kubectl $kubectlCmd"
                    $resourceOutput = Invoke-KubectlCommand $kubectlCmd

                    if (-not $resourceOutput -or $resourceOutput -match '"items": \[\]') {
                        Write-Verbose "No $resource found in namespace $Namespace. Skipping."
                        continue
                    }

                    $resourceOutputJson = $resourceOutput | ConvertFrom-Json
                    foreach ($item in $resourceOutputJson.items) {
                        $resourceName = $item.metadata.name
                        $kind = $item.kind
                        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                        $safeResourceName = $resourceName -replace "[:\\/]", "_"
                        $resourceFile = Join-Path -Path $OutputPath -ChildPath "${kind}_${safeResourceName}_$timestamp.yaml"
                        $item | ConvertTo-Yaml | Out-File -FilePath $resourceFile -Force
                        Write-Host "Saved $kind '$resourceName' in namespace '$Namespace': $resourceFile" -ForegroundColor Green
                    }
                }

                # Process namespaced CRDs
                $crds = Invoke-KubectlCommand "get crds -o json" | ConvertFrom-Json
                if ($crds) {
                    foreach ($crd in $crds.items) {
                        $crdName = $crd.metadata.name
                        if ($crd.spec.scope -eq "Namespaced") {
                            $kubectlCmd = "get $crdName -n $Namespace -o yaml"
                            Write-Verbose "Running command for namespaced CRD instances: kubectl $kubectlCmd"
                            $crdInstancesOutput = Invoke-KubectlCommand $kubectlCmd
                            Save-CRDInstances -crdName $crdName -crdInstancesOutput $crdInstancesOutput -OutputPath $OutputPath -Scope "Namespaced" -Namespace $Namespace
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
            } elseif ($Namespace) {
                Write-Host "Processing namespace: $Namespace"
                Process-Namespace -Namespace $Namespace
            }

            # Cluster-scoped resources
            if ($ClusterResources) {
                Write-Verbose "Processing cluster-scoped resources"
                foreach ($resource in $clusterScopedResources) {
                    $kubectlCmd = "get $resource -o json"
                    Write-Verbose "Running command: kubectl $kubectlCmd"
                    $resourceOutput = Invoke-KubectlCommand $kubectlCmd

                    if (-not $resourceOutput -or $resourceOutput -match '"items": \[\]') {
                        Write-Verbose "No $resource found. Skipping."
                        continue
                    }

                    $resourceOutputJson = $resourceOutput | ConvertFrom-Json
                    foreach ($item in $resourceOutputJson.items) {
                        $resourceName = $item.metadata.name
                        $kind = $item.kind
                        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                        $safeResourceName = $resourceName -replace "[:\\/]", "_"
                        $resourceFile = Join-Path -Path $OutputPath -ChildPath "${kind}_${safeResourceName}_$timestamp.yaml"
                        $item | ConvertTo-Yaml | Out-File -FilePath $resourceFile -Force
                        Write-Host "Saved $kind '$resourceName': $resourceFile" -ForegroundColor Green
                    }
                }
            }
        } catch {
            Write-Host "Error occurred while capturing snapshots: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Dry run: No snapshot was taken."
    }
}