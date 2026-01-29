$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYjBhZGE4Yi01ODViLTRlYmEtYmRjZS1hMjE3MDNkYjYwZWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4NzU3MDgxLCJleHAiOjE3NzM4OTI4MDB9.iYOwvT2qoKxAwLtvkcpr0Te0yk4R6AZ3liXD3UjX80U"
$workflowId = "WJIT6gkxSnEPCkKo"

$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Content-Type" = "application/json"
}

$workflow = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Get -Headers $headers

# Fix Code - Generate Signed URL - hardcode the R2 account info
# User will need to update these values or make bucket public
$fixedSignedUrlCode = @'
// Get data from the Code - Map Filter to Prompt node (before S3 upload modified it)
const prevData = $('Code - Map Filter to Prompt').item.json;

const filename = prevData.filename;
const expiresIn = 1200;

// Hardcoded R2 bucket info - update these values!
// If your bucket is public, use your public bucket URL
// Otherwise, you'll need to set up a public custom domain or use R2's public access
const bucketName = 'photoaibooth';

// Option 1: If you have a public bucket with custom domain:
// const downloadUrl = 'https://your-custom-domain.com/' + filename;

// Option 2: If bucket has public access enabled via R2 settings:
// const downloadUrl = 'https://pub-XXXX.r2.dev/' + filename;

// Option 3: Direct R2 URL (requires public access or signed URL from worker)
// For now, we'll construct a placeholder - you'll need to configure R2 public access
const downloadUrl = 'https://photoaibooth.your-domain.com/' + filename;

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

# Update the node
foreach ($node in $workflow.nodes) {
    if ($node.name -eq "Code - Generate Signed URL") {
        $node.parameters.jsCode = $fixedSignedUrlCode
        Write-Host "Fixed: Code - Generate Signed URL (removed env vars)"
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
    Write-Host ""
    Write-Host "NOTE: You need to configure R2 public access for downloads."
    Write-Host "Either:"
    Write-Host "1. Enable public access on your R2 bucket and get the public URL"
    Write-Host "2. Set up a custom domain for your R2 bucket"
    Write-Host "3. Use a Cloudflare Worker to generate signed URLs"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
