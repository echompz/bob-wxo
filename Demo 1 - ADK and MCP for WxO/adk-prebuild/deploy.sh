#!/bin/bash
# ============================================================
# Demo 1 — Deploy IT Support Agent via ADK
# Includes: Elasticsearch MCP toolkit + IT Support Agent
# ============================================================
# Prerequisites:
#   pip install ibm-watsonx-orchestrate
#   cp creds/.env.example creds/.env  →  fill in your values
# ============================================================

set -e

# Always run from the directory where this script lives
cd "$(dirname "$0")"

echo ""
echo "============================================================"
echo "DEMO 1 — IT Support Agent (ADK Deployment)"
echo "============================================================"
echo ""

# Load credentials
if [ -f creds/.env ]; then
    set -a
    source creds/.env
    set +a
    echo "✅ Credentials loaded from creds/.env"
else
    echo "❌ creds/.env not found — copy creds/.env.example and fill in your values"
    exit 1
fi

# Activate venv if orchestrate not already in PATH
if ! command -v orchestrate &> /dev/null; then
    if [ -f venv/bin/activate ]; then
        source venv/bin/activate
        echo "✅ venv activated"
    fi
fi

# Final check
if ! command -v orchestrate &> /dev/null; then
    echo "❌ orchestrate CLI not found — run: pip install ibm-watsonx-orchestrate"
    exit 1
fi
echo "✅ orchestrate CLI found"

# ── Step 1: Activate environment ────────────────────────────
echo ""
echo "Step 1 — Activating WXO environment..."
orchestrate env add \
    --name demo1 \
    --url "$WATSONX_ORCHESTRATE_URL" \
    --type ibm_iam \
    --activate 2>/dev/null || true

orchestrate env activate demo1 --api-key "$WXO_APIKEY"
echo "✅ Environment activated"

# ── Step 2: Import Elasticsearch MCP toolkit ─────────────────
echo ""
echo "Step 2 — Importing Elasticsearch MCP toolkit..."
orchestrate toolkits remove --name elasticsearch_mcp 2>/dev/null || true
orchestrate toolkits import -f toolkits/elasticsearch_mcp.yaml
echo "✅ Elasticsearch MCP toolkit imported"

# ── Step 3: Import agent ─────────────────────────────────────
echo ""
echo "Step 3 — Importing IT Support Agent..."
orchestrate agents import -f agents/it_support_agent.yml
echo "✅ Agent imported"

# ── Step 4: Deploy agent ──────────────────────────────────────
echo ""
echo "Step 4 — Deploying IT Support Agent..."
orchestrate agents deploy --name it_support_agent_adk
echo "✅ Agent deployed"

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "DEPLOYMENT COMPLETE"
echo "============================================================"
echo ""
echo "Open WXO → Agents → find 'it_support_agent_adk'"
echo "Click 'Talk to agent' and try:"
echo ""
echo "  Email & Incident:"
echo "  → Show me the latest 5 unread emails in my inbox"
echo "  → Create an incident: VPN not connecting, high priority"
echo ""
echo "  Knowledge Base (Elasticsearch MCP):"
echo "  → List all available Elasticsearch indices"
echo "  → Search the knowledge base for network connectivity issues"
echo "  → Search for high-risk entries in the risk_mapping_hybrid_index"
echo ""
