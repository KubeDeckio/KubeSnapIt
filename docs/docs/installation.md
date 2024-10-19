---
title: Installation
parent: Documentation
nav_order: 1
layout: default
---

# Installation

KubeSnapIt can be installed through the PowerShell Gallery or Krew for Linux and macOS users.

## Installing via PowerShell Gallery

You can install **KubeSnapIt** directly from the PowerShell Gallery:

```powershell
Install-Module -Name KubeSnapIt -Repository PSGallery -Scope CurrentUser
```

To update **KubeSnapIt**:

```powershell
Update-Module -Name KubeSnapIt
```

## Installing via Krew (Linux and macOS)

To install KubeSnapIt as a `kubectl` plugin using [Krew](https://krew.sigs.k8s.io/):

1. **Install Krew**: Follow the instructions [here](https://krew.sigs.k8s.io/docs/user-guide/setup/install/).
2. **Install KubeSnapIt**: 

```bash
# Fetch the latest release tag using GitHub's API
LATEST_VERSION=$(curl -s https://api.github.com/repos/KubeDeckio/KubeSnapIt/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

# Download the KubeSnapIt.yaml file from the latest release
curl -L -H "Cache-Control: no-cache" -O https://github.com/KubeDeckio/KubeSnapIt/releases/download/$LATEST_VERSION/KubeSnapIt.yaml

# Install the plugin using the downloaded KubeSnapIt.yaml file
kubectl krew install --manifest="./KubeSnapIt.yaml"
```

## Requirements

- **PowerShell Version**: PowerShell 7 or higher is required.
- **Additional Dependencies**: The `powershell-yaml` module is needed for YAML parsing. It will be automatically installed when running KubeSnapIt from PowerShell. You also need `kubectl` installed.

Now that you've installed KubeSnapIt visit the [Usage Guide](/docs/usage) to start cleaning up your Kubernetes configurations!
