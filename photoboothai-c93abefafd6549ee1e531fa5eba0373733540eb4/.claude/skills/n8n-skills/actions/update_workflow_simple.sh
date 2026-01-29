#!/bin/bash

# n8n API Configuration
API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2ZjRiYzBlNC02MzFlLTQ5MjctOTNmNi1hMjQ4NGQ5MGFkMjgiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4ODU0Nzg4LCJleHAiOjE3NzY1NDYwMDB9.i8GTUi_Ki2UAWtXY2AV52KamEnwnDgvIAS24QkcR0D8"
N8N_HOST="https://petriclucas.app.n8n.cloud"
WORKFLOW_ID="IE54SxYrHylbHmNhrrJ3_"

echo "Reading updated workflow from local file..."
# Read the updated workflow JSON file that we already edited
WORKFLOW_DATA=$(cat photobooth_workflow.json)

# Extract fields and filter settings to remove problematic properties
UPDATED_WORKFLOW=$(echo "$WORKFLOW_DATA" | jq '{
  name: .name,
  nodes: .nodes,
  connections: .connections,
  settings: {
    executionOrder: .settings.executionOrder
  },
  staticData: .staticData
}')

echo "Deploying updated workflow..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  "${N8N_HOST}/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$UPDATED_WORKFLOW")

# Split response and HTTP code
HTTP_BODY=$(echo "$RESPONSE" | head -n -1)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Workflow updated successfully!"
    echo ""
    echo "The Code - Prepare Response node has been updated to include the preview_image field."
    echo "The webapp has also been updated to display the preview image alongside the QR code."
else
    echo "✗ Workflow update failed with status $HTTP_CODE"
fi
