# Converts the 16:9 banner icon into square Android launcher icons:
# 1. Pads to square using the sampled background color
# 2. Generates legacy mipmap ic_launcher.png at 5 densities
# 3. Generates an adaptive-icon foreground (432px = xxxhdpi) + writes the
#    mipmap-anydpi-v26/ic_launcher.xml and values/colors.xml
Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\laure\StudioProjects\sleep_tracker\assets\sleep_tracker.png"
$resDir  = "C:\Users\laure\StudioProjects\sleep_tracker\android\app\src\main\res"

$src = [System.Drawing.Image]::FromFile($srcPath)
$w = $src.Width
$h = $src.Height
$size = [Math]::Max($w, $h)  # 1664

# Sample background color: average of pixels along the top edge (likely flat bg).
$bmp = New-Object System.Drawing.Bitmap($src)
$r = 0; $g = 0; $b = 0
$sampleXs = @(5, [int]($w / 2), ($w - 6))
foreach ($x in $sampleXs) {
  $p = $bmp.GetPixel($x, 3)
  $r += $p.R; $g += $p.G; $b += $p.B
}
$bg = [System.Drawing.Color]::FromArgb(
  [int]($r / $sampleXs.Count), [int]($g / $sampleXs.Count), [int]($b / $sampleXs.Count))
Write-Host "Background color: #$($bg.R.ToString('X2'))$($bg.G.ToString('X2'))$($bg.B.ToString('X2'))"

# Padded square canvas, source centered vertically.
function New-PaddedSquare([int]$dim, [string]$outPath) {
  $canvas = New-Object System.Drawing.Bitmap($dim, $dim)
  $g = [System.Drawing.Graphics]::FromImage($canvas)
  $g.Clear($bg)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $yOff = [int](($dim - ($h * $dim / $w)) / 2)
  $dstH = [int]($h * $dim / $w)
  $g.DrawImage($src, 0, $yOff, $dim, $dstH)
  $g.Dispose()
  $canvas.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $canvas.Dispose()
}

# Legacy densities: mdpi 48, hdpi 72, xhdpi 96, xxhdpi 144, xxxhdpi 192
$densities = @{
  "mipmap-mdpi"    = 48
  "mipmap-hdpi"    = 72
  "mipmap-xhdpi"   = 96
  "mipmap-xxhdpi"  = 144
  "mipmap-xxxhdpi" = 192
}
foreach ($entry in $densities.GetEnumerator()) {
  $out = Join-Path $resDir "$($entry.Key)\ic_launcher.png"
  New-PaddedSquare $entry.Value $out
  Write-Host "Wrote $out ($($entry.Value)x$($entry.Value))"
}

# Adaptive-icon foreground (432px, the xxxhdpi size Android scales down).
$fgDir = Join-Path $resDir "drawable"
$fgPath = Join-Path $fgDir "ic_launcher_foreground.png"
New-PaddedSquare 432 $fgPath
Write-Host "Wrote $fgPath (432x432)"

# mipmap-anydpi-v26/ic_launcher.xml (adaptive icon, API 26+ = our minSdk).
$anydpi = Join-Path $resDir "mipmap-anydpi-v26"
New-Item -ItemType Directory -Force -Path $anydpi | Out-Null
$colorHex = "#$($bg.R.ToString('X2'))$($bg.G.ToString('X2'))$($bg.B.ToString('X2'))"
@"
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
"@ | Set-Content -Path (Join-Path $anydpi "ic_launcher.xml") -Encoding UTF8
Write-Host "Wrote mipmap-anydpi-v26/ic_launcher.xml"

# values/colors.xml with the sampled background color.
@"
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">$colorHex</color>
</resources>
"@ | Set-Content -Path (Join-Path $resDir "values\colors.xml") -Encoding UTF8
Write-Host "Wrote values/colors.xml ($colorHex)"

$src.Dispose()
$bmp.Dispose()
Write-Host "Done."
