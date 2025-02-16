---
title: Krew Plugin Usage
parent: Usage
nav_order: 2
layout: default
---

# ⎈ Krew Plugin Usage

KubeSnapIt is available as a **kubectl plugin** via **Krew** for Linux and macOS users. This allows seamless integration with your existing Kubernetes workflow.

{: .note }
Before using KubeSnapIt, ensure you are **connected to your Kubernetes cluster**. Use the following command to check your active Kubernetes context:

```bash
kubectl config current-context
```

If no context is set, configure one before proceeding.

---

## 📌 Parameters

| Parameter                  | Description                                                                 |
|----------------------------|-----------------------------------------------------------------------------|
| `--namespace`              | Specifies the namespace to snapshot or restore.                             |
| `--all-namespaces`         | Captures/restores all namespaces. Overrides the `--namespace` parameter.     |
| `--all-nonsystem-namespaces` | Captures all non-system namespaces, ignoring `--namespace` and `--all-namespaces`. |
| `--output-path`            | Path to save snapshots.                                                     |
| `--input-path`             | Path to restore snapshots from or for comparison.                           |
| `--compare-path`           | Path to the second snapshot for comparison.                                 |
| `--labels`                 | Filters objects using specified labels (e.g., `app=nginx`).                 |
| `--objects`                | Comma-separated list of specific objects in `kind/name` format.             |
| `--dry-run`                | Simulates snapshotting/restoring without changes.                           |
| `--restore`                | Restores resources from the specified snapshot path.                        |
| `--compare-with-cluster`   | Compares a snapshot with the current cluster state.                         |
| `--compare-snapshots`      | Compares two snapshots.                                                     |
| `--force`                  | Bypasses confirmation prompts when restoring snapshots.                     |
| `--verbose`                | Displays detailed output during execution.                                  |
| `--snapshot-helm`          | Backup Helm releases including values, manifests, and history.              |
| `--snapshot-helm-used-values` | Backup only the user-provided Helm values.                                  |
| `--restore-helm-snapshot`  | Restore a Helm release from a snapshot.                                    |
| `--help`                   | Displays KubeSnapIt help information.                                      |

---

## 📂 Taking a Snapshot

### Capture a Namespace Snapshot
```bash
kubectl kubesnapit --namespace "your-namespace" --output-path "./snapshots"
```
This captures all resources within the specified namespace.

### Capture All Namespaces
```bash
kubectl kubesnapit --all-namespaces --output-path "./snapshots"
```
This is useful for taking a full snapshot of your cluster.

### Capture Non-System Namespaces
```bash
kubectl kubesnapit --all-nonsystem-namespaces --output-path "./snapshots"
```
This captures all namespaces except system namespaces like `kube-system`.

---

## ⎈ Snapshotting Helm Releases

Helm releases can be backed up either fully or by storing only used values.

### Capture Full Helm Snapshots
```bash
kubectl kubesnapit --snapshot-helm --namespace "my-namespace" --output-path "./helm-backups"
```
This captures:
- Helm release values
- Helm release manifests
- Helm release history

### Capture Only Helm Used Values
```bash
kubectl kubesnapit --snapshot-helm-used-values --namespace "my-namespace" --output-path "./helm-backups"
```
This saves only user-provided Helm values.

### Capture Both Helm Snapshots & Used Values
```bash
kubectl kubesnapit --snapshot-helm --snapshot-helm-used-values --namespace "my-namespace" --output-path "./helm-backups"
```
This ensures **both full snapshots and values** are stored.

---

## 🔍 Comparing Snapshots

### Compare Snapshot vs Cluster
```bash
kubectl kubesnapit --compare-with-cluster --input-path "./snapshots"
```
This command checks differences between your snapshot and the live cluster.

### Compare Two Snapshots
```bash
kubectl kubesnapit --compare-snapshots --input-path "./snapshots/snapshot1" --compare-path "./snapshots/snapshot2"
```
Use this to track configuration changes over time.

---

## ♻️ Restoring Snapshots

### Restore a Snapshot
```bash
kubectl kubesnapit --restore --input-path "./snapshots/your_snapshot.yaml"
```
This applies the stored snapshot back to the cluster.

### Force Restore Without Confirmation
```bash
kubectl kubesnapit --restore --input-path "./snapshots/your_snapshot.yaml" --force
```
The `--force` flag bypasses confirmation prompts.

---

## 🏗️ Dry Run Mode

### Simulate Snapshot Capture
```bash
kubectl kubesnapit --namespace "your-namespace" --output-path "./snapshots" --dry-run
```
This verifies the snapshot process without saving any files.

### Simulate Restore Process
```bash
kubectl kubesnapit --restore --input-path "./snapshots/your_snapshot.yaml" --dry-run
```
This shows what would be restored without making changes.

---

## 🔎 Detailed Logging & Debugging

For troubleshooting or auditing, use `--verbose` mode to get detailed logs.
```bash
kubectl kubesnapit --namespace "your-namespace" --output-path "./snapshots" --verbose
```
This provides a breakdown of every operation performed.

📌 **For more details on logging, visit the [Logging and Output](../logging-output) page.** 🚀

