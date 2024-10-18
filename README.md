
<p align="center">
  <img src="./images/KubeSnapIt.png" />
</p>
<h1 align="center" style="font-size: 100px;">
  <b>KubeSnapIt</b>
</h1>

</br>

![Publish Module to PowerShell Gallery](https://github.com/KubeDeckio/KubeSnapIt/actions/workflows/publish-psgal.yml/badge.svg)
[![Publish Plugin to Krew](https://github.com/KubeDeckio/KubeSnapIt/actions/workflows/publish-krewplugin.yaml/badge.svg)](https://github.com/KubeDeckio/KubeSnapIt/actions/workflows/publish-krewplugin.yaml)
![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/KubeSnapIt.svg)
![Downloads](https://img.shields.io/powershellgallery/dt/KubeSnapIt.svg)
![Krew Version](https://img.shields.io/github/v/release/KubeDeckio/KubeSnapIt?label=Krew%20Version)
![License](https://img.shields.io/github/license/PixelRobots/KubeSnapIt.svg)

---

**KubeSnapIt** is a PowerShell-based tool for Kubernetes that simplifies the management of Kubernetes resources by enabling users to take snapshots, compare configurations, and restore states efficiently. It is designed to help Kubernetes administrators and developers manage their cluster configurations effectively.

## Documentation

For complete installation, usage, and advanced configuration instructions, please visit the [KubeSnapIt Documentation Site](https://kubesnapit.io).

## Features

- **Resource Snapshotting:** Capture the current state of Kubernetes objects (Deployments, Services, ConfigMaps, etc.) in YAML format.
- **Resource Diffing:** Compare snapshots against live cluster states or between two local snapshots to identify changes.
- **Resource Restoration:** Restore Kubernetes configurations from snapshots quickly and easily.
- **Automated Scheduled Snapshots:** Schedule periodic snapshots for continuous configuration tracking.
- **Snapshot by Labels:** Specify labels to filter which Kubernetes objects are included in snapshots.
- **Dry Run Mode:** Simulate snapshotting or restoration processes without making any actual changes.
- **Verbose Logging:** Get detailed logs of all operations using the `-Verbose` flag.

## Installation

### PowerShell Gallery

To install **KubeSnapIt** via PowerShell Gallery:

```powershell
Install-Module -Name KubeSnapIt -Repository PSGallery -Scope CurrentUser
```

### Krew (Linux and macOS)

To install **KubeSnapIt** as a kubectl plugin using Krew:

```bash
# Fetch the latest release tag using GitHub's API
LATEST_VERSION=$(curl -s https://api.github.com/repos/KubeDeckio/KubeSnapIt/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

# Download the KubeSnapIt.yaml file from the latest release
curl -L -H "Cache-Control: no-cache" -O https://github.com/KubeDeckio/KubeSnapIt/releases/download/$LATEST_VERSION/KubeSnapIt.yaml

# Install the plugin using the downloaded KubeSnapIt.yaml file
kubectl krew install --manifest="./KubeSnapIt.yaml"
```

### Platform Support

**KubeSnapIt** installed via Krew is supported on Linux and macOS. It does not support Windows at this time.

For additional instructions, refer to the [KubeSnapIt Documentation Site.](https://kubesnapit.io)

## Changelog

All notable changes to this project are documented in the [CHANGELOG](./CHANGELOG.md).

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more details.
