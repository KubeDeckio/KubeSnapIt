---
title: Installation
parent: Documentation
nav_order: 1
layout: default
---

# ⚡ Installing KubeSnapIt

KubeSnapIt can be installed on **Windows, Linux, and macOS** via the **PowerShell Gallery** or **Krew** for `kubectl` users.

---

## 🖥️ Installing via PowerShell Gallery

For PowerShell users, install **KubeSnapIt** directly from the PowerShell Gallery:

```powershell
Install-Module -Name KubeSnapIt -Repository PSGallery -Scope CurrentUser
```

### 🔄 Updating KubeSnapIt

To update **KubeSnapIt** to the latest version:

```powershell
Update-Module -Name KubeSnapIt
```

---

## 🌍 Installing via Krew (Linux/macOS)

For Kubernetes users on **Linux and macOS**, install KubeSnapIt as a `kubectl` plugin using **Krew**:

### 1️⃣ Install Krew
Follow the official Krew installation guide [here](https://krew.sigs.k8s.io/docs/user-guide/setup/install/).

### 2️⃣ Install KubeSnapIt via Krew

```bash
kubectl krew install kubesnapit
```

### 🔄 Updating KubeSnapIt via Krew

```bash
kubectl krew upgrade kubesnapit
```

---

## 🔧 Requirements

✅ **PowerShell Version**: PowerShell 7 or higher is required.  
✅ **Additional Dependencies**: The `powershell-yaml` module is needed for YAML parsing and will be installed automatically.  
✅ **Krew for Plugin Users**: If using Krew, ensure `kubectl` and Krew are properly configured.  

---

✅ **Next Steps:** Now that KubeSnapIt is installed, check out the [Usage Guide](/docs/usage) to start capturing and comparing Kubernetes snapshots! 📸🚀

