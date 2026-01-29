$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYjBhZGE4Yi01ODViLTRlYmEtYmRjZS1hMjE3MDNkYjYwZWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4NzU3MDgxLCJleHAiOjE3NzM4OTI4MDB9.iYOwvT2qoKxAwLtvkcpr0Te0yk4R6AZ3liXD3UjX80U"
$workflowId = "WJIT6gkxSnEPCkKo"

$headers = @{
    "X-N8N-API-KEY" = $apiKey
    "Content-Type" = "application/json"
}

$workflow = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Get -Headers $headers

# ============================================
# FIX 1: Webhook - change responseMode
# ============================================
foreach ($node in $workflow.nodes) {
    if ($node.name -eq "Webhook - Receive Photo") {
        $node.parameters.responseMode = "responseNode"
        Write-Host "Fixed: Webhook responseMode -> responseNode"
    }
}

# ============================================
# FIX 2: Code - Map Filter to Prompt (no crypto)
# ============================================
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

foreach ($node in $workflow.nodes) {
    if ($node.name -eq "Code - Map Filter to Prompt") {
        $node.parameters.jsCode = $fixedFilterCode
        Write-Host "Fixed: Code - Map Filter to Prompt (no crypto)"
    }
}

# ============================================
# FIX 3: HTTP - OpenAI Image Generation (dall-e-3)
# ============================================
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

foreach ($node in $workflow.nodes) {
    if ($node.name -eq "HTTP - OpenAI Image Generation") {
        $node.parameters.jsonBody = $fixedOpenAIBody
        Write-Host "Fixed: HTTP - OpenAI Image Generation (dall-e-3)"
    }
}

# ============================================
# FIX 4: Code - Extract Generated Image (output binary)
# ============================================
$fixedExtractCode = @'
const openaiResponse = $json;
let generatedImageB64;

if (openaiResponse.data && openaiResponse.data[0]) {
  generatedImageB64 = openaiResponse.data[0].b64_json || openaiResponse.data[0].url;
} else {
  throw new Error('Unexpected OpenAI response format');
}

const prevData = $('Code - Map Filter to Prompt').item.json;

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

foreach ($node in $workflow.nodes) {
    if ($node.name -eq "Code - Extract Generated Image") {
        $node.parameters.jsCode = $fixedExtractCode
        Write-Host "Fixed: Code - Extract Generated Image (binary output)"
    }
}

# ============================================
# FIX 5: Code - Generate Signed URL (R2 public URL)
# ============================================
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
        Write-Host "Fixed: Code - Generate Signed URL (R2 public URL)"
    }
}

# ============================================
# FIX 6: Code - Prepare Response (QR code binary)
# ============================================
$fixedPrepareResponseCode = @'
const signedUrlData = $('Code - Generate Signed URL').item.json;

let qrBase64 = '';
const binaryData = $input.item.binary;
if (binaryData && binaryData.data) {
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
        Write-Host "Fixed: Code - Prepare Response (QR binary extraction)"
    }
}

# ============================================
# SAVE WORKFLOW
# ============================================
$updatePayload = @{
    name = $workflow.name
    nodes = $workflow.nodes
    connections = $workflow.connections
    settings = $workflow.settings
}

$body = $updatePayload | ConvertTo-Json -Depth 20

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/workflows/$workflowId" -Method Put -Headers $headers -Body $body
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "ALL FIXES APPLIED SUCCESSFULLY!"
    Write-Host "=========================================="
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
