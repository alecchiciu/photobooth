$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYjBhZGE4Yi01ODViLTRlYmEtYmRjZS1hMjE3MDNkYjYwZWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4NzU3MDgxLCJleHAiOjE3NzM4OTI4MDB9.iYOwvT2qoKxAwLtvkcpr0Te0yk4R6AZ3liXD3UjX80U"
$workflowId = "WJIT6gkxSnEPCkKo"

$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Content-Type" = "application/json"
}

$workflow = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Get -Headers $headers

# Fix Code - Prepare Response - use await this.helpers.getBinaryDataBuffer to get actual binary
$fixedPrepareResponseCode = @'
// Get the QR code binary - in n8n we need to use the binary helper
const signedUrlData = $('Code - Generate Signed URL').item.json;

// Access binary data using the proper n8n method
let qrBase64 = '';

// Try to get the binary data from the input
const binaryData = $input.item.binary;
if (binaryData && binaryData.data) {
  // Use the getBinaryDataBuffer helper to get actual data
  const buffer = await this.helpers.getBinaryDataBuffer(0, 'data');
  qrBase64 = buffer.toString('base64');
}

return {
  json: {
    success: true,
    qr_code: qrBase64 ? 'data:image/png;base64,' + qrBase64 : null,
    download_url: signedUrlData.downloadUrl,
    filter_applied: signedUrlData.filter,
    expires_in: signedUrlData.expiresIn,
    expires_at: signedUrlData.expiresAt,
    session_id: signedUrlData.session_id
  }
};
'@

foreach ($node in $workflow.nodes) {
    if ($node.name -eq "Code - Prepare Response") {
        $node.parameters.jsCode = $fixedPrepareResponseCode
        Write-Host "Fixed: Code - Prepare Response (v2 - using getBinaryDataBuffer)"
    }
}

$updatePayload = @{
    name = $workflow.name
    nodes = $workflow.nodes
    connections = $workflow.connections
    settings = $workflow.settings
}

$body = $updatePayload | ConvertTo-Json -Depth 20

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Put -Headers $headers -Body $body
    Write-Host "Workflow updated!"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
