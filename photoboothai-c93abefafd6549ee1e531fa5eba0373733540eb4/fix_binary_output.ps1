$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYjBhZGE4Yi01ODViLTRlYmEtYmRjZS1hMjE3MDNkYjYwZWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4NzU3MDgxLCJleHAiOjE3NzM4OTI4MDB9.iYOwvT2qoKxAwLtvkcpr0Te0yk4R6AZ3liXD3UjX80U"
$workflowId = "WJIT6gkxSnEPCkKo"

$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Content-Type" = "application/json"
}

$workflow = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Get -Headers $headers

# Fix Code - Extract Generated Image to output binary data for S3 upload
$fixedExtractCode = @'
const openaiResponse = $json;
let generatedImageB64;

if (openaiResponse.data && openaiResponse.data[0]) {
  generatedImageB64 = openaiResponse.data[0].b64_json || openaiResponse.data[0].url;
} else {
  throw new Error('Unexpected OpenAI response format');
}

const prevData = $('Code - Map Filter to Prompt').item.json;

// Return both JSON metadata and binary data for S3 upload
return {
  json: {
    imageBase64: generatedImageB64,
    filename: prevData.filename,
    uuid: prevData.uuid,
    filter: prevData.filter,
    timestamp: prevData.timestamp,
    session_id: prevData.session_id
  },
  binary: {
    data: {
      data: generatedImageB64,
      mimeType: 'image/png',
      fileName: prevData.filename
    }
  }
};
'@

# Update the node
foreach ($node in $workflow.nodes) {
    if ($node.name -eq "Code - Extract Generated Image") {
        $node.parameters.jsCode = $fixedExtractCode
        Write-Host "Fixed: Code - Extract Generated Image (now outputs binary)"
    }
}

# Create update payload
$updatePayload = @{
    name = $workflow.name
    nodes = $workflow.nodes
    connections = $workflow.connections
    settings = $workflow.settings
}

$body = $updatePayload | ConvertTo-Json -Depth 20

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Put -Headers $headers -Body $body
    Write-Host "Workflow updated successfully!"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
