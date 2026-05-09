# Architecture Diagrams — Lab #8

> All diagrams are written in **Mermaid** (advanced syntax with classes,
> subgraphs and notes) so they render natively on GitHub and in any modern
> markdown viewer without extra tooling.

---

## 1. Component Diagram

The component diagram shows the **infrastructure layout deployed by
Terraform** in Azure: developer toolchain, CI/CD federation with Azure AD,
remote state storage and the actual workload (VNet + Load Balancer + VMs +
NSG).

```mermaid
%%{init: {
  "theme": "base",
  "themeVariables": {
    "primaryColor": "#E8F1FA",
    "primaryBorderColor": "#0078D4",
    "primaryTextColor": "#1B1B1B",
    "lineColor": "#0078D4",
    "fontFamily": "Segoe UI, sans-serif"
  },
  "flowchart": { "htmlLabels": true, "curve": "basis" }
}}%%
flowchart LR
    %% ─────────────────────────── External actors ───────────────────────────
    Dev(["👩‍💻 Developer<br/><i>terraform CLI</i>"]):::actor
    User(["🌐 End user<br/><i>HTTP client</i>"]):::actor
    GitHub(["🐙 GitHub<br/><i>repo + Actions</i>"]):::actor

    %% ─────────────────────────── Identity layer ────────────────────────────
    subgraph AAD["☁️ Azure Active Directory"]
        direction TB
        OIDC{{"🔐 OIDC<br/>Federated Credential"}}:::identity
        SP["🪪 Service Principal<br/>lab8-github-actions"]:::identity
        Role[["📜 Role: Contributor<br/>(scope: subscription)"]]:::identity
    end

    %% ─────────────────────────── Backend / state ───────────────────────────
    subgraph Backend["🗄️ Remote State (Azure Storage)"]
        direction TB
        SA[("📦 sttfstate658<br/>Storage Account")]:::storage
        Container[("🪣 tfstate<br/>blob container")]:::storage
        Lease["🔒 Blob lease<br/>(state lock)"]:::storage
    end

    %% ─────────────────────────── Workload ──────────────────────────────────
    subgraph RG["🧱 Resource Group: lab8-rg (eastus)"]
        direction TB

        subgraph VNet["🌐 VNet lab8-vnet · 10.10.0.0/16"]
            direction TB
            subgraph Web["🖧 subnet-web · 10.10.1.0/24"]
                NIC0["🔌 lab8-nic-0"]:::nic
                NIC1["🔌 lab8-nic-1"]:::nic
                VM0["🖥️ lab8-vm-0<br/><i>nginx · Ubuntu 22.04</i>"]:::vm
                VM1["🖥️ lab8-vm-1<br/><i>nginx · Ubuntu 22.04</i>"]:::vm
                NIC0 --- VM0
                NIC1 --- VM1
            end
            subgraph Mgmt["🛠️ subnet-mgmt · 10.10.2.0/24"]
                Bastion["🪜 (reserved)<br/>future Azure Bastion"]:::reserved
            end
        end

        subgraph Edge["🚦 Edge"]
            direction TB
            PIP{{"📡 lab8-lb-pip<br/>Public IP · Standard"}}:::edge
            LB["⚖️ lab8-lb<br/>Standard SKU"]:::edge
            Probe["💓 health-probe<br/>TCP/80"]:::edge
            Pool["🎯 lab8-bepool<br/>backend pool"]:::edge
        end

        NSG["🛡️ lab8-web-nsg<br/>80/TCP from *<br/>22/TCP from /32"]:::nsg
    end

    %% ─────────────────────────── Edges ─────────────────────────────────────
    Dev -- "az login + terraform apply" --> Backend
    Dev -- "writes" --> RG

    GitHub == "trusts" ==> OIDC
    OIDC --> SP
    SP --> Role
    Role -- "manages" --> RG
    GitHub == "azure/login@v2 (OIDC)" ==> AAD

    SA --> Container --> Lease

    User == "HTTP :80" ==> PIP
    PIP --> LB --> Pool
    Pool -. balances .-> NIC0
    Pool -. balances .-> NIC1
    Probe -. monitors .-> NIC0
    Probe -. monitors .-> NIC1

    NSG -. attached to .-> NIC0
    NSG -. attached to .-> NIC1
    Dev -- "SSH :22 (only /32)" --> NSG

    %% ─────────────────────────── Style classes ─────────────────────────────
    classDef actor    fill:#FFF4CE,stroke:#A36500,color:#1B1B1B,stroke-width:1.4px;
    classDef identity fill:#FCE4EC,stroke:#AD1457,color:#1B1B1B;
    classDef storage  fill:#E8F5E9,stroke:#1B5E20,color:#1B1B1B;
    classDef vm       fill:#E3F2FD,stroke:#0D47A1,color:#1B1B1B,stroke-width:1.4px;
    classDef nic      fill:#FFFFFF,stroke:#0D47A1,color:#1B1B1B,stroke-dasharray:3 3;
    classDef edge     fill:#EDE7F6,stroke:#311B92,color:#1B1B1B,stroke-width:1.4px;
    classDef nsg      fill:#FFEBEE,stroke:#B71C1C,color:#1B1B1B;
    classDef reserved fill:#F5F5F5,stroke:#9E9E9E,color:#616161,stroke-dasharray:2 2;
```

### Component legend

| Color | Layer                 | Notes                                                    |
| :---- | :-------------------- | :------------------------------------------------------- |
| 🟦    | Compute (VMs / NICs)  | 2 × `Standard_B1s` Ubuntu, bootstrapped by cloud-init.   |
| 🟪    | Edge (LB / PIP)       | Standard SKU, single Public frontend, HTTP rule 80→80.   |
| 🟥    | NSG                   | Allow 80/TCP from any, 22/TCP from operator /32 only.    |
| 🟩    | Remote state          | Azure Storage Account + container + blob lease lock.     |
| 🟨    | Actors                | Developer CLI, end user and GitHub Actions runner.       |
| 🟫    | Identity              | OIDC federation between GitHub and Azure AD.             |

---

## 2. Sequence Diagram — End-user HTTP request

This sequence shows what happens when a client visits
`http://<lb_public_ip>` and the LB round-robins between the two backend
VMs.

```mermaid
%%{init: {
  "theme": "base",
  "themeVariables": {
    "actorBkg": "#0078D4",
    "actorTextColor": "#FFFFFF",
    "actorBorder": "#003E73",
    "signalColor": "#0078D4",
    "signalTextColor": "#1B1B1B",
    "labelBoxBkgColor": "#EDE7F6",
    "labelBoxBorderColor": "#311B92",
    "noteBkgColor": "#FFF4CE",
    "noteBorderColor": "#A36500"
  }
}}%%
sequenceDiagram
    autonumber
    actor User as 🌐 Client (browser/curl)
    participant DNS as 🧭 DNS resolver
    participant PIP as 📡 lab8-lb-pip<br/>(Public IP)
    participant LB  as ⚖️ lab8-lb<br/>(Standard LB)
    participant NSG as 🛡️ lab8-web-nsg
    participant VM0 as 🖥️ lab8-vm-0<br/>(nginx)
    participant VM1 as 🖥️ lab8-vm-1<br/>(nginx)

    Note over User,LB: 🔵 Phase 1 — Address resolution
    User  ->>+ DNS: Resolve hostname/IP
    DNS  -->>- User: Returns 104.211.49.157

    Note over User,LB: 🔵 Phase 2 — TCP / HTTP request
    User  ->>+ PIP: TCP SYN :80
    PIP   ->>+ LB:  Forward connection

    Note right of LB: 5-tuple hash<br/>chooses backend VM<br/>(round-robin in practice)

    alt Hash routes to VM0
        LB ->>+ NSG: Inbound 80/TCP allowed
        NSG ->>+ VM0: Deliver to nginx
        VM0 -->>- NSG: 200 OK · "Hello from lab8-vm-0"
        NSG -->>- LB: HTTP response
    else Hash routes to VM1
        LB ->>+ NSG: Inbound 80/TCP allowed
        NSG ->>+ VM1: Deliver to nginx
        VM1 -->>- NSG: 200 OK · "Hello from lab8-vm-1"
        NSG -->>- LB: HTTP response
    end

    LB  -->>- PIP: Response
    PIP -->>- User: 200 OK + body

    Note over LB,VM1: 🟢 Continuous health probing
    loop every 5s
        LB ->>+ VM0: TCP probe :80
        VM0 -->>- LB: probe ack
        LB ->>+ VM1: TCP probe :80
        VM1 -->>- LB: probe ack
    end
```

### Notes on the sequence

* **Step 3-4 (TCP SYN)** is what the Standard LB intercepts on the
  configured frontend port. The probe state determines which backend
  pool members are eligible.
* **Round-robin behaviour**: Azure LB uses a *5-tuple hash*
  `(src IP, src port, dst IP, dst port, protocol)`; for `curl` runs from
  the same machine, the source port changes between connections, which is
  why successive requests rotate through both VMs.
* **NSG enforcement** happens *after* the LB chose a backend — the same
  NSG is bound to every NIC, so flows mirror the backend pool exactly.
* **Health probe loop** runs independently of user traffic; if a VM stops
  responding to the probe it is taken out of the pool transparently.

---

## 3. Sequence Diagram — CI/CD with OIDC

```mermaid
%%{init: {
  "theme": "base",
  "themeVariables": {
    "actorBkg": "#311B92",
    "actorTextColor": "#FFFFFF",
    "actorBorder": "#1B0066",
    "signalColor": "#311B92"
  }
}}%%
sequenceDiagram
    autonumber
    actor Eng as 👩‍💻 Engineer
    participant GH  as 🐙 GitHub Actions runner
    participant AAD as 🔐 Azure AD (OIDC)
    participant ARM as ☁️ Azure Resource Manager
    participant SA  as 🗄️ Storage Account (state)
    participant RG  as 🧱 lab8-rg

    Eng  ->> GH:  Open PR / dispatch workflow
    GH   ->> AAD: Exchange OIDC JWT for access token
    AAD -->> GH:  Bearer token (≤1h)
    GH   ->> SA:  Acquire blob lease<br/>(state lock)
    SA  -->> GH:  Lease acquired
    GH   ->> ARM: terraform plan / apply
    ARM  ->> RG:  Create/Update/Delete resources
    RG  -->> ARM: Status
    ARM -->> GH:  Plan diff / apply summary
    GH   ->> SA:  Persist new state<br/>+ release lease
    GH  -->> Eng: PR comment with plan or job summary
```

This second sequence highlights how no long-lived secret is stored: the
GitHub job mints a short-lived OIDC JWT, swaps it for an Azure AD access
token, and uses it to talk to ARM and to the state Storage Account.

---

## How to render

* **GitHub** renders Mermaid blocks natively — just open this file on the
  web UI.
* **VS Code**: install the *Markdown Preview Mermaid Support* extension.
* **Standalone export**: paste any block into <https://mermaid.live> and
  export PNG/SVG.
