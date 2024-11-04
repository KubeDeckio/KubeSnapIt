# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.7] - 2024-11-01

### Added
- **AllNonSystemNamespaces Parameter**: Introduced the `-AllNonSystemNamespaces` parameter to the `Invoke-KubeSnapIt` and `Save-KubeSnapshot` functions. This allows users to capture snapshots from all non-system namespaces, excluding `kube-system`, `kube-public`, `kube-node-lease`, and `default`.
- **Helm Chart Snapshot**: Added functionality to backup Helm releases and their values using the `-SnapshotHelm` parameter. This includes:
  - Fetching Helm release values.
  - Fetching Helm release manifests.
  - Fetching Helm release history.
  - Saving the fetched data to specified output paths.

### Fixed
- **Namespace Processing**: Ensured that the `Process-Namespace` function correctly handles single namespace strings and iterates over multiple namespaces when `-AllNonSystemNamespaces` is specified.

## [0.0.6] - 2024-10-30

### Added
- **Enhanced Error Handling**: Improved error handling in `Read-YamlFile` and `Compare-Files` functions.
    - `Read-YamlFile` now checks for:
        - Missing file paths, displaying an error if the path is invalid or the file is not found.
        - YAML format validation, ensuring required fields (`kind`, `metadata.name`) are present.
    - `Compare-Files` function enhancements include:
        - Validation for the presence of `$LocalFile` and error messaging if the file is missing or unreadable.
        - Cluster snapshot retrieval wrapped in error handling, with feedback for failed `kubectl` access or invalid resource information.
        - Temporary file write protection, ensuring successful snapshot output to a specified location and clear messaging if issues occur.
- **UI Switch Update**: Modified the `-UI` switch to display the `Show-KubeSnapItBanner` banner when running the script in CLI mode without blocking subsequent operations. This ensures that banner display and further command execution can occur seamlessly in CLI environments.

### Fixed
- **Comparison Execution**: Resolved issues where `Compare-Files` would not complete if the `$CompareFile` was not explicitly provided, adding automatic snapshot creation when needed and appropriate validation checks.

## [0.0.5] - 2024-10-22

### Fixed
- **Function Execution Logic**: Addressed the issue where the function was incorrectly requiring a namespace for comparison operations, ensuring that users can now run comparisons against the cluster or between snapshots without needing to specify a namespace.

## [0.0.4] - 2024-10-22

### Added
- **Separate Comparison Switches**: Introduced two distinct switches for comparison:
  - `-CompareWithCluster`: Allows users to compare a snapshot against the current state of the Kubernetes cluster without requiring a namespace.
  - `-CompareSnapshots`: Allows users to compare two snapshots, enabling more flexible comparison options.

### Changed
- **Refined Operation Logic**: Improved the internal logic to handle operations more clearly using `switch` statements, ensuring that each operation (Snapshot, Compare, Restore) is handled independently without unnecessary dependencies.
- **Improved Error Messaging**: Enhanced error messages for missing required parameters specific to each operation, providing clearer feedback to users.

### Fixed
- **Namespace Requirement for Compare Operations**: Resolved the issue where comparing snapshots against the cluster incorrectly enforced namespace requirements, allowing users to perform comparisons without specifying a namespace.

## [0.0.3] - 2024-10-22

### Changed
- **Removed ASCII Art from Output**: Replaced ASCII art in the comparison summary with cleaner, simpler text formatting to improve compatibility and readability across different terminals and UI environments.

## [0.0.2] - 2024-10-18

### Added
- **Empty Namespace Detection**: Added functionality to detect and notify the user when no resources are found within a specified namespace, displaying `"No resources found in the namespace '<namespace>'"`.
- **Cluster-Scoped Resources Feedback**: Introduced feedback when no cluster-scoped resources are found with the `--all-namespaces` option, displaying `"No cluster-scoped resources found."`.
- **Enhanced Confirmation Prompt**: The confirmation prompt for restores now accepts both `"yes"` and `"y"` as valid inputs, improving user experience.
- **Force Restore Option**: Added a `-Force` parameter to `Restore-KubeSnapshot`, allowing users to bypass the confirmation prompt for restoring snapshots.

### Changed
- **Error Handling for Missing Namespaces**: Suppressed unnecessary error messages when attempting to snapshot a non-existent namespace, providing a user-friendly message instead.
- **Verbose Output Improvements**: Improved the verbose logging throughout the snapshot and restore processes, providing clearer feedback during execution.

### Fixed
- **Resource Snapshot Processing**: Unified handling of namespaced and cluster-scoped resources for consistent snapshotting and better error handling.

## [0.0.1] - 2024-10-14

### Added
- Initial release of **KubeSnapIt** with the following core features:
  - Snapshot functionality for various Kubernetes resource types (e.g., **Deployments**, **ConfigMaps**, **Services**, **ClusterRoles**).
  - Support for taking snapshots from specific namespaces and all namespaces.
  - **Diff** functionality to compare local snapshots against live cluster states and between snapshot files.
  - **Restore** functionality to restore Kubernetes resources from snapshots.