---
title: Krew Plugin Usage
parent: Usage
nav_order: 2
layout: default
---

# Krew Plugin Usage

If you're using **KubeSnapIt** via Krew as a `kubectl` plugin (Linux/macOS), here are the usage examples to help you manage your Kubernetes resources effectively.

> **Note:** Ensure you are connected to your Kubernetes cluster before using KubeSnapIt. You can use `kubectl` commands to check your connection and manage your contexts.

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

To restore a Kubernetes resource from a snapshot:

```bash
kubectl KubeSnapIt restore --input-path "./snapshots/your_snapshot.yaml"
```

## Dry Run Mode

Use the `--dry-run` option to simulate snapshotting or restoration processes without making any actual changes:

```bash
kubectl KubeSnapIt --namespace "your-namespace" --output-path "./snapshots" --dry-run
```

For detailed logging examples, check out our [Logging and Output](../logging-output) page.
