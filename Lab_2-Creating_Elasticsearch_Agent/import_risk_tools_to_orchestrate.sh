#!/bin/bash

# ============================================================
# Import risk_tools to Watsonx Orchestrate
# ============================================================
# Prerequisites:
# 1. pip install ibm-watsonx-orchestrate
# 2. Set environment variables in .env
# 3. Run from project root: bash import_risk_tools.sh
# ============================================================

set -e

echo ""
echo "============================================================"
echo "WATSONX ORCHESTRATE - IMPORT RISK TOOLS"
echo "============================================================"
echo ""

# ── Load .env ──────────────────────────────────────────────
if [ -f .env ]; then
    echo "→ Loading .env..."
    set -a; source .env; set +a
    echo "   ✅ Environment loaded"
else
    echo "❌ .env not found"; exit 1
fi

# ── Check required vars ────────────────────────────────────
echo ""
echo "→ Checking required variables..."

REQUIRED_VARS=(
    WATSONX_ORCHESTRATE_URL
    WXO_APIKEY
    WXO_ENV_NAME
    ES_HOST ES_USERNAME ES_PASSWORD
    WATSONX_URL WATSONX_APIKEY WATSONX_PROJECT_ID
)

MISSING=()
for var in "${REQUIRED_VARS[@]}"; do
    [ -z "${!var}" ] && MISSING+=("$var")
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "❌ Missing variables:"; printf '   - %s\n' "${MISSING[@]}"; exit 1
fi
echo "   ✅ All required variables set"

# ── Check CLI ──────────────────────────────────────────────
echo ""
echo "→ Checking orchestrate CLI..."
command -v orchestrate &>/dev/null || { echo "❌ orchestrate CLI not found. Run: pip install ibm-watsonx-orchestrate"; exit 1; }
echo "   ✅ CLI found"

# ── Step 1: Activate environment ───────────────────────────
echo ""
echo "============================================================"
echo "STEP 1: Activate Environment"
echo "============================================================"
echo ""

ENV_NAME="$WXO_ENV_NAME"

echo "→ Activating environment: $ENV_NAME..."
if orchestrate env activate "$ENV_NAME" --api-key "$WXO_APIKEY" 2>/dev/null; then
    echo "   ✅ Environment activated"
else
    echo "   → Not found, creating environment..."
    orchestrate env add \
        --name "$ENV_NAME" \
        --url "$WATSONX_ORCHESTRATE_URL" \
        --type ibm_iam \
        --api-key "$WXO_APIKEY" \
        --activate
    echo "   ✅ Environment created and activated"
fi

echo ""
echo "→ Verifying connection..."
orchestrate tools list > /dev/null 2>&1 && echo "   ✅ Connected" || { echo "❌ Could not connect"; exit 1; }

# ── Step 2: Import connections ─────────────────────────────
echo ""
echo "============================================================"
echo "STEP 2: Import Connections"
echo "============================================================"
echo ""

# Elasticsearch
echo "→ Importing Elasticsearch connection..."
orchestrate connections import -f connections/elasticsearch-service-desk.yaml \
    && echo "   ✅ Imported" || echo "   ⚠️  Already exists, continuing..."

echo "   → Setting credentials..."
for env in draft live; do
    orchestrate connections set-credentials -a elasticsearch-service-desk \
        --env "$env" \
        -e "ES_HOST=${ES_HOST}" \
        -e "ES_PORT=${ES_PORT:-9200}" \
        -e "ES_USERNAME=${ES_USERNAME}" \
        -e "ES_PASSWORD=${ES_PASSWORD}" \
        -e "ES_USE_SSL=${ES_USE_SSL:-true}" \
        -e "ES_VERIFY_CERTS=${ES_VERIFY_CERTS:-false}" \
        -e "ES_CERT_CONTENT=${ES_CERT_CONTENT:-}"
    echo "   ✅ ES credentials set ($env)"
done

echo ""

# WatsonX AI
echo "→ Importing WatsonX AI connection..."
orchestrate connections import -f connections/watsonx-ai-service-desk.yaml \
    && echo "   ✅ Imported" || echo "   ⚠️  Already exists, continuing..."

echo "   → Setting credentials..."
for env in draft live; do
    orchestrate connections set-credentials -a watsonx-ai-service-desk \
        --env "$env" \
        -e "WATSONX_URL=${WATSONX_URL}" \
        -e "WATSONX_APIKEY=${WATSONX_APIKEY}" \
        -e "WATSONX_PROJECT_ID=${WATSONX_PROJECT_ID}"
    echo "   ✅ WatsonX credentials set ($env)"
done

# ── Step 3: Import risk_tools ──────────────────────────────
echo ""
echo "============================================================"
echo "STEP 3: Import risk_tools"
echo "============================================================"
echo ""

TOOLS_FILE="agents/risk_tools.py"
REQS_FILE="agents/requirements_tools.txt"

[ -f "$TOOLS_FILE" ] || { echo "❌ $TOOLS_FILE not found"; exit 1; }
[ -f "$REQS_FILE"  ] || { echo "❌ $REQS_FILE not found";  exit 1; }

echo "→ Importing risk_tools from $TOOLS_FILE..."

# cd into agents/ so Python can resolve the module name cleanly
(
    cd agents
    orchestrate tools import \
        -k python \
        -f risk_tools.py \
        -r requirements_tools.txt \
        -a elasticsearch-service-desk \
        -a watsonx-ai-service-desk
)

echo "   ✅ risk_tools imported"

echo ""
echo "→ Listing imported tools..."
orchestrate tools list

# ── Done ───────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "DONE"
echo "============================================================"
echo ""
echo "  Environment : $ENV_NAME"
echo "  Connections : elasticsearch-service-desk"
echo "                watsonx-ai-service-desk"
echo "  Tools       : retrieve_risk_documents"
echo "                retrieve_resolution_notes"
echo ""
echo "============================================================"