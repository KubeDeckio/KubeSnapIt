---
title: Installation
parent: Documentation
nav_order: 1
layout: default
---

# Installation

KubeSnapIt can be installed through either the PowerShell Gallery or via Krew for Linux and macOS users.

## Installing via PowerShell Gallery

You can install **KubeSnapIt** directly from the PowerShell Gallery:

```powershell
Install-Module -Name KubeSnapIt -Repository PSGallery -Scope CurrentUser
```

To update **KubeSnapIt**:

```powershell
Update-Module -Name KubeSnapIt
```

<!-- ## Installing via Krew (Linux and macOS)

To install KubeSnapIt as a `kubectl` plugin using [Krew](https://krew.sigs.k8s.io/):

1. **Install Krew**: Follow the instructions [here](https://krew.sigs.k8s.io/docs/user-guide/setup/install/).
2. **Install KubeSnapIt**: 

```bash
curl -H "Cache-Control: no-cache" -O https://raw.githubusercontent.com/PixelRobots/KubeSnapIt/main/KubeSnapIt.yaml
kubectl krew install --manifest="./KubeSnapIt.yaml"
``` -->

## Requirements

- **PowerShell Version**: PowerShell 7 or higher is required.
- **Additional Dependencies**: The `powershell-yaml` module is needed for YAML parsing. It will be automatically installed when running KubeSnapIt from PowerShell. You also need `kubectl` installed.

Now that you've installed KubeSnapIt, head over to the [Usage Guide](/docs/usage) to start cleaning up your Kubernetes configurations!