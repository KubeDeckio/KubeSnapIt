---
title: Logging and Output
parent: Usage
nav_order: 3
layout: default
---

# 📜 Logging and Output

KubeSnapIt provides detailed logging for every operation, allowing users to track and debug snapshot creation, resource restoration, and diff comparisons.

{: .note }
For in-depth troubleshooting, always use the `-Verbose` flag to view detailed logs of what KubeSnapIt is doing.

---

## 📝 Snapshot Logging Example

When creating snapshots, a summary output displays each resource being saved:

```PowerShell
Deployment 'access' snapshot saved: ./snapshots/Deployment_access_2024-10-14_12-55-22.yaml
ConfigMap 'kube-root-ca.crt' snapshot saved: ./snapshots/ConfigMap_kube-root-ca.crt_2024-10-14_12-55-23.yaml
Unmanaged pod 'my-unmanaged-pod' snapshot saved: ./snapshots/unmanaged_pod_my-unmanaged-pod_2024-10-14_12-55-26.yaml
```

This output confirms that each resource has been successfully captured and stored.

---

## ♻️ Restore Logging Example

When restoring resources from a snapshot, KubeSnapIt provides feedback on the restoration process:

```PowerShell
Restoring resource from file: "./snapshots/Deployment_noaccess_2024-10-14_14-47-46.yaml"
deployment.apps/noaccess configured
Resource from './snapshots/Deployment_noaccess_2024-10-14_14-47-46.yaml' restored successfully.
```

This output indicates which resources have been applied and whether they were updated or left unchanged.

---

## 🔍 Diff Logging Example

KubeSnapIt provides a detailed summary of differences when comparing snapshots:

```PowerShell
File1 = snapshots/Deployment_noaccess_2024-10-14_14-49-30.yaml
File2 = snapshots/Deployment_noaccess_2024-10-14_14-47-46.yaml

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

The summary shows exactly where changes occurred between two snapshots, making it easy to spot configuration differences.

---

## 📢 Verbose Logging Example

For even more detailed output, enable `-Verbose` mode:

```powershell
Save-KubeSnapshot -Namespace "your-namespace" -OutputPath "./snapshots" -Verbose
```

### 🔎 Verbose Output Example

When using the `-Verbose` flag, the output provides deeper insights into each step of the snapshot process:

```PowerShell
VERBOSE: Capturing snapshot for Deployment 'my-deployment' in namespace 'your-namespace'.
VERBOSE: Saving snapshot to: ./snapshots/Deployment_my-deployment_2024-10-14_12-00-00.yaml
VERBOSE: Checking for unmanaged pods in namespace 'your-namespace'.
VERBOSE: Found unmanaged pod: 'my-unmanaged-pod'. Saving snapshot...
```

This is useful for debugging and verifying that KubeSnapIt is processing the correct resources.

---

## 📂 Saving Logs to a File

To capture logs for later review while still displaying them in the terminal, use `Tee-Object`:

```PowerShell
Save-KubeSnapshot -Namespace "your-namespace" -OutputPath "./snapshots" -Verbose | Tee-Object -FilePath "./logs/kubesnapit.log"
```

This ensures logs are stored for later analysis while still being visible in the terminal.

📌 **For more details on using KubeSnapIt, visit the [Usage Guide](../usage).** 🚀

