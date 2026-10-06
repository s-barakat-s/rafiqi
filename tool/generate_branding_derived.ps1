Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

function Convert-ToTransparentWhite {
    param([string]$SourcePath, [string]$DestPath)

    $src = [System.Drawing.Bitmap]::new($SourcePath)
    $dst = [System.Drawing.Bitmap]::new($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

    $rect = [System.Drawing.Rectangle]::new(0, 0, $src.Width, $src.Height)
    $sd = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $dd = $dst.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

    $bytes = [Math]::Abs($sd.Stride) * $src.Height
    $buffer = [byte[]]::new($bytes)
    [System.Runtime.InteropServices.Marshal]::Copy($sd.Scan0, $buffer, 0, $bytes)

    for ($i = 0; $i -lt $bytes; $i += 4) {
        $b = $buffer[$i]; $g = $buffer[$i + 1]; $r = $buffer[$i + 2]
        $lum = [int]((0.299 * $r) + (0.587 * $g) + (0.114 * $b))
        $buffer[$i] = 255; $buffer[$i + 1] = 255; $buffer[$i + 2] = 255
        $buffer[$i + 3] = $lum
    }

    [System.Runtime.InteropServices.Marshal]::Copy($buffer, 0, $dd.Scan0, $bytes)
    $src.UnlockBits($sd); $dst.UnlockBits($dd)
    $src.Dispose()
    $dst.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dst.Dispose()
    Write-Host "Created $DestPath"
}

function New-SafeSplashIcon {
    param([string]$SourcePath, [string]$DestPath, [int]$Size = 1000, [double]$ContentRatio = 0.60)

    $src = [System.Drawing.Bitmap]::new($SourcePath)
    $dst = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gfx = [System.Drawing.Graphics]::FromImage($dst)
    $gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $gfx.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gfx.Clear([System.Drawing.Color]::Transparent)

    $content = [int]($Size * $ContentRatio)
    $offset = [int](($Size - $content) / 2)
    $destRect = [System.Drawing.Rectangle]::new($offset, $offset, $content, $content)
    $gfx.DrawImage($src, $destRect)
    $gfx.Dispose()
    $src.Dispose()
    $dst.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dst.Dispose()
    Write-Host "Created $DestPath"
}

function Get-AverageColor {
    param([string]$SourcePath)
    $src = [System.Drawing.Bitmap]::new($SourcePath)
    $rect = [System.Drawing.Rectangle]::new(0, 0, $src.Width, $src.Height)
    $sd = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $bytes = [Math]::Abs($sd.Stride) * $src.Height
    $buffer = [byte[]]::new($bytes)
    [System.Runtime.InteropServices.Marshal]::Copy($sd.Scan0, $buffer, 0, $bytes)
    $src.UnlockBits($sd)
    $src.Dispose()
    $totalB = [double]0; $totalG = [double]0; $totalR = [double]0; $count = 0
    for ($i = 0; $i -lt $bytes; $i += 4) {
        $totalB += $buffer[$i]; $totalG += $buffer[$i + 1]; $totalR += $buffer[$i + 2]; $count++
    }
    '#{0:X2}{1:X2}{2:X2}' -f [int]($totalR / $count), [int]($totalG / $count), [int]($totalB / $count)
}

$branding = 'D:\projects\tasbeh\assets\branding'
$res = 'D:\projects\tasbeh\android\app\src\main\res'

# The master adaptive_foreground.png is already a transparent PNG containing the
# white logo (verified: corner A=0). Derive padded, correctly-sized variants that
# PRESERVE alpha instead of converting luminance.

# 1. Padded transparent adaptive/monochrome foreground (safe-zone friendly)
New-SafeSplashIcon -SourcePath "$branding\adaptive_foreground.png" -DestPath "$branding\adaptive_foreground_transparent.png" -Size 1000 -ContentRatio 0.70

# 2. Android 12+ safe splash icons (transparent, centered, generous padding for
#    Android's circular icon mask)
New-SafeSplashIcon -SourcePath "$branding\adaptive_foreground.png" -DestPath "$res\drawable-nodpi\android12_splash_icon.png" -Size 1000 -ContentRatio 0.55
New-SafeSplashIcon -SourcePath "$branding\adaptive_foreground.png" -DestPath "$res\drawable-night-nodpi\android12_splash_icon.png" -Size 1000 -ContentRatio 0.55

Write-Host ("Light art avg: " + (Get-AverageColor "$branding\splash_light.png"))
Write-Host ("Dark art avg: " + (Get-AverageColor "$branding\splash_dark.png"))
