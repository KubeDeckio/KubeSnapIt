---
title: Krew Plugin Usage
parent: Usage
nav_order: 2
layout: default
---

# Krew Plugin Usage

If you're using **KubeSnapIt** via Krew as a `kubectl` plugin (Linux/macOS), here are the usage examples to help you manage your Kubernetes resources effectively.

{: .note }
Ensure you are connected to your Kubernetes cluster before using KubeSnapIt. You can use `kubectl` commands to check your connection and manage your contexts.

## Parameters

| Parameter            | Description                                                                 |
|----------------------|-----------------------------------------------------------------------------|
| `-Namespace`         | Specifies the namespace to snapshot or restore.                             |
| `-AllNamespaces`     | Captures or restores all namespaces. Overrides the `-Namespace` parameter.   |
| `-OutputPath`        | Path to save the snapshot files.                                             |
| `-InputPath`         | Path to restore snapshots from or for comparison.                           |
| `-ComparePath`       | Path to the second snapshot for comparison.                                 |
| `-Labels`            | Filters Kubernetes objects based on specified labels (e.g., `app=nginx`).   |
| `-Objects`           | Comma-separated list of specific objects in the `kind/name` format.          |
| `-DryRun`            | Simulates snapshotting or restoring without making any actual changes.       |
| `-Restore`           | Restores resources from the specified snapshot path.                        |
| `-Compare`           | Compares two snapshots or a snapshot with the current cluster state.         |
| `-CompareWithCluster`| Compares a snapshot with the current cluster state.                         |
| `-Force`             | Bypasses confirmation prompts when restoring snapshots.                     |
| `-Verbose`           | Shows detailed output during the snapshot, restore, or comparison process.   |
| `-Help`              | Displays the help information for using `KubeSnapIt`.                       |

## Resource Snapshotting

To capture a snapshot of Kubernetes resources in a specific namespace:

```bash
kubectl KubeSnapIt --namespace "your-namespace" --output-path "./snapshots"
```

To capture snapshots of all resources across all namespaces:

```bash
kubectl KubeSnapIt --all-namespaces --output-path "./snapshots"
```

## Resource Diffing

To compare a local snapshot against the live cluster state:

```bash
kubectl KubeSnapIt diff --local-file "./snapshots/your_snapshot.yaml"
```

To compare two local snapshots:

```bash
kubectl KubeSnapIt diff --local-file "./snapshots/your_snapshot1.yaml" --compare-file "./snapshots/your_snapshot2.yaml"
```

## Resource Restoration

To restore a Kubernetes resource from a snapshot using `kubectl KubeSnapIt`, use the following command. By default, this will ask for confirmation before restoring:

```bash
kubectl KubeSnapIt restore --input-path "./snapshots/your_snapshot.yaml"
```

### Skipping Confirmation with `--force`

If you want to bypass the confirmation prompt and restore the resources immediately, use the `--force` option:

```bash
kubectl KubeSnapIt restore --input-path "./snapshots/your_snapshot.yaml" --force
```

This command restores the resources from the specified snapshot without asking for confirmation.

## Dry Run Mode

Use the `--dry-run` option to simulate snapshotting or restoration processes without making any actual changes:

```bash
kubectl KubeSnapIt --namespace "your-namespace" --output-path "./snapshots" --dry-run
```

For detailed logging examples, check out our [Logging and Output](../logging-output) page.
