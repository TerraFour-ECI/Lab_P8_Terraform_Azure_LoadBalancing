# 🧭 Terraform Installation Guide

> **Course:** BluePrints / ARSW · **Goal:** Set up your local environment
> to run and test Terraform against Azure.

---

## 🧰 1. Prerequisites

Before installing Terraform make sure you have:

* ☁️ An active **Azure** account (Azure for Students works fine).
* 🛠️ The **Azure CLI** (`az`) installed and authenticated.
* 🐙 Access to **Git** and **GitHub**.
* 🌐 Internet connectivity and admin rights on your machine.

---

## 🍎 2. Install on macOS

### Option 1 — via Homebrew (recommended)

```bash
brew update
brew install terraform
```

### Verify the installation

```bash
terraform -version
```

**Sample output:**

```text
Terraform v1.9.5
on darwin_arm64
```

### Update Terraform

```bash
brew upgrade terraform
```

> 💡 On Apple Silicon (M1/M2/M3) Homebrew installs the ARM build
> automatically.

---

## 🐧 3. Install on Linux (Ubuntu/Debian)

### Step 1 — Install dependencies

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
```

### Step 2 — Add the official HashiCorp repository

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
```

### Step 3 — Install Terraform

```bash
sudo apt-get update && sudo apt-get install terraform -y
```

### Verify the installation (Linux)

```bash
terraform -version
```

**Expected output:**

```text
Terraform v1.9.x
```

### Update

```bash
sudo apt-get update && sudo apt-get upgrade terraform -y
```

---

## 🪟 4. Install on Windows

### Option 1 — Winget (Windows 10/11)

```powershell
winget install HashiCorp.Terraform
```

### Option 2 — Manual (ZIP)

1. Download the ZIP from
   [Terraform Downloads](https://developer.hashicorp.com/terraform/downloads).
2. Extract to `C:\terraform`.
3. Add that path to the system **PATH**.
4. Open PowerShell and verify:

```powershell
terraform -version
```

> ⚠️ If the command is not recognised, double-check `PATH` or restart
> your shell session.

---

## ☁️ 5. Authenticate to Azure

Sign in:

```bash
az login
```

Verify the active subscription:

```bash
az account show
```

Switch subscription if you have several:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"
```

---

## 🧩 6. Initialise a Terraform project

From inside the `infra/` folder:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out plan.tfplan
terraform apply "plan.tfplan"
```

For the lab specifically, use the remote backend:

```bash
terraform init -backend-config=backend.hcl
terraform plan  -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars -auto-approve
```

---

## 🧼 7. Uninstall

**macOS:**

```bash
brew uninstall terraform
```

**Linux:**

```bash
sudo apt-get remove terraform -y
```

**Windows:**

```powershell
winget uninstall HashiCorp.Terraform
```

---

## 🧠 Common errors

| Error                            | Cause                                   | Fix                                                  |
| :------------------------------- | :-------------------------------------- | :--------------------------------------------------- |
| `terraform: command not found`   | PATH not configured                     | Add the binary to PATH or reinstall                  |
| `az login` fails                 | Outdated Azure CLI                      | Run `az upgrade`                                     |
| `Insufficient privileges`        | No permissions on the subscription      | Request the **Contributor** role                     |
| `Error acquiring state lock`     | Backend misconfigured / stuck blob lease| Validate the Azure Storage container (`tfstate`)     |
| `BlobAlreadyExists` on init      | Old state left behind                   | Inspect the container and remove conflicting blobs   |

---

## 📘 Official references

* [Terraform CLI Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* [Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
* [Azure CLI Docs](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
