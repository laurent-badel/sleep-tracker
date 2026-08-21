# Generates a crescent-moon notification small icon (alpha silhouette).
# Android uses only the alpha channel of the small icon and tints it, so the
# moon is drawn as white-on-transparent pixels (color is irrelevant).
# Densities: mdpi 24, hdpi 36, xhdpi 48, xxhdpi 72, xxxhdpi 96 (24dp base).
Add-Type -AssemblyName System.Drawing

$resDir = "C:\Users\laure\StudioProjects\sleep_tracker\android\app\src\main\res"
$name = "ic_stat_moon.png"

# Crescent via per-pixel math: pixel is opaque when inside the moon body circle
# AND outside the cutout circle (offset up-right).
function New-CrescentBitmap([int]$size) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $cx = $size * 0.5
  $cy = $size * 0.5
  $r  = $size * 0.40   # body radius
  $ox = $size * 0.22   # cutout offset x (right)
  $oy = $size * 0.16   # cutout offset y (up, so subtract)
  $r2 = $size * 0.42   # cutout radius (slightly larger -> crescent)

  for ($y = 0; $y -lt $size; $y++) {
    for ($x = 0; $x -lt $size; $x++) {
      $dx = $x - $cx; $dy = $y - $cy
      $d1 = [Math]::Sqrt($dx * $dx + $dy * $dy)
      $dx2 = $x - ($cx + $ox); $dy2 = $y - ($cy - $oy)
      $d2 = [Math]::Sqrt($dx2 * $dx2 + $dy2 * $dy2)
      $alpha = if ($d1 -le $r -and $d2 -gt $r2) { 255 } else { 0 }
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, 255, 255, 255))
    }
  }
  return $bmp
}

$densities = @{
  "drawable-mdpi"    = 24
  "drawable-hdpi"    = 36
  "drawable-xhdpi"   = 48
  "drawable-xxhdpi"  = 72
  "drawable-xxxhdpi" = 96
}
foreach ($entry in $densities.GetEnumerator()) {
  $dir = Join-Path $resDir $entry.Key
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $bmp = New-CrescentBitmap $entry.Value
  $out = Join-Path $dir $name
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Host "Wrote $out ($($entry.Value)x$($entry.Value))"
}
Write-Host "Done."
