$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYjBhZGE4Yi01ODViLTRlYmEtYmRjZS1hMjE3MDNkYjYwZWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4NzU3MDgxLCJleHAiOjE3NzM4OTI4MDB9.iYOwvT2qoKxAwLtvkcpr0Te0yk4R6AZ3liXD3UjX80U"
$workflowId = "WJIT6gkxSnEPCkKo"

$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Content-Type" = "application/json"
}

$workflow = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Get -Headers $headers

# Fix 1: Code - Map Filter to Prompt (use simple UUID, no crypto)
$fixedFilterCode = @'
// Simple UUID generator (no crypto required)
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0;
    var v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

const filterPrompts = {
  'cartoon': 'Transform this photo into a vibrant cartoon style with bold outlines, bright colors, and smooth shading. Keep the person recognizable but stylized.',
  'oil_painting': 'Transform this photo into a classic oil painting with visible brushstrokes, rich textures, and deep colors in the style of Renaissance masters.',
  'anime': 'Transform this photo into Japanese anime style with large expressive eyes, clean lines, and vibrant colors while maintaining the persons likeness.',
  'vintage': 'Transform this photo into a vintage 1970s style with warm sepia tones, soft film grain, and slight vignetting.',
  'neon': 'Transform this photo into a cyberpunk neon style with glowing neon edges, dark background, and vibrant pink/blue/purple color scheme.',
  'watercolor': 'Transform this photo into a soft watercolor painting with flowing colors, gentle washes, and delicate brush effects.',
  'sketch': 'Transform this photo into a detailed pencil sketch with professional shading, hatching, and fine line work.',
  'pop_art': 'Transform this photo into Andy Warhol pop art style with bold primary colors, halftone dots, and high contrast.'
};

const filterName = $json.body.filter.toLowerCase();
const prompt = filterPrompts[filterName];

if (!prompt) {
  throw new Error('Invalid filter: ' + filterName);
}

let imageData = $json.body.image;
if (imageData.startsWith('data:')) {
  imageData = imageData.split(',')[1];
}

const uuid = generateUUID();
const filename = uuid + '.png';

return {
  json: {
    filter: filterName,
    prompt: prompt,
    imageBase64: imageData,
    filename: filename,
    uuid: uuid,
    timestamp: new Date().toISOString(),
    session_id: $json.body.session_id || null
  }
};
'@

# Fix 2: Code - Generate Signed URL (simplified, no crypto)
$fixedSignedUrlCode = @'
// Generate URL for R2 (simplified without crypto signing)
const accountId = $env.R2_ACCOUNT_ID;
const bucketName = $env.R2_BUCKET_NAME || 'photoaibooth';

const filename = $json.filename;
const expiresIn = 1200;

// Use R2's public URL
const downloadUrl = 'https://' + accountId + '.r2.cloudflarestorage.com/' + bucketName + '/' + filename;

return {
  json: {
    downloadUrl: downloadUrl,
    filename: filename,
    uuid: $json.uuid,
    filter: $json.filter,
    expiresIn: expiresIn,
    expiresAt: new Date(Date.now() + expiresIn * 1000).toISOString(),
    timestamp: $json.timestamp,
    session_id: $json.session_id
  }
};
'@

# Fix 3: OpenAI Image Generation (use dall-e-3 model)
$fixedOpenAIBody = @'
={
  "model": "dall-e-3",
  "prompt": "{{ $json.prompt }}",
  "n": 1,
  "size": "1024x1024",
  "quality": "standard",
  "response_format": "b64_json"
}
'@

# Update the nodes
foreach ($node in $workflow.nodes) {
    if ($node.name -eq "Code - Map Filter to Prompt") {
        $node.parameters.jsCode = $fixedFilterCode
        Write-Host "Fixed: Code - Map Filter to Prompt"
    }
    if ($node.name -eq "Code - Generate Signed URL") {
        $node.parameters.jsCode = $fixedSignedUrlCode
        Write-Host "Fixed: Code - Generate Signed URL"
    }
    if ($node.name -eq "HTTP - OpenAI Image Generation") {
        $node.parameters.jsonBody = $fixedOpenAIBody
        Write-Host "Fixed: HTTP - OpenAI Image Generation (using dall-e-3)"
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
    Write-Host "`nWorkflow updated successfully!"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
