$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8080/')
$listener.Start()
Write-Host "Server running at http://localhost:8080"
Write-Host "Press Ctrl+C to stop"

$root = $PSScriptRoot

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $path = $context.Request.Url.LocalPath

    if ($path -eq '/') {
        $path = '/index.html'
    }

    $file = Join-Path $root $path.TrimStart('/')

    if (Test-Path $file) {
        $content = [System.IO.File]::ReadAllBytes($file)
        $ext = [System.IO.Path]::GetExtension($file)

        $mimeTypes = @{
            '.html' = 'text/html; charset=utf-8'
            '.css' = 'text/css; charset=utf-8'
            '.js' = 'application/javascript; charset=utf-8'
            '.json' = 'application/json'
            '.png' = 'image/png'
            '.jpg' = 'image/jpeg'
            '.jpeg' = 'image/jpeg'
            '.svg' = 'image/svg+xml'
            '.ico' = 'image/x-icon'
        }

        $mime = $mimeTypes[$ext]
        if (-not $mime) {
            $mime = 'application/octet-stream'
        }

        $context.Response.ContentType = $mime
        $context.Response.OutputStream.Write($content, 0, $content.Length)
        Write-Host "200 $path"
    } else {
        $context.Response.StatusCode = 404
        Write-Host "404 $path"
    }

    $context.Response.Close()
}
