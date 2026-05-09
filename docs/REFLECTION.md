# Technical Reflection — Lab #8

> **Course:** Software Architecture (ARSW) · **Lab:** #8 — Terraform Azure
> Load Balancing · **Team:** Andersson Sánchez, Cristian Pedraza, Elizabeth
> Correa, Juan Sebastián Ortega.

---

## 1. Why a Layer-4 Load Balancer instead of Application Gateway (L7)?

We deliberately chose **Azure Load Balancer (Standard SKU)** for this lab
because the use case is *plain TCP/HTTP traffic to identical backends*. A
Layer-7 device (Application Gateway, Front Door) would buy us
features—path-based routing, SSL offloading, WAF, header rewrites,
session affinity—that **the workload simply does not consume**.

| Dimension          | Azure LB (L4)                | Application Gateway (L7)        |
| :----------------- | :--------------------------- | :------------------------------ |
| Routing            | 5-tuple hash, port-only      | URL paths, hostnames, headers   |
| TLS termination    | ❌ (passthrough)             | ✅                              |
| WAF                | ❌                           | ✅ (OWASP ruleset)              |
| Latency overhead   | ~sub-ms                      | ~few ms                         |
| Cost (24h)         | ~USD 0.60                    | ~USD 4–6                        |
| Operational model  | Stateless, easy IaC          | More moving parts (listeners…)  |

L4 keeps **latency and cost minimal**, and matches the IaC theme of the
lab: every concept maps 1:1 to a Terraform resource. The day we need
SSL/HTTP routing we would **swap the `lb` module for an `agw` module**
without touching `compute` or `vnet`—the whole point of separating
modules.

## 2. Security implications of exposing port 22 and how we mitigated them

SSH on the public Internet is permanently scanned by botnets; an open
22/TCP with default settings is a brute-force magnet that floods auth
logs and consumes CPU. Our mitigations:

1. **NSG IP allow-list.** The rule `Allow-SSH-From-Operator` only permits
   our operator IP `186.154.34.223/32`. Any other source is dropped at
   the NIC, before nginx or sshd ever see the packet.
2. **Key-only authentication.** `azurerm_linux_virtual_machine` is
   created with `disable_password_authentication = true` (the default in
   `azurerm` v4 when an `admin_ssh_key` is provided), so password spray
   is structurally impossible.
3. **Least-privilege NSG.** The only inbound rules are 80/TCP from
   anywhere and 22/TCP from our /32. Everything else falls under the
   default deny.
4. **Tagged ephemeral resources.** All VMs carry `expires=2026-12-31`,
   making cost cleanup auditable.

For a production posture we would **remove 22/TCP entirely from the
public surface** by deploying **Azure Bastion** in `subnet-mgmt` (already
provisioned). Bastion brokers SSH over TLS through the Azure portal,
removing the public IP requirement on the VMs.

## 3. Approximate cost breakdown (East US, pay-as-you-go list price)

| Resource                       | Hourly       | Daily      | Monthly   |
| :----------------------------- | -----------: | ---------: | --------: |
| 2 × VM `Standard_B1s`          | ~USD 0.0104  | ~USD 0.50  | ~USD 15.2 |
| Standard Load Balancer         | ~USD 0.025   | ~USD 0.60  | ~USD 18.3 |
| Standard Public IP (static)    | ~USD 0.005   | ~USD 0.12  | ~USD 3.7  |
| Storage Account (state, LRS)   | ~USD 0.0002  | ~USD 0.005 | ~USD 0.15 |
| **Total**                      | **~USD 0.041** | **~USD 1.23** | **~USD 37** |

For an 8-hour development session the deployment costs ~**USD 0.33**, so
the **USD 100 Azure for Students** credit comfortably covers dozens of
full lab cycles. Egress traffic for the lab is negligible (a handful of
`curl` requests).

## 4. What would we change for production?

| Lever            | Why                                                              |
| :--------------- | :--------------------------------------------------------------- |
| **VM Scale Set** | Replace `count = 2` with autoscaling 2→N on CPU/HTTP queue.      |
| **Availability Zones** | Spread VMs across `zones = [1,2,3]` to survive AZ outages. |
| **Azure Bastion** | Eliminate public 22/TCP — SSH only via TLS broker.              |
| **App Gateway + WAF** | Add OWASP rule set, end-to-end TLS, path routing.            |
| **Azure Monitor + alerts** | Page on-call when health probe fails > 1m.              |
| **Budget alerts** | Hard guardrail to avoid surprise bills.                         |
| **Private state + RBAC** | Lock down state Storage Account with private endpoint.   |
| **Module versioning** | Publish `vnet`/`compute`/`lb` to a private registry with SemVer. |

---

## 5. Trade-offs accepted in the lab scope

* **Single region, single subscription.** We did not implement geo-DR or
  cross-tenant federation — out of scope for a 2-3 hour lab.
* **Mutable `latest` Ubuntu image.** Production should pin an image
  version to keep `terraform plan` idempotent across rebuilds.
* **NSG attached to NICs**, not to the subnet — easier per-tier
  hardening at the cost of duplicated rules if we add more tiers.
* **`vm_count` capped at 5** by a `validation` block — explicitly to
  avoid runaway spend during the lab.

## 6. Cleanup procedure

```powershell
cd infra
terraform destroy "-var-file=env/dev.tfvars" -auto-approve
```

The destroy is also exposed as a `workflow_dispatch` action in
`.github/workflows/terraform.yml` (`action=destroy`) so an authorised
team member can tear the lab down from the GitHub UI without local
credentials.
