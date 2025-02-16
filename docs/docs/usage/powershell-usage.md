---
title: PowerShell Usage
parent: Usage
nav_order: 1
layout: default
---

# 📸 PowerShell Usage

If you're using **KubeSnapIt** via PowerShell, this guide provides step-by-step instructions to help you **capture**, **compare**, and **restore** Kubernetes snapshots efficiently.

{: .note }
Before using KubeSnapIt, ensure that you are **connected to your Kubernetes cluster**. Use the command below to check your active Kubernetes context:

```powershell
kubectl config current-context
```

This will display the current Kubernetes context you are connected to. If no context is set, configure one before proceeding.

---

## 🛠️ Understanding Parameters

KubeSnapIt provides a variety of options to fine-tune your snapshot and restore operations. Below is a breakdown of the key parameters:

| Parameter                  | Description                                                                 |
|----------------------------|-----------------------------------------------------------------------------|
| `-Namespace`               | Specifies the namespace to snapshot or restore.                             |
| `-AllNamespaces`           | Captures/restores all namespaces. Overrides the `-Namespace` parameter.     |
| `-AllNonSystemNamespaces`  | Captures all non-system namespaces, ignoring `-Namespace` and `-AllNamespaces`. |
| `-OutputPath`              | Path to save snapshots.                                                     |
| `-InputPath`               | Path to restore snapshots from or for comparison.                           |
| `-ComparePath`             | Path to the second snapshot for comparison.                                 |
| `-Labels`                  | Filters objects using specified labels (e.g., `app=nginx`).                 |
| `-Objects`                 | Comma-separated list of specific objects in `kind/name` format.             |
| `-DryRun`                  | Simulates snapshotting/restoring without changes.                           |
| `-Restore`                 | Restores resources from the specified snapshot path.                        |
| `-CompareWithCluster`      | Compares a snapshot with the current cluster state.                         |
| `-CompareSnapshots`        | Compares two snapshots.                                                     |
| `-Force`                   | Bypasses confirmation prompts when restoring snapshots.                     |
| `-Verbose`                 | Displays detailed output during execution.                                  |
| `-SnapshotHelm`            | Backup Helm releases including values, manifests, and history.              |
| `-SnapshotHelmUsedValues`  | Backup only the user-provided Helm values.                                  |
| `-RestoreHelmSnapshot`     | Restore a Helm release from a snapshot.                                    |
| `-Help`                    | Displays KubeSnapIt help information.                                      |

---

## 📂 Taking a Snapshot

KubeSnapIt allows you to take snapshots of **entire clusters**, **specific namespaces**, or **filtered resources**.

### Capture a Namespace Snapshot
```powershell
Invoke-KubeSnapIt -Namespace "your-namespace" -OutputPath "./snapshots"
```
This command captures all resources within the specified namespace and saves them in the defined output path.

### Capture All Namespaces
```powershell
Invoke-KubeSnapIt -AllNamespaces -OutputPath "./snapshots"
```
This option is useful when you need a full snapshot of your entire Kubernetes cluster.

### Capture Non-System Namespaces
```powershell
Invoke-KubeSnapIt -AllNonSystemNamespaces -OutputPath "./snapshots"
```
This captures all namespaces **except system namespaces** like `kube-system`, making it useful for application-focused snapshots.

---

## ⎈ Snapshotting Helm Releases

Helm releases can be backed up in full, including manifests, history, and values, or you can capture only the user-defined values.

### Capture Full Helm Snapshots
```powershell
Invoke-KubeSnapIt -SnapshotHelm -Namespace "my-namespace" -OutputPath "./helm-backups"
```
This captures:
- Helm release values
- Helm release manifests
- Helm release history

### Capture Only Helm Used Values
```powershell
Invoke-KubeSnapIt -SnapshotHelmUsedValues -Namespace "my-namespace" -OutputPath "./helm-backups"
```
This saves only the user-provided Helm values, useful for tracking configuration changes.

### Capture Both Helm Snapshots & Used Values
```powershell
Invoke-KubeSnapIt -SnapshotHelm -SnapshotHelmUsedValues -Namespace "my-namespace" -OutputPath "./helm-backups"
```
This ensures **both full snapshots and values** are stored for disaster recovery and audit purposes.

---

## 🔍 Comparing Snapshots

Comparing snapshots allows you to track **configuration drift** or validate changes before applying them.

### Compare Snapshot vs Cluster
```powershell
Invoke-KubeSnapIt -CompareWithCluster -InputPath "./snapshots"
```
This command checks how your saved snapshot differs from the live cluster state.

### Compare Two Snapshots
```powershell
Invoke-KubeSnapIt -CompareSnapshots -InputPath "./snapshots/snapshot1" -ComparePath "./snapshots/snapshot2"
```
Use this when you want to see what changed between two different snapshots.

---

## ♻️ Restoring Snapshots

KubeSnapIt can be used to **restore Kubernetes resources** from a previous snapshot.

### Restore a Snapshot
```powershell
Invoke-KubeSnapIt -Restore -InputPath "./snapshots/your_snapshot.yaml"
```
This applies the resources stored in the snapshot back to the cluster.

### Force Restore Without Confirmation
```powershell
Invoke-KubeSnapIt -Restore -InputPath "./snapshots/your_snapshot.yaml" -Force
```
The `-Force` flag skips confirmation prompts for fully automated restores.

---

## 🏗️ Dry Run Mode

Before applying any changes, you can **simulate** actions using Dry Run mode.

### Simulate Snapshot Capture
```powershell
Invoke-KubeSnapIt -Namespace "your-namespace" -OutputPath "./snapshots" -DryRun
```
This verifies the snapshot process without saving any files.

### Simulate Restore Process
```powershell
Invoke-KubeSnapIt -Restore -InputPath "./snapshots/your_snapshot.yaml" -DryRun
```
This allows you to see what would be restored **without making any actual changes**.

---

## 🔎 Detailed Logging & Debugging

For troubleshooting or auditing, use `-Verbose` mode to get detailed logs.
```powershell
Invoke-KubeSnapIt -Namespace "your-namespace" -OutputPath "./snapshots" -Verbose
```
This provides a breakdown of every operation performed.

📌 **For more details on logging, visit the [Logging and Output](../logging-output) page.** 🚀

