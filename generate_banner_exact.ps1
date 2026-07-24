Add-Type -AssemblyName System.Drawing
$icon = [System.Drawing.Image]::FromFile('phone/assets/icon/icon.png')
$bmp = New-Object System.Drawing.Bitmap(320, 180)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# The original image is 1024x1024. The center 16:9 crop is Y=224, Height=576.
$srcY = (1024 - 576) / 2
$srcRect = New-Object System.Drawing.Rectangle(0, $srcY, 1024, 576)
$destRect = New-Object System.Drawing.Rectangle(0, 0, 320, 180)

$g.DrawImage($icon, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

$g.Dispose()
$icon.Dispose()

$bmp.Save('tv/android/app/src/main/res/drawable/tv_banner.png', [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Save('phone/assets/icon/icon_16_9_320x180.png', [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
