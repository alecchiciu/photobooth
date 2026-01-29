$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYjBhZGE4Yi01ODViLTRlYmEtYmRjZS1hMjE3MDNkYjYwZWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4NzU3MDgxLCJleHAiOjE3NzM4OTI4MDB9.iYOwvT2qoKxAwLtvkcpr0Te0yk4R6AZ3liXD3UjX80U"
$workflowId = "WJIT6gkxSnEPCkKo"

$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Content-Type" = "application/json"
}

$workflow = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Get -Headers $headers

# Fix Code - Prepare Response to correctly extract QR code binary
$fixedPrepareResponseCode = @'
// Get the QR code binary data
const qrBinary = $binary;
let qrBase64 = '';

// The HTTP node returns binary in $binary.data
if (qrBinary && qrBinary.data && qrBinary.data.data) {
  qrBase64 = qrBinary.data.data;
} else if ($input.item.binary && $input.item.binary.data) {
  qrBase64 = $input.item.binary.data.data;
}

// Get signed URL data from earlier node
const signedUrlData = $('Code - Generate Signed URL').item.json;

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
        Write-Host "Fixed: Code - Prepare Response"
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
