$apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYjBhZGE4Yi01ODViLTRlYmEtYmRjZS1hMjE3MDNkYjYwZWQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY4NzU3MDgxLCJleHAiOjE3NzM4OTI4MDB9.iYOwvT2qoKxAwLtvkcpr0Te0yk4R6AZ3liXD3UjX80U"

$headers = @{
    "X-N8N-API-KEY" = $apiKey
}

$result = Invoke-RestMethod -Uri "http://localhost:5678/api/v1/executions/17?includeData=true" -Method Get -Headers $headers

Write-Host "Status: $($result.status)"
Write-Host "Error: $($result.data.resultData.error.message)"
Write-Host "Description: $($result.data.resultData.error.description)"
Write-Host "Stack: $($result.data.resultData.error.stack)" | Select-Object -First 5

# Show which node failed
Write-Host "`nLast Node Executed: $($result.data.resultData.lastNodeExecuted)"
