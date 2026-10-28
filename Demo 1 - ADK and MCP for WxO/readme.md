# Demo 1 — IT Support Agent via ADK

> **This demo produces the exact same result as Lab 1**, but shows how a developer would build and deploy the same agent using code instead of the WXO graphical interface.
>
> Two approaches are shown: **ADK direct** (pre-built files) and **via BOB** (live-generated with IBM's code assistant).

---

## Lab 1 vs Demo 1 — What Is Different?

| | Lab 1 (Low-Code) | Demo 1 (ADK) |
|---|---|---|
| **Who does it** | Workshop participants | Facilitator / developer |
| **How agent is built** | WXO GUI — "Build with AI" | YAML file + CLI command |
| **How agent is deployed** | Clicking "Create" in the UI | `orchestrate agents import` |
| **Connections (Gmail, ServiceNow)** | Configured via Manage → Connections in UI | Pre-configured in WXO (same instance) |
| **End result in WXO** | `IT_Support_Incident_Creator` agent | `IT Support Agent (ADK)` agent |
| **Behavior** | Identical | Identical |

**Why show this?**  
Lab 1 demonstrates that non-developers can build agents in minutes. Demo 1 shows developers how the same thing is expressed as code — making it version-controllable, repeatable, and deployable across environments without touching the UI.

---

## Two Demo Approaches

### Approach A — ADK Direct (Pre-built Files)

Use the files already in this repo. Fastest path — best when you want to show the end result without live generation.

**Files:**
```
adk-prebuild/agents/it_support_agent.yml   ← agent definition
adk-prebuild/deploy.sh                     ← one-command deployment
adk-prebuild/creds/.env.example            ← credentials template
```

Steps: fill in `adk-prebuild/creds/.env` → run `bash adk-prebuild/deploy.sh` → done.

---

### Approach B — Via BOB (Live Generation)

Use **BOB** (IBM's code assistant) to generate the same files live in front of the audience. Best when you want to show AI-assisted development in action.

**Files:**
```
adk-bob/instructions.md   ← prompts to give BOB during the demo
```

Steps: open BOB → paste the prompts from `adk-bob/instructions.md` → BOB generates the agent YAML + deploy script → run the generated deploy script → done.

> See `adk-bob/instructions.md` for the exact prompts, demo flow, and talking points.

---

## Folder Structure

```
Demo 1 - ADK and MCP for WxO/
├── readme.md               ← you are here
├── adk-prebuild/           ← Approach A: pre-built files, deploy immediately
│   ├── deploy.sh
│   ├── agents/
│   │   └── it_support_agent.yml
│   ├── tools/              ← empty (uses pre-built WXO tools)
│   └── creds/
│       └── .env.example
└── adk-bob/                ← Approach B: prompts to generate the same via BOB
    └── instructions.md
```

---

## What This Agent Does

- Reads unread emails from a Gmail service desk inbox (`List emails in Gmail`)
- Creates incidents in ServiceNow from user input or email content (`Create an incident in ServiceNow`)

Same two tools as Lab 1. Same instructions. Same output format.

---

## Prerequisites

1. **WXO instance already set up** — same instance used in Lab 1
2. **Gmail and ServiceNow connections already configured** in WXO (done in Lab 1 Part 1)
3. **orchestrate CLI installed:**
   ```bash
   pip install ibm-watsonx-orchestrate
   ```

---

## Setup (Approach A — ADK Direct)

### 1. Fill in credentials

```bash
cp adk-prebuild/creds/.env.example adk-prebuild/creds/.env
```

Edit `adk-prebuild/creds/.env`:

```
WATSONX_ORCHESTRATE_URL=https://api.jp-tok.watson-orchestrate.cloud.ibm.com/instances/<your-instance-id>
WXO_APIKEY=<your-ibm-cloud-api-key>
```

> Get the instance ID from the WXO URL when logged in. Get the API key from IBM Cloud → Manage → Access → API keys.

### 2. Deploy

```bash
bash adk-prebuild/deploy.sh
```

The script will:
1. Authenticate to the WXO instance
2. Import `agents/it_support_agent.yml` into WXO
3. Deploy the agent so it appears in the WXO UI

> **Note:** The agent YAML references pre-built WXO tools by their internal names (`list_emails_0f321`, `create_an_incident_f6379`). These names are specific to this workshop instance. If you run this on a different WXO instance, run `orchestrate tools list -v` to find the correct names and update `agents/it_support_agent.yml` accordingly.

---

## How to Run the Demo

1. Open WXO → **Agents**
2. Find **it_support_agent_adk**
3. Click **Talk to agent**
4. Try these prompts:

```
Show me the latest 5 unread emails in my inbox
```

```
Create an incident: a user cannot connect to VPN since this morning. High priority.
```

```
I received an email from sarah.tan@company.com — her laptop won't turn on before an important client presentation. Create a ServiceNow incident for this.
```

---

## Talking Points

**For Approach A (ADK Direct):**
- Open `it_support_agent.yml` — show the instructions and tools fields. These map 1:1 to what "Build with AI" generates in the UI.
- Run `bash deploy.sh` live — the agent appears in WXO immediately.
- *"This file can be committed to Git, reviewed in a PR, and deployed to any WXO environment automatically."*

**For Approach B (via BOB):**
- *"You just built this in the UI in 10 minutes. Let me show you how BOB does it in 30 seconds."*
- Paste the context + prompts from `via-bob/instructions.md` into BOB live
- Show BOB generating the YAML and deploy script
- Run the generated files — same result
- *"BOB didn't just answer a question — it generated production-ready infrastructure code."*

---

## Troubleshooting

**`orchestrate: command not found`**  
Run `pip install ibm-watsonx-orchestrate` and restart your terminal.

**`Authentication failed` during deploy**  
Check `WATSONX_ORCHESTRATE_URL` and `WXO_APIKEY` in `creds/.env`. Make sure the API key has access to the WXO instance.

**Agent imported but tools not working**  
Gmail and ServiceNow connections must already be authorized in WXO (done in Lab 1 Part 1). The ADK import does not configure OAuth connections — those still go through the UI.

**Agent name conflicts**  
If an agent with the same name already exists, the import will update it. Safe to re-run.
