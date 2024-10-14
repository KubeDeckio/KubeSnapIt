---
title: Logging and Output
parent: Usage
nav_order: 3
layout: default
---

# Logging and Output

KubeSnapIt provides detailed output and logging for each operation. You can use the `-Verbose` flag to see detailed information about resource snapshotting, diffing, and restoring processes.


### Detailed Example of Snapshot Creation Output

When creating snapshots, the following summary might be displayed:

```PowerShell
Deployment 'access' snapshot saved: ./snapshots/Deployment_access_2024-10-14_12-55-22.yaml
ConfigMap 'kube-root-ca.crt' snapshot saved: ./snapshots/ConfigMap_kube-root-ca.crt_2024-10-14_12-55-23.yaml
Unmanaged pod 'my-unmanaged-pod' snapshot saved: ./snapshots/unmanaged_pod_my-unmanaged-pod_2024-10-14_12-55-26.yaml
```

## Detailed Example of Restore Output

```PowerShell
Restoring resource from file: "C:\Users\rhooper\OneDrive - Intercept\Documents\Git\KubeSnapIt\snapshots\Deployment_noaccess_2024-10-14_14-47-46.yaml"
deployment.apps/noaccess configured
Resource from '"C:\Users\rhooper\OneDrive - Intercept\Documents\Git\KubeSnapIt\snapshots\Deployment_noaccess_2024-10-14_14-47-46.yaml"' restored successfully.
```

## Detailed Example of Diff Output

After running the diff operation, a summary is displayed indicating how many resources were processed and their statuses:

```PowerShell
File1 = snapshots\Deployment_noaccess_2024-10-14_14-49-30.yaml
File2 = snapshots\Deployment_noaccess_2024-10-14_14-47-46.yaml

Note: Spaces are represented as '␣' in the output.

╔════════════════════════════════════════════════╗
║               Comparison Summary               ║
╠════════════════════════════════════════════════╣
║  Line: 17                                      ║
║  File: File1                                   ║
║  Content: ␣␣replicas:␣4                         ║
║                                                ║
║  Line: 18                                      ║
║  File: File2                                   ║
║  Content: ␣␣replicas:␣1                         ║
║                                                ║
║  Line: 11                                      ║
║  File: File2                                   ║
║  Content: ␣␣␣␣test:␣notepad                      ║
║                                                ║
╚════════════════════════════════════════════════╝
```

## Verbose Logging Example

Use the `-Verbose` flag for detailed logging during the snapshotting process:

```powershell
Save-KubeSnapshot -Namespace "your-namespace" -OutputPath "./snapshots" -Verbose
```

### Verbose Output Example

Here’s an example of what verbose output may look like during the snapshot process:

```PowerShell
VERBOSE: Capturing snapshot for Deployment 'my-deployment' in namespace 'your-namespace'.
VERBOSE: Saving snapshot to: ./snapshots/Deployment_my-deployment_2024-10-14_12-00-00.yaml
VERBOSE: Checking for unmanaged pods in namespace 'your-namespace'.
VERBOSE: Found unmanaged pod: 'my-unmanaged-pod'. Saving snapshot...
```