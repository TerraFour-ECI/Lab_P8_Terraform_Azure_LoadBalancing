# 🔐 Azure OIDC Setup for GitHub Actions

> Step-by-step guide to wire **GitHub Actions** with **Azure AD** through
> **OpenID Connect** federation, so the CI/CD pipeline never stores a
> long-lived secret.

---

## 🧰 Prerequisites

* Azure CLI (`az`) authenticated against the lab subscription.
* Owner (or User Access Administrator + Application Administrator) over
  the subscription.
* Admin rights on the GitHub repository to create *Secrets* and
  *Environments*.

```bash
az login
az account set --subscription "cd4ddc1a-042b-4bc4-b751-024854e4f459"
```

---

## 🪪 Step 1 — Create the App Registration

```bash
APP_ID=$(az ad app create \
  --display-name "lab8-github-actions" \
  --query appId -o tsv)
echo "APP_ID=$APP_ID"
```

## 🤖 Step 2 — Create the Service Principal

```bash
az ad sp create --id "$APP_ID"
```

## 📜 Step 3 — Grant Contributor over the lab scope

```bash
az role assignment create \
  --assignee "$APP_ID" \
  --role Contributor \
  --scope "/subscriptions/cd4ddc1a-042b-4bc4-b751-024854e4f459"
```

> 💡 For tighter scope, use the lab Resource Group instead of the whole
> subscription once `lab8-rg` exists.

## 🔗 Step 4 — Federated credentials

Create one credential **per branch / environment** that GitHub Actions
will use.

### 4.a — `main` branch (apply / destroy)

```bash
cat > federated-main.json <<EOF
{
  "name": "github-actions-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:TerraFour-ECI/arsw-terraform-azure-load-balancing:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters federated-main.json
```

### 4.b — Pull requests (plan only)

```bash
cat > federated-pr.json <<EOF
{
  "name": "github-actions-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:TerraFour-ECI/arsw-terraform-azure-load-balancing:pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters federated-pr.json
```

### 4.c — `production` environment (manual apply)

```bash
cat > federated-env.json <<EOF
{
  "name": "github-actions-prod-env",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:TerraFour-ECI/arsw-terraform-azure-load-balancing:environment:production",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters federated-env.json
```

## 🔑 Step 5 — GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and create the
following **repository secrets**:

| Name                    | Value                                                            |
| :---------------------- | :--------------------------------------------------------------- |
| `AZURE_CLIENT_ID`       | `$APP_ID` from step 1                                            |
| `AZURE_TENANT_ID`       | `az account show --query tenantId -o tsv`                        |
| `AZURE_SUBSCRIPTION_ID` | `cd4ddc1a-042b-4bc4-b751-024854e4f459`                           |
| `BACKEND_RG`            | `rg-tfstate-lab8`                                                |
| `BACKEND_SA`            | `sttfstate658`                                                   |
| `BACKEND_CONTAINER`     | `tfstate`                                                        |
| `BACKEND_KEY`           | `lab8/terraform.tfstate`                                         |

## 🛡️ Step 6 — Protect the `production` environment

In **Settings → Environments → New environment → production**, enable:

* ✅ **Required reviewers** — at least one team member must approve.
* ✅ **Wait timer** (optional) — 1-5 minutes window to abort.
* ✅ **Deployment branches** — restrict to `main`.

## ✅ Verification

Trigger the workflow manually from the **Actions** tab → *Terraform
CI/CD* → *Run workflow* → choose `plan`. The job should:

1. Print `Login successful.` after `azure/login@v2`.
2. Successfully `terraform init` against the remote backend.
3. Output a valid plan, with no resources changed if the infra is
   already destroyed (or a `+ create` plan if it isn't).

If the workflow fails on `azure/login`, double-check the **subject** of
the federated credential matches the actual `repo:<owner>/<repo>:ref:...`
string GitHub emits — every typo blocks the trust handshake.
