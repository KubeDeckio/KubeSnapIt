---
title: PowerShell Usage
parent: Usage
nav_order: 1
layout: default
---

# PowerShell Usage

If you're using **KubeSnapIt** via PowerShell, here are the usage examples to help you manage your Kubernetes resources effectively.

{: .note }
Ensure you are connected to your Kubernetes cluster before using KubeSnapIt. You can use `kubectl` commands to check your connection and manage your contexts.

## Parameters

| Parameter                  | Description                                                                 |
|----------------------------|-----------------------------------------------------------------------------|
| `-Namespace`               | Specifies the namespace to snapshot or restore.                             |
| `-AllNamespaces`           | Captures or restores all namespaces. Overrides the `-Namespace` parameter.   |
| `-AllNonSystemNamespaces`  | Capture all non-system namespaces. If this is provided, `-Namespace` and `-AllNamespaces` will be ignored. |
| `-OutputPath`              | Path to save the snapshot files.                                             |
| `-InputPath`               | Path to restore snapshots from or for comparison.                           |
| `-ComparePath`             | Path to the second snapshot for comparison.                                 |
| `-Labels`                  | Filters Kubernetes objects based on specified labels (e.g., `app=nginx`).   |
| `-Objects`                 | Comma-separated list of specific objects in the `kind/name` format.          |
| `-DryRun`                  | Simulates snapshotting or restoring without making any actual changes.       |
| `-Restore`                 | Restores resources from the specified snapshot path.                        |
| `-Compare`                 | Compares two snapshots or a snapshot with the current cluster state.         |
| `-CompareWithCluster`      | Compares a snapshot with the current cluster state.                         |
| `-Force`                   | Bypasses confirmation prompts when restoring snapshots.                     |
| `-Verbose`                 | Shows detailed output during the snapshot, restore, or comparison process.   |
| `-SnapshotHelm`            | Backup Helm releases and their values, manifests, and history.              |
| `-SnapshotHelmUsedValues`  | Backup only the used values (default and user-provided) for Helm releases.   |
| `-Help`                    | Displays the help information for using `KubeSnapIt`.                       |

---

## Taking a Snapshot

To capture a snapshot of Kubernetes resources in a specific namespace:

```powershell
Invoke-KubeSnapIt -Namespace "your-namespace" -OutputPath "./snapshots"
```

To capture snapshots of all resources across all namespaces:

```powershell
Invoke-KubeSnapIt -AllNamespaces -OutputPath "./snapshots"
```

To capture snapshots of all resources across all non system namespaces:

```powershell
Invoke-KubeSnapIt -AllNonSystemNamespaces -OutputPath "./snapshots"
```

---

## Snapshotting Helm Releases

### Capture Full Helm Snapshots
A full Helm snapshot includes:
- Helm release values
- Helm release manifests
- Helm release history

Capture snapshots of Helm releases in a specific namespace:

```powershell
Invoke-KubeSnapIt -SnapshotHelm -Namespace "my-namespace" -OutputPath "./helm-backups"
```

To capture snapshots of Helm releases in all namespaces:

```powershell
Invoke-KubeSnapIt -SnapshotHelm -AllNamespaces -OutputPath "./helm-backups"
```

To capture snapshots of Helm releases in all non-system namespaces:

```powershell
Invoke-KubeSnapIt -SnapshotHelm -AllNonSystemNamespaces -OutputPath "./helm-backups"
```

---

### Capture Only Helm Used Values
The `-SnapshotHelmUsedValues` switch captures only the **used values** for Helm releases. This includes all values (default and user-provided).

To capture only used values for Helm releases in a specific namespace:

```powershell
Invoke-KubeSnapIt -SnapshotHelmUsedValues -Namespace "my-namespace" -OutputPath "./helm-backups"
```

To capture only used values for Helm releases in all namespaces:

```powershell
Invoke-KubeSnapIt -SnapshotHelmUsedValues -AllNamespaces -OutputPath "./helm-backups"
```

To capture only used values for Helm releases in all non-system namespaces:

```powershell
Invoke-KubeSnapIt -SnapshotHelmUsedValues -AllNonSystemNamespaces -OutputPath "./helm-backups"
```

---

### Combining Full Snapshots and Used Values
You can combine the `-SnapshotHelm` and `-SnapshotHelmUsedValues` switches to capture a full Helm snapshot and used values simultaneously.

To capture both full snapshots and used values for Helm releases in a specific namespace:

```powershell
Invoke-KubeSnapIt -SnapshotHelm -SnapshotHelmUsedValues -Namespace "my-namespace" -OutputPath "./helm-backups"
```

To capture both full snapshots and used values for Helm releases in all namespaces:

```powershell
Invoke-KubeSnapIt -SnapshotHelm -SnapshotHelmUsedValues -AllNamespaces -OutputPath "./helm-backups"
```

To capture both full snapshots and used values for Helm releases in all non-system namespaces:

```powershell
Invoke-KubeSnapIt -SnapshotHelm -SnapshotHelmUsedValues -AllNonSystemNamespaces -OutputPath "./helm-backups"
```

---

## Comparing Snapshots

To compare a local snapshot against the live cluster state:

```powershell
Invoke-KubeSnapIt -CompareWithCluster -InputPath "./snapshots"
```

To compare two local snapshots:

```powershell
Invoke-KubeSnapIt -CompareSnapshots -InputPath "./snapshots/snapshot1" -ComparePath "./snapshots/snapshot2"
```

---

## Restoring a Snapshot

To restore a Kubernetes resource from a snapshot, use the following command. By default, the script will ask for confirmation before proceeding with the restore:

```powershell
Invoke-KubeSnapIt -Restore -InputPath "./snapshots/your_snapshot.yaml"
```

### Skipping Confirmation with `-Force`

If you want to bypass the confirmation prompt and restore the resources immediately, use the `-Force` option:

```powershell
Invoke-KubeSnapIt -Restore -InputPath "./snapshots/your_snapshot.yaml" -Force
```

This command restores the resources from the specified snapshot without asking for confirmation.

---

## Dry Run Mode

Use the `-DryRun` option to simulate snapshotting or restoration processes without making any actual changes:

```powershell
Invoke-KubeSnapIt -Namespace "your-namespace" -OutputPath "./snapshots" -DryRun
```

This command simulates the snapshot process for the specified namespace without saving any files.

Similarly, you can use the `-DryRun` option during restoration to simulate the restore process:

```powershell
Invoke-KubeSnapIt -Restore -InputPath "./snapshots/your_snapshot.yaml" -DryRun
```

This command simulates the restoration of resources from the specified snapshot without applying any changes.

For detailed logging examples, check out our [Logging and Output](../logging-output) page.