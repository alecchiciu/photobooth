$json = Get-Content 'c:\Users\User\Documents\n8n_builder\workflows_list.json' -Raw | ConvertFrom-Json
$json.data | ForEach-Object {
    [PSCustomObject]@{
        id=$_.id
        name=$_.name
        active=$_.active
    }
} | Where-Object { $_.name -match 'photo|booth' } | Format-Table -AutoSize
