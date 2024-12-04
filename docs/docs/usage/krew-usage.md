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

## Taking a Snapshot

To capture a snapshot of Kubernetes resources in a specific namespace:

```bash
kubectl kubesnapit --namespace "your-namespace" --output-path "./snapshots"
```

To capture snapshots of all resources across all namespaces:

```bash
kubectl kubesnapit --all-namespaces --output-path "./snapshots"
```

To capture snapshots of all non-system namespaces:

```bash
kubectl kubesnapit --allnonsystemnamespaces --outputpath ./snapshots
```

To capture snapshots with specific labels:

```bash
kubectl kubesnapit --namespace my-namespace --labels app=nginx --outputpath ./snapshots
```

To capture snapshots of specific objects:

```bash
kubectl kubesnapit --namespace my-namespace --objects pod/my-pod,deployment/my-deployment --outputpath ./snapshots
```

---

## Snapshotting Helm Releases

### Capture Full Helm Snapshots
A full Helm snapshot includes:
- Helm release values
- Helm release manifests
- Helm release history

To capture snapshots of Helm releases in a specific namespace:

```bash
kubectl kubesnapit --snapshothelm --namespace my-namespace --outputpath ./helm-backups
```

To capture snapshots of Helm releases in all namespaces:

```bash
kubectl kubesnapit --snapshothelm --allnamespaces --outputpath ./helm-backups
```

To capture snapshots of Helm releases in all non-system namespaces:

```bash
kubectl kubesnapit --snapshothelm --allnonsystemnamespaces --outputpath ./helm-backups
```

---

### Capture Only Helm Used Values
The `--snapshothelmusedvalues` option captures only the **used values** for Helm releases. This includes all values (default and user-provided).

To capture only used values for Helm releases in a specific namespace:

```bash
kubectl kubesnapit --snapshothelmusedvalues --namespace my-namespace --outputpath ./helm-backups
```

To capture only used values for Helm releases in all namespaces:

```bash
kubectl kubesnapit --snapshothelmusedvalues --allnamespaces --outputpath ./helm-backups
```

To capture only used values for Helm releases in all non-system namespaces:

```bash
kubectl kubesnapit --snapshothelmusedvalues --allnonsystemnamespaces --outputpath ./helm-backups
```

---

### Combining Full Snapshots and Used Values
You can combine the `--snapshothelm` and `--snapshothelmusedvalues` options to capture a full Helm snapshot and used values simultaneously.

To capture both full snapshots and used values for Helm releases in a specific namespace:

```bash
kubectl kubesnapit --snapshothelm --snapshothelmusedvalues --namespace my-namespace --outputpath ./helm-backups
```

To capture both full snapshots and used values for Helm releases in all namespaces:

```bash
kubectl kubesnapit --snapshothelm --snapshothelmusedvalues --allnamespaces --outputpath ./helm-backups
```

To capture both full snapshots and used values for Helm releases in all non-system namespaces:

```bash
kubectl kubesnapit --snapshothelm --snapshothelmusedvalues --allnonsystemnamespaces --outputpath ./helm-backups
```

---

## Comparing Snapshots

To compare a local snapshot against the live cluster state:

```bash
kubectl kubesnapit --comparewithcluster --inputpath ./snapshots
```

To compare two local snapshots:

```bash
kubectl kubesnapit --comparesnapshots --inputpath ./snapshots/snapshot1 --comparepath ./snapshots/snapshot2
```

---

## Resource Restoration

To restore a Kubernetes resource from a snapshot using `kubectl KubeSnapIt`, use the following command. By default, this will ask for confirmation before restoring:

```bash
kubectl kubesnapit restore --inputpath ./snapshots/your_snapshot.yaml
```

### Skipping Confirmation with `--force`

If you want to bypass the confirmation prompt and restore the resources immediately, use the `--force` option:

```bash
kubectl kubesnapit restore --inputpath ./snapshots/your_snapshot.yaml --force
```

This command restores the resources from the specified snapshot without asking for confirmation.

---

## Dry Run Mode

Use the `--dry-run` option to simulate snapshotting or restoration processes without making any actual changes:

```bash
kubectl kubesnapit --namespace your-namespace --outputpath ./snapshots --dry-run
```

For detailed logging examples, check out our [Logging and Output](../logging-output) page.