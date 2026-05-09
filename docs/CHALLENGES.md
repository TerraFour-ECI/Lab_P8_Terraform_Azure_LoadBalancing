# 🎁 Optional Challenges — Lab #8

> The base lab fulfils the 100-pt rubric on its own. This document covers
> the two optional *Retos* that have been implemented as **opt-in modules**
> behind feature flags, so they only spin up extra resources (and extra
> cost) when explicitly enabled.

| Challenge | Module | Feature flag | Approx. extra cost |
| :--- | :--- | :--- | :--- |
| 🪜 **Azure Bastion** in `subnet-mgmt` area | [`modules/bastion`](../modules/bastion) | `enable_bastion = true` | ~USD 0.19 / hour (Basic SKU) |
| 💰 **Budget alert** with email notifications | [`modules/budget`](../modules/budget) | `enable_budget = true` | **Free** (Azure does not charge for budgets) |

---

## 🪜 Challenge #1 — Azure Bastion (no public SSH)

### 🎯 Goal

Eliminate the public 22/TCP attack surface on the workload VMs by
brokering SSH/RDP through the **Azure portal over TLS**. Operators reach
the VMs by clicking *Connect → Bastion* in the portal — there is no
public IP on the VMs and no inbound rule for port 22 from the Internet.

### 🧱 What gets created

When `enable_bastion = true`:

1. The `vnet` module adds a third subnet named **`AzureBastionSubnet`**
   (10.10.3.0/26). Azure mandates this exact name and a minimum of `/26`.
2. The new `bastion` module provisions:
   * A Standard SKU Public IP for the Bastion frontend.
   * The `azurerm_bastion_host` itself (Basic or Standard SKU).

### 🛠️ How to enable

```powershell
# 1. Copy the overlay tfvars and customise as needed
Copy-Item infra/env/dev-challenges.tfvars.example infra/env/dev-challenges.tfvars
# Make sure enable_bastion = true in that file.

# 2. Apply with BOTH var-files (base + challenges overlay)
cd infra
terraform apply `
  "-var-file=env/dev.tfvars" `
  "-var-file=env/dev-challenges.tfvars" `
  -auto-approve

# 3. Open the Azure portal -> lab8-vm-0 -> Connect -> Bastion
```

### 🔒 Production-grade follow-up

If you adopt this in production, also:

* Drop the `Allow-SSH-From-Operator` rule from the NSG entirely — Bastion
  reaches the VMs on the private subnet, no NSG rule for 22 is needed.
* Use the `Standard` SKU to enable shareable links and multi-host scaling.
* Enable Just-In-Time VM Access (Microsoft Defender for Cloud) on top of
  Bastion for time-boxed approvals.

### 💸 Cost note

Azure Bastion is the most expensive single resource in this lab. At
~**USD 0.19/hour for the Basic SKU**, an 8-hour demo costs roughly
USD 1.50 — multiplied by the Bastion's monthly bill you can blow
through your student credit fast. **Always destroy the deployment when
the demo is over** (`terraform destroy` works for the challenge layer
identically).

---

## 💰 Challenge #2 — Budget alert (Cost Management)

### 🎯 Goal

Add a **hard guardrail against runaway spend** by attaching an Azure
Cost Management budget to the lab Resource Group. Budgets do not
prevent provisioning by themselves, but they email the team early so
nobody discovers a maxed-out subscription on Monday morning.

### 🧱 What gets created

When `enable_budget = true`:

1. An `azurerm_consumption_budget_resource_group` scoped to `lab8-rg`.
2. Three notifications, all on **Actual cost** (not Forecast, to avoid
   noisy alerts in the first days of the month):
   * **50%** — early heads-up.
   * **90%** — warning before the credit is exhausted.
   * **100%** — hard alert.

Recipients are taken from `budget_contact_emails`.

### 🛠️ How to enable

```powershell
# In env/dev-challenges.tfvars set:
#   enable_budget         = true
#   budget_amount_usd     = 30
#   budget_contact_emails = ["you@example.edu", ...]
#   budget_start_date     = "2026-05-01T00:00:00Z"

cd infra
terraform apply `
  "-var-file=env/dev.tfvars" `
  "-var-file=env/dev-challenges.tfvars" `
  -auto-approve
```

### ✅ How to verify

1. Open **Azure portal → Cost Management + Billing → Budgets**.
2. The budget `lab8-monthly-budget` should appear under the lab Resource
   Group with three alert rules.
3. Trigger a synthetic notification by lowering `budget_amount_usd`
   below the current month's spend, then re-applying.

### 💸 Cost note

Budgets themselves are **free** — Azure only charges for the resources
the budget tracks, never for the budget object. Adding this challenge
is therefore a pure-upside ergonomics win.

---

## 🧪 Combined apply (both challenges at once)

```powershell
cd infra
terraform init "-backend-config=backend.hcl"
terraform apply `
  "-var-file=env/dev.tfvars" `
  "-var-file=env/dev-challenges.tfvars" `
  -auto-approve

# Outputs gain two extra fields:
#   bastion_dns_name = "bst-xxxxxxxx.bastion.azure.com"
#   budget_name      = "lab8-monthly-budget"

# Tear everything down (base + challenges) when done:
terraform destroy `
  "-var-file=env/dev.tfvars" `
  "-var-file=env/dev-challenges.tfvars" `
  -auto-approve
```

> 💡 Apply with only `env/dev.tfvars` and the optional modules quietly
> stay at `count = 0`, so the base flow keeps the same plan diff it had
> before the challenges existed.
