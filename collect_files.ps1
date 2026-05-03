Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$OutputFolder = "C:\COLLECTED_FILES\דיגום_ארובות_$(Get-Date -Format 'yyyy-MM-dd')"
$LogFile      = "$OutputFolder\_סיכום_איסוף.txt"
$DrivesToScan = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }).Root

$Extensions = @("*.pdf","*.doc","*.docx","*.xls","*.xlsx","*.ppt","*.pptx",
                "*.txt","*.csv","*.xml","*.zip","*.rar","*.7z",
                "*.jpg","*.jpeg","*.png","*.tif","*.tiff","*.dwg","*.dxf")

$Keywords = @("ארוב","ארובה","ארובות","דיגום","דגימ","פליטה","פליטות",
              "נוהל","נהלים","טופס","טפסים","בדיקה","בדיקות","מדידה","מדידות",
              "emission","stack","chimney","sampling","monitoring",
              "protocol","procedure","form","report","דוח")

$ExcludeFolders = @("C:\Windows","C:\Program Files","C:\Program Files (x86)","C:\ProgramData\Microsoft","C:\Users\All Users\Microsoft")

New-Item -ItemType Directory -Force -Path "$OutputFolder\PDF"     | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\Word"    | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\Excel"   | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\תמונות"  | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\שונות"   | Out-Null

function Get-Sub($e) {
    switch ($e.ToLower()) {
        ".pdf"  {"PDF"}  ".doc"  {"Word"} ".docx" {"Word"}
        ".xls"  {"Excel"} ".xlsx" {"Excel"}
        ".jpg"  {"תמונות"} ".jpeg" {"תמונות"} ".png" {"תמונות"}
        ".tif"  {"תמונות"} ".tiff" {"תמונות"}
        default {"שונות"}
    }
}

$Copied = 0; $Errors = 0; $AllFound = @()
$TotalDrives = $DrivesToScan.Count
$DriveIndex  = 0

Write-Host "`n=== איסוף קבצי דיגום ארובות ===" -ForegroundColor Cyan
Write-Host "דיסקים לסריקה: $($DrivesToScan -join ', ')" -ForegroundColor Yellow

foreach ($Drive in $DrivesToScan) {
    $DriveIndex++
    $DrivePct = [int](($DriveIndex / $TotalDrives) * 100)

    Write-Progress -Id 1 -Activity "סריקת דיסקים" `
        -Status "דיסק $DriveIndex מתוך $TotalDrives : $Drive" `
        -PercentComplete $DrivePct

    $ExtIndex  = 0
    $TotalExts = $Extensions.Count

    foreach ($Ext in $Extensions) {
        $ExtIndex++
        $ExtPct = [int](($ExtIndex / $TotalExts) * 100)

        Write-Progress -Id 2 -ParentId 1 -Activity "סוג קובץ" `
            -Status "מחפש $Ext  |  נאספו עד כה: $Copied קבצים" `
            -PercentComplete $ExtPct

        Get-ChildItem -Path $Drive -Filter $Ext -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $f = $_
            $inExclude = $ExcludeFolders | Where-Object { $f.FullName.StartsWith($_) }
            if ($inExclude) { return $false }
            $name = $f.Name + " " + $f.DirectoryName
            ($Keywords | Where-Object { $name -match $_ }).Count -gt 0
        } | ForEach-Object {

            Write-Progress -Id 3 -ParentId 2 -Activity "מעתיק" `
                -Status "$($_.Name)" -PercentComplete 50

            $sub  = Get-Sub $_.Extension
            $dest = "$OutputFolder\$sub\$($_.Name)"
            if (Test-Path $dest) {
                $b = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                $x = $_.Extension; $n = 1
                while (Test-Path "$OutputFolder\$sub\${b}_${n}${x}") { $n++ }
                $dest = "$OutputFolder\$sub\${b}_${n}${x}"
            }
            try {
                Copy-Item $_.FullName $dest -ErrorAction Stop
                Write-Host "  [OK] $($_.FullName)" -ForegroundColor Green
                $AllFound += $_.FullName; $Copied++
            } catch {
                Write-Host "  [ERR] $($_.FullName)" -ForegroundColor Red; $Errors++
            }
        }
    }
    Write-Progress -Id 2 -ParentId 1 -Activity "סוג קובץ" -Completed
}

Write-Progress -Id 1 -Activity "סריקת דיסקים" -Completed
Write-Progress -Id 3 -Activity "מעתיק" -Completed

"=== סיכום איסוף ===`nתאריך: $(Get-Date -Format 'dd/MM/yyyy HH:mm')`nתיקיית יעד: $OutputFolder`nדיסקים: $($DrivesToScan -join ', ')`nהועתקו: $Copied`nשגיאות: $Errors`n`n=== קבצים ===`n$($AllFound -join "`n")" |
    Out-File $LogFile -Encoding UTF8

Write-Host "`n=== סיום! ===" -ForegroundColor Cyan
Write-Host "הועתקו $Copied קבצים" -ForegroundColor Green
Write-Host "שגיאות: $Errors" -ForegroundColor $(if ($Errors -gt 0) {"Red"} else {"Green"})
Write-Host "לוג: $LogFile" -ForegroundColor Yellow
explorer $OutputFolder
