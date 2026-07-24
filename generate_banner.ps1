Add-Type -AssemblyName System.Drawing
$icon = [System.Drawing.Image]::FromFile('tv/assets/icon/icon.png')
$bmp = New-Object System.Drawing.Bitmap(1024, 576)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$bg = [System.Drawing.ColorTranslator]::FromHtml('#210A3E')
$g.Clear($bg)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# Scale icon to fit height (576x576)
$iconSize = 500
$x = (1024 - $iconSize) / 2
$y = (576 - $iconSize) / 2
$g.DrawImage($icon, $x, $y, $iconSize, $iconSize)

$g.Dispose()
$icon.Dispose()

$bmp.Save('tv/android/app/src/main/res/drawable/tv_banner.png', [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
