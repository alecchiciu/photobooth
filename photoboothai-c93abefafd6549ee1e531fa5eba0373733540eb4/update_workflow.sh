#!/bin/bash

# n8n API Configuration
API_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2ZjRiYzBlNC02MzFlLTQ5MjctOTNmNi1hMjQ4NGQ5MGFkMjgiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4ODU0Nzg4LCJleHAiOjE3NzY1NDYwMDB9.i8GTUi_Ki2UAWtXY2AV52KamEnwnDgvIAS24QkcR0D8"
N8N_HOST="https://petriclucas.app.n8n.cloud"
WORKFLOW_ID="IE54SxYrHylbHmNhrrJ3_"

echo "Fetching current workflow..."
WORKFLOW_JSON=$(curl -s -X GET \
  "${N8N_HOST}/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${API_KEY}" \
  -H "Content-Type: application/json")

echo "Updating Code - Prepare Response node..."

# Updated jsCode for the Code - Prepare Response node
NEW_CODE='const signedUrlData = $('\''Code - Generate Signed URL'\'').item.json;
const extractedImageData = $('\''Code - Extract Generated Image'\'').item.json;

let qrBase64 = '\'''\'';
const binaryData = $input.item.binary;
if (binaryData && binaryData.data) {
  const buffer = await this.helpers.getBinaryDataBuffer(0, '\''data'\'');
  qrBase64 = buffer.toString('\''base64'\'');
}

return {
  json: {
    success: true,
    qr_code: qrBase64 ? '\''data:image/png;base64,'\'' + qrBase64 : null,
    preview_image: '\''data:image/png;base64,'\'' + extractedImageData.imageBase64,
    download_url: signedUrlData.downloadUrl,
    filter_applied: signedUrlData.filter,
    expires_in: signedUrlData.expiresIn,
    expires_at: signedUrlData.expiresAt,
    session_id: signedUrlData.session_id
  }
};'

# Use jq to update the workflow JSON and extract only allowed fields
UPDATED_WORKFLOW=$(echo "$WORKFLOW_JSON" | jq --arg newcode "$NEW_CODE" '
  (.nodes[] | select(.name == "Code - Prepare Response") | .parameters.jsCode) = $newcode |
  {
    name: .name,
    nodes: .nodes,
    connections: .connections,
    settings: .settings,
    staticData: .staticData,
    tags: .tags,
    pinData: .pinData
  }
')

echo "Deploying updated workflow..."
RESPONSE=$(curl -s -X PUT \
  "${N8N_HOST}/api/v1/workflows/${WORKFLOW_ID}" \
  -H "X-N8N-API-KEY: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$UPDATED_WORKFLOW")

echo "Response:"
echo "$RESPONSE" | jq '.'

if echo "$RESPONSE" | jq -e '.id' > /dev/null 2>&1; then
    echo "✓ Workflow updated successfully!"
else
    echo "✗ Workflow update failed!"
fi
