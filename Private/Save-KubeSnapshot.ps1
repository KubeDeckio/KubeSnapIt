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

    # Define resource kinds to capture if Objects are not used
    $resources = @("deployments", "daemonsets", "statefulsets", "configmaps", "secrets")

    # Command to capture all pods if no specific pod is provided
    $unmanagedPodsCmd = "kubectl get pods --output=json"

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
            # If specific objects are provided, process them first
            if ($Objects) {
                # Split the comma-separated string into an array
                $ObjectsArray = $Objects -split ","

                foreach ($object in $ObjectsArray) {
                    $kind, $name = $object.Trim() -split "/"

                    # Generate the kubectl command for the specific object
                    $kubectlCmd = "kubectl get $kind $name $namespaceOption -o yaml"
                    Write-Verbose "Running command: $kubectlCmd"

                    # Capture the output of the specific object as YAML
                    $resourceOutput = Invoke-Expression $kubectlCmd | ConvertFrom-Yaml

                    # Get the resource name and kind
                    $resourceName = $resourceOutput.metadata.name
                    $kind = $resourceOutput.kind
                    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

                    # Generate a filename based on the kind and name of the resource
                    $resourceFile = Join-Path -Path $OutputPath -ChildPath "${kind}_${resourceName}_$timestamp.yaml"

                    # Convert the resource to YAML and save it
                    $itemYaml = ConvertTo-Yaml $resourceOutput
                    Write-Verbose "Saving $kind '$resourceName' snapshot to: $resourceFile"
                    $itemYaml | Out-File -FilePath $resourceFile -Force
                    Write-Host "$kind '$resourceName' snapshot saved: $resourceFile" -ForegroundColor Green
                }
            }
            else {
                # Loop through each resource kind and capture individual items
                foreach ($resource in $resources) {
                    $kubectlCmd = "kubectl get $resource $namespaceOption $labelOption -o yaml"
                    Write-Verbose "Running command: $kubectlCmd"

                    # Capture the resource output as YAML
                    $resourceOutput = Invoke-Expression $kubectlCmd | ConvertFrom-Yaml

                    # Process each individual item in the resource output
                    foreach ($item in $resourceOutput.items) {
                        $resourceName = $item.metadata.name
                        $kind = $item.kind
                        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                        
                        # Generate a filename based on the kind and name of the resource
                        $resourceFile = Join-Path -Path $OutputPath -ChildPath "${kind}_${resourceName}_$timestamp.yaml"
                        
                        # Convert the item back to YAML and save it
                        $itemYaml = ConvertTo-Yaml $item
                        Write-Verbose "Saving $kind '$resourceName' snapshot to: $resourceFile"
                        $itemYaml | Out-File -FilePath $resourceFile -Force
                        Write-Host "$kind '$resourceName' snapshot saved: $resourceFile" -ForegroundColor Green
                    }
                }

                # Capture unmanaged pods (those without ownerReferences)
                Write-Verbose "Running command for unmanaged pods: $unmanagedPodsCmd"
                $unmanagedPodsOutput = Invoke-Expression $unmanagedPodsCmd | ConvertFrom-Json

                # Process each unmanaged pod individually
                foreach ($pod in $unmanagedPodsOutput.items) {
                    if (-not $pod.metadata.ownerReferences) {
                        $podName = $pod.metadata.name
                        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                        
                        # Generate a filename for unmanaged pod
                        $unmanagedPodFile = Join-Path -Path $OutputPath -ChildPath "unmanaged_pod_${podName}_$timestamp.yaml"

                        # Convert the unmanaged pod to YAML and save it
                        $podYaml = ConvertTo-Yaml $pod
                        Write-Verbose "Saving unmanaged pod '$podName' snapshot to: $unmanagedPodFile"
                        $podYaml | Out-File -FilePath $unmanagedPodFile -Force
                        Write-Host "Unmanaged pod '$podName' snapshot saved: $unmanagedPodFile" -ForegroundColor Green
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
