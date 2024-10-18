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

## Resource Snapshotting

To capture a snapshot of Kubernetes resources in a specific namespace:

```powershell
Invoke-KubeSnapIt -Namespace "your-namespace" -OutputPath "./snapshots"
```

To capture snapshots of all resources across all namespaces:

```powershell
Invoke-KubeSnapIt -AllNamespaces -OutputPath "./snapshots"
```

## Resource Diffing

To compare a local snapshot against the live cluster state:

```powershell
Invoke-KubeSnapIt -LocalFile "./snapshots/your_snapshot.yaml"
```

To compare two local snapshots:

```powershell
CompareFiles -LocalFile "./snapshots/your_snapshot1.yaml" -CompareFile "./snapshots/your_snapshot2.yaml"
```

## Resource Restoration

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
