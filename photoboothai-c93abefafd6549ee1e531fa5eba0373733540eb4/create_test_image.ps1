Add-Type -AssemblyName System.Drawing

$bitmap = New-Object System.Drawing.Bitmap(200, 200)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

# Fill background
$graphics.Clear([System.Drawing.Color]::SkyBlue)

# Draw a simple face (yellow circle)
$brush = [System.Drawing.Brushes]::Yellow
$graphics.FillEllipse($brush, 40, 40, 120, 120)

# Eyes (black circles)
$blackBrush = [System.Drawing.Brushes]::Black
$graphics.FillEllipse($blackBrush, 70, 70, 20, 20)
$graphics.FillEllipse($blackBrush, 110, 70, 20, 20)

# Smile (arc)
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 3)
$graphics.DrawArc($pen, 70, 90, 60, 40, 0, 180)

# Save to memory stream and convert to base64
$ms = New-Object System.IO.MemoryStream
$bitmap.Save($ms, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$bytes = $ms.ToArray()
$base64 = [Convert]::ToBase64String($bytes)

# Clean up
$graphics.Dispose()
$bitmap.Dispose()
$ms.Dispose()

# Save base64 to file
$base64 | Out-File -FilePath "test_image_base64.txt" -NoNewline
Write-Output "Image created and saved to test_image_base64.txt"
Write-Output "Base64 length: $($base64.Length) characters"
