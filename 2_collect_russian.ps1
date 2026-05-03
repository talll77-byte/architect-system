Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$OutputFolder = "C:\COLLECTED_FILES\דיגום_ארובות_$(Get-Date -Format 'yyyy-MM-dd')"
$LogFile      = "$OutputFolder\_סיכום_רוסית.txt"
$DrivesToScan = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }).Root

$Extensions = @("*.pdf","*.doc","*.docx","*.xls","*.xlsx","*.ppt","*.pptx",
                "*.txt","*.csv","*.xml","*.zip","*.rar","*.7z",
                "*.jpg","*.jpeg","*.png","*.tif","*.tiff","*.dwg","*.dxf")

$RussianKeywords = @(
    "труб","дымо","выброс","эмисси","загрязн",
    "замер","измерени","отбор","проб","анализ","контрол","монитор",
    "протокол","процедур","форм","отчет","акт","журнал",
    "экологи","охран","атмосфер"
)

$ExcludeFolders = @("C:\Windows","C:\Program Files","C:\Program Files (x86)","C:\ProgramData\Microsoft")

New-Item -ItemType Directory -Force -Path "$OutputFolder\PDF"     | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\Word"    | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\Excel"   | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\תמונות"  | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\שונות"   | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\רוסית"   | Out-Null

$Copied = 0; $Errors = 0; $AllFound = @()
$DriveIndex = 0

Write-Host "`n=== איסוף קבצים ברוסית ===" -ForegroundColor Cyan

foreach ($Drive in $DrivesToScan) {
    $DriveIndex++
    Write-Progress -Id 1 -Activity "סריקת דיסקים" `
        -Status "דיסק $DriveIndex/$($DrivesToScan.Count): $Drive  |  נאספו: $Copied קבצים" `
        -PercentComplete ([int]($DriveIndex / $DrivesToScan.Count * 100))

    $ExtIndex = 0
    foreach ($Ext in $Extensions) {
        $ExtIndex++
        Write-Progress -Id 2 -ParentId 1 -Activity "סוג קובץ" `
            -Status "מחפש $Ext" `
            -PercentComplete ([int]($ExtIndex / $Extensions.Count * 100))

        Get-ChildItem -Path $Drive -Filter $Ext -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $f = $_
            $inExclude = $ExcludeFolders | Where-Object { $f.FullName.StartsWith($_) }
            if ($inExclude) { return $false }
            $name = $f.Name + " " + $f.DirectoryName
            ($RussianKeywords | Where-Object { $name -match $_ }).Count -gt 0
        } | ForEach-Object {
            Write-Progress -Id 3 -ParentId 2 -Activity "מעתיק" -Status "$($_.Name)" -PercentComplete 50

            $dest = "$OutputFolder\רוסית\$($_.Name)"
            if (Test-Path $dest) {
                $b = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                $x = $_.Extension; $n = 1
                while (Test-Path "$OutputFolder\רוסית\${b}_${n}${x}") { $n++ }
                $dest = "$OutputFolder\רוסית\${b}_${n}${x}"
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

"=== סיכום קבצים ברוסית ===`nתאריך: $(Get-Date)`nהועתקו: $Copied`nשגיאות: $Errors`n`n$($AllFound -join "`n")" |
    Out-File $LogFile -Encoding UTF8

Write-Host "`n=== סיום! הועתקו $Copied קבצים ברוסית ===" -ForegroundColor Green
Write-Host "לוג: $LogFile"
