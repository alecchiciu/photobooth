# Read the base64 image
$base64Image = Get-Content -Path "test_image_base64.txt" -Raw

# Create the request body
$body = @{
    image = "data:image/jpeg;base64,$base64Image"
    filter = "cartoon"
    session_id = "test-session-123"
} | ConvertTo-Json

# Send the request
$headers = @{
    "Content-Type" = "application/json"
}

Write-Output "Testing workflow with 200x200 smiley face image..."
Write-Output "Filter: cartoon"
Write-Output "Sending request to webhook..."

try {
    $response = Invoke-RestMethod -Uri "https://petriclucas.app.n8n.cloud/webhook/photo-booth" -Method Post -Body $body -Headers $headers -TimeoutSec 180

    Write-Output "`n=== RESPONSE ==="
    Write-Output "Success: $($response.success)"
    Write-Output "Filter Applied: $($response.filter_applied)"
    Write-Output "Download URL: $($response.download_url)"
    Write-Output "Expires At: $($response.expires_at)"

    if ($response.qr_code) {
        Write-Output "QR Code: Present (base64 data)"
    }

    $response | ConvertTo-Json -Depth 5
} catch {
    Write-Output "`n=== ERROR ==="
    Write-Output $_.Exception.Message
    if ($_.ErrorDetails.Message) {
        Write-Output "Details: $($_.ErrorDetails.Message)"
    }
}
