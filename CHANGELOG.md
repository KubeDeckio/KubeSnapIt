# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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