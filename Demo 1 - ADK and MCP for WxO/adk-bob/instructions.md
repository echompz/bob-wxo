# Demo 1 — Build the IT Support Agent Using BOB

> These are the instructions you give to **BOB** (IBM's code assistant) during the live demo.
> BOB will generate the same files that are in the `agents/`, `toolkits/`, and `creds/` folders — live, in front of the audience.

---

## Context (Tell BOB This First)

```
I am building a demo for an IBM watsonx Orchestrate workshop.

I need you to create an IT Support Agent that:
- Reads unread emails from a Gmail service desk inbox
- Creates incidents in ServiceNow based on the email content
- Searches an Elasticsearch knowledge base for solutions and similar issues

The agent will be deployed to IBM watsonx Orchestrate using the ADK (orchestrate CLI).
It will use:
  - Two pre-built WXO tools: "List emails in Gmail" and "Create an incident in ServiceNow"
  - Five Elasticsearch MCP tools from an MCP toolkit called "elasticsearch_mcp":
      elasticsearch_mcp:list_indices
      elasticsearch_mcp:search
      elasticsearch_mcp:esql
      elasticsearch_mcp:get_mappings
      elasticsearch_mcp:get_shards

The agent YAML must include:
  - spec_version: v1
  - kind: native
  - name: it_support_agent_adk
  - llm: groq/openai/gpt-oss-120b

The MCP toolkit YAML connects to the Elasticsearch MCP server at:
  http://52.118.190.184:8443/mcp  (streamable_http transport)

The deploy script activates the WXO environment, imports the MCP toolkit first,
then imports and deploys the agent.

Credentials are stored in creds/.env with variables WATSONX_ORCHESTRATE_URL and WXO_APIKEY.
The service desk Gmail inbox is: watsonxincubation2@gmail.com
The default Elasticsearch index is: risk_mapping_hybrid_index
```

---

## Prompt 1 — Generate the MCP Toolkit YAML

```
Create a watsonx Orchestrate MCP toolkit YAML file for Elasticsearch.

Requirements:
- spec_version: v1
- kind: mcp
- name: elasticsearch_mcp
- transport: streamable_http
- url: http://52.118.190.184:8443/mcp
- tools: list_indices, get_mappings, search, esql, get_shards

Add a description explaining it connects to elastic/mcp-server-elasticsearch
running on a workshop VM.

Save as: toolkits/elasticsearch_mcp.yaml
```

---

## Prompt 2 — Generate the Agent YAML

```
Create a watsonx Orchestrate agent YAML file for an IT Support Agent.

Requirements:
- spec_version: v1
- kind: native
- name: it_support_agent_adk
- llm: groq/openai/gpt-oss-120b
- tools:
    - list_emails_0f321
    - create_an_incident_f6379
    - elasticsearch_mcp:list_indices
    - elasticsearch_mcp:search
    - elasticsearch_mcp:esql
    - elasticsearch_mcp:get_mappings
    - elasticsearch_mcp:get_shards

Instructions for the agent:
- When user asks to see emails, call List emails in Gmail
- When user asks to create an incident, extract short_description, description,
  caller_email, urgency (1-4), and category (Hardware/Software/Network/Access/Security/Other)
- Urgency mapping: Critical/system down=1, Major/multiple users=2, Partial/workaround=3, Minor=4
- When user asks to search for solutions or similar issues, use elasticsearch_mcp:search
  with the default index: risk_mapping_hybrid_index
- When user asks to list indices or explore the knowledge base, use elasticsearch_mcp:list_indices
- Always confirm actions taken and show the incident number if one was created
- Never return raw JSON — always summarize in plain language

Output format when creating an incident:
📧 EMAIL ANALYSIS → show extracted fields → ✅ INCIDENT CREATED with ticket number

Output format for knowledge base search:
Search Results → total hits → top results with key fields summarized

welcome_content:
  welcome_message: "Hi! I'm your IT Support Agent — emails, incidents, and knowledge base search."
  description: Accuracy of generated answers may vary. Please double-check responses.
  is_default_message: false

starter_prompts (4 prompts):
1. Show me the latest 5 unread emails in the service desk inbox with the detail information
2. Create an incident: a user cannot connect to VPN. High priority.
3. I received an email about a laptop not turning on. Create a ServiceNow incident.
4. Search the knowledge base for network connectivity issues and show the top results
```

---

## Prompt 3 — Generate the Deploy Script

```
Create a bash deploy script (deploy.sh) with these exact requirements:

1. Start with: set -e
2. Immediately cd to the script's own directory: cd "$(dirname "$0")"
   (This ensures relative paths like creds/.env and toolkits/ always work,
   regardless of where the user runs the script from.)

3. Load credentials from creds/.env using set -a / source / set +a

4. Auto-activate venv — orchestrate may not be in PATH:
   if ! command -v orchestrate; then
     if [ -f venv/bin/activate ]; then source venv/bin/activate; fi
   fi
   Then check again and exit with install instructions if still not found.

5. Activate WXO environment:
   orchestrate env add --name demo1 --url "$WATSONX_ORCHESTRATE_URL" --type ibm_iam --activate 2>/dev/null || true
   orchestrate env activate demo1 --api-key "$WXO_APIKEY"

6. Import Elasticsearch MCP toolkit — MUST remove first if it already exists,
   otherwise the import fails with an error:
   orchestrate toolkits remove --name elasticsearch_mcp 2>/dev/null || true
   orchestrate toolkits import -f toolkits/elasticsearch_mcp.yaml

7. Import agent (this auto-updates if it already exists):
   orchestrate agents import -f agents/it_support_agent.yml

8. Deploy agent:
   orchestrate agents deploy --name it_support_agent_adk

9. Print success message with example prompts for both email/incident AND knowledge base search.

The script must be fully idempotent — safe to run multiple times in a row.
```

---

## Prompt 4 — Generate the Credentials Template

```
Create a .env.example file for creds/ folder with two variables:
- WATSONX_ORCHESTRATE_URL (example: https://api.jp-tok.watson-orchestrate.cloud.ibm.com/instances/your-instance-id)
- WXO_APIKEY

Add a comment explaining where to get each value.
```

---

## Known Gotchas (Learned from Testing — Give These to BOB if It Gets Stuck)

| Problem | Fix |
|---|---|
| `orchestrate: command not found` | Script must auto-activate `venv/bin/activate` before checking again |
| `Existing MCP toolkit found. Failed to create.` | Run `orchestrate toolkits remove --name elasticsearch_mcp` before import |
| `422: welcome_message at most 100 characters` | Keep welcome_message under 100 chars — count carefully |
| `Both url and transport must be provided together` | Toolkit YAML field is `url:` not `server_url:` |
| Toolkit import fails on re-run | Always `remove` before `import` — there is no upsert for toolkits |
| Agent import on re-run | Agent import is safe — it auto-updates existing agents |

---

## Before Running the Demo — Pre-Flight Check

> **Facilitator only.** Verify the Elasticsearch MCP server is running and tool names are correct for this WXO instance.

```bash
# 1. Verify the MCP server is live
curl http://52.118.190.184:8443/

# 2. Install CLI and activate environment
pip install ibm-watsonx-orchestrate
orchestrate env add --name demo1 --url $WATSONX_ORCHESTRATE_URL --type ibm_iam --activate
orchestrate env activate demo1 --api-key $WXO_APIKEY

# 3. Import the MCP toolkit and verify tool names
orchestrate toolkits import -f toolkits/elasticsearch_mcp.yaml
orchestrate tools list -v | grep elasticsearch_mcp

# 4. Check WXO tool names for Gmail and ServiceNow
orchestrate tools list -v | grep -E '"(name|display_name)"' | grep -i -E "gmail|incident"
```

For this workshop instance the confirmed tool names are:
- Gmail tool: `list_emails_0f321`
- ServiceNow tool: `create_an_incident_f6379`
- Elasticsearch MCP tools: `elasticsearch_mcp:list_indices`, `elasticsearch_mcp:search`, `elasticsearch_mcp:esql`, `elasticsearch_mcp:get_mappings`, `elasticsearch_mcp:get_shards`

---

## What BOB Generates vs What Already Exists

| File | Already in repo | What BOB generates |
|---|---|---|
| `toolkits/elasticsearch_mcp.yaml` | ✅ Reference version | ✅ Live-generated version |
| `agents/it_support_agent.yml` | ✅ Reference version | ✅ Live-generated version |
| `deploy.sh` | ✅ Reference version | ✅ Live-generated version |
| `creds/.env.example` | ✅ Reference version | ✅ Live-generated version |

> During the demo, BOB's output may differ slightly from the reference files — that is okay and expected. The key point is that BOB understands the intent and generates deployable code in seconds.

---

## Demo Flow (Talking Points)

1. **Open BOB** in your IDE or browser
2. Give BOB the context block above
3. Send Prompt 1 → show the MCP toolkit YAML BOB generates
4. Send Prompt 2 → show the agent YAML with all 7 tools (2 WXO + 5 MCP)
5. Send Prompt 3 → show the deploy script
6. Save the files BOB generated, then run `bash deploy.sh`
7. Open WXO → Agents → show the agent appeared automatically
8. Test email: `Show me the latest 5 unread emails in my inbox`
9. Test MCP: `Search the knowledge base for network connectivity issues`

**Key message:**
*"BOB didn't just answer a question — it generated production-ready infrastructure code that we deployed in one command.
And notice: this agent uses both native WXO tools AND an external MCP server running on a VM.
BOB understood the full architecture and wired it all together in 30 seconds."*
