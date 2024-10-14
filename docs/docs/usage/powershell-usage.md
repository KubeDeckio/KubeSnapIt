---
title: PowerShell Usage
parent: Usage
nav_order: 1
layout: default
---

# PowerShell Usage

If you're using **KubeSnapIt** via PowerShell, here are the usage examples to help you manage your Kubernetes resources effectively.

> **Note:** Ensure you are connected to your Kubernetes cluster before using KubeSnapIt. You can use `kubectl` commands to check your connection and manage your contexts.

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

To restore a Kubernetes resource from a snapshot:

```powershell
Invoke-KubeSnapIt -InputPath "./snapshots/your_snapshot.yaml"
```

For detailed logging examples, check out our [Logging and Output](../logging-output) page.
