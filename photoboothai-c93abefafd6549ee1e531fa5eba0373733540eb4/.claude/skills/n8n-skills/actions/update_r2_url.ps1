$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYjBhZGE4Yi01ODViLTRlYmEtYmRjZS1hMjE3MDNkYjYwZWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4NzU3MDgxLCJleHAiOjE3NzM4OTI4MDB9.iYOwvT2qoKxAwLtvkcpr0Te0yk4R6AZ3liXD3UjX80U"
$workflowId = "WJIT6gkxSnEPCkKo"

$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Content-Type" = "application/json"
}

$workflow = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Get -Headers $headers

# Fix Code - Generate Signed URL with the actual R2 public URL
$fixedSignedUrlCode = @'
const prevData = $('Code - Map Filter to Prompt').item.json;

const filename = prevData.filename;
const expiresIn = 1200;

// R2 public bucket URL
const downloadUrl = 'https://pub-81c17259d0024b8f8f925552b562c490.r2.dev/' + filename;

return {
  json: {
    downloadUrl: downloadUrl,
    filename: filename,
    uuid: prevData.uuid,
    filter: prevData.filter,
    expiresIn: expiresIn,
    expiresAt: new Date(Date.now() + expiresIn * 1000).toISOString(),
    timestamp: prevData.timestamp,
    session_id: prevData.session_id
  }
};
'@

foreach ($node in $workflow.nodes) {
    if ($node.name -eq "Code - Generate Signed URL") {
        $node.parameters.jsCode = $fixedSignedUrlCode
        Write-Host "Updated R2 URL to: https://pub-81c17259d0024b8f8f925552b562c490.r2.dev/"
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
