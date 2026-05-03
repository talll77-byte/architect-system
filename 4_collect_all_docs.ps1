Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# ============================================================
# 4_collect_all_docs.ps1
# איסוף כל קבצי המסמכים ללא סינון מילות מפתח
# מיועד לסקירה ידנית לאחר מכן
# ============================================================

$OutputFolder   = "C:\COLLECTED_FILES\_לסקירה_ידנית"
$LogFile        = "C:\COLLECTED_FILES\_לוג_סקירה_ידנית.txt"
$DrivesToScan   = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }).Root

# רק סוגי מסמכים — ללא תמונות, ללא xml, ללא zip
$DocExtensions  = @("*.pdf","*.doc","*.docx","*.xls","*.xlsx","*.ppt","*.pptx")

$ExcludeFolders = @(
    "C:\Windows",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\ProgramData\Microsoft",
    "C:\Users\All Users\Microsoft",
    "C:\COLLECTED_FILES"          # אל תסרוק את מה שכבר אספנו
)

# תת-תיקיות לפי סוג
New-Item -ItemType Directory -Force -Path "$OutputFolder\PDF"   | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\Word"  | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\Excel" | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\PPT"   | Out-Null

function Get-Sub($e) {
    switch ($e.ToLower()) {
        ".pdf"  {"PDF"}
        ".doc"  {"Word"}  ".docx" {"Word"}
        ".xls"  {"Excel"} ".xlsx" {"Excel"}
        ".ppt"  {"PPT"}   ".pptx" {"PPT"}
        default {"Word"}
    }
}

$Copied     = 0
$Skipped    = 0
$Errors     = 0
$AllFound   = @()
$DriveIndex = 0

Write-Host "`n=== איסוף כל המסמכים לסקירה ידנית ===" -ForegroundColor Cyan
Write-Host "תיקיית יעד: $OutputFolder" -ForegroundColor Yellow
Write-Host "סורק: $($DrivesToScan -join ', ')" -ForegroundColor Yellow

foreach ($Drive in $DrivesToScan) {
    $DriveIndex++
    $DrivePct = [int]($DriveIndex / $DrivesToScan.Count * 100)

    Write-Progress -Id 1 -Activity "סריקת דיסקים" `
        -Status "דיסק $DriveIndex/$($DrivesToScan.Count): $Drive  |  נאספו: $Copied קבצים" `
        -PercentComplete $DrivePct

    $ExtIndex = 0
    foreach ($Ext in $DocExtensions) {
        $ExtIndex++
        Write-Progress -Id 2 -ParentId 1 -Activity "סוג קובץ" `
            -Status "מחפש $Ext" `
            -PercentComplete ([int]($ExtIndex / $DocExtensions.Count * 100))

        Get-ChildItem -Path $Drive -Filter $Ext -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $f = $_
            # דלג על תיקיות מוחרגות
            $inExclude = $ExcludeFolders | Where-Object { $f.FullName.StartsWith($_) }
            if ($inExclude) { $script:Skipped++; return $false }
            return $true
        } | ForEach-Object {

            Write-Progress -Id 3 -ParentId 2 -Activity "מעתיק" `
                -Status "$($_.Name)" -PercentComplete 50

            $sub  = Get-Sub $_.Extension
            $dest = "$OutputFolder\$sub\$($_.Name)"

            # טיפול בכפילויות
            if (Test-Path $dest) {
                $b = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                $x = $_.Extension; $n = 1
                while (Test-Path "$OutputFolder\$sub\${b}_${n}${x}") { $n++ }
                $dest = "$OutputFolder\$sub\${b}_${n}${x}"
            }

            try {
                Copy-Item $_.FullName $dest -ErrorAction Stop
                $AllFound += [PSCustomObject]@{
                    Name      = $_.Name
                    FullPath  = $_.FullName
                    Extension = $_.Extension
                    SizeKB    = [math]::Round($_.Length / 1KB, 1)
                    Modified  = $_.LastWriteTime.ToString("dd/MM/yyyy HH:mm")
                }
                $Copied++
            } catch {
                Write-Host "  [ERR] $($_.FullName)" -ForegroundColor Red
                $Errors++
            }
        }
    }
    Write-Progress -Id 2 -ParentId 1 -Activity "סוג קובץ" -Completed
    Write-Host "  [דיסק $Drive] נאספו $Copied קבצים עד כה" -ForegroundColor White
}

Write-Progress -Id 1 -Activity "סריקת דיסקים" -Completed
Write-Progress -Id 3 -Activity "מעתיק" -Completed

# ============================================================
# כתיבת לוג מסודר
# ============================================================
$Lines  = @()
$Lines += "=" * 70
$Lines += "  לוג איסוף כל המסמכים — לסקירה ידנית"
$Lines += "  תאריך : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$Lines += "  מחשב  : $env:COMPUTERNAME"
$Lines += "=" * 70
$Lines += ""
$Lines += "  סה""כ נאספו : $Copied קבצים"
$Lines += "  שגיאות     : $Errors"
$Lines += "  תיקיית יעד : $OutputFolder"
$Lines += ""

foreach ($SubName in @("PDF","Word","Excel","PPT")) {
    $Group = $AllFound | Where-Object { (Get-Sub $_.Extension) -eq $SubName }
    $Count = ($Group | Measure-Object).Count
    $Lines += "=" * 70
    $Lines += "  $SubName  |  $Count קבצים"
    $Lines += "=" * 70
    $Lines += "  {0,-5} {1,-50} {2,-40} {3,8} {4}" -f "#","שם קובץ","נתיב מקורי","גודל KB","תאריך שינוי"
    $Lines += "  " + "-" * 110
    $i = 1
    foreach ($f in ($Group | Sort-Object Name)) {
        $Lines += "  {0,-5} {1,-50} {2,-40} {3,8} {4}" -f $i, $f.Name, $f.FullPath, $f.SizeKB, $f.Modified
        $i++
    }
    $Lines += ""
}

$Lines += "=" * 70
$Lines += "  סוף לוג  |  $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$Lines += "=" * 70

$Lines | Out-File -FilePath $LogFile -Encoding UTF8

Write-Host "`n=== סיום! ===" -ForegroundColor Cyan
Write-Host "נאספו $Copied קבצים לסקירה ידנית" -ForegroundColor Green
Write-Host "שגיאות: $Errors" -ForegroundColor $(if ($Errors -gt 0) {"Red"} else {"Green"})
Write-Host "תיקייה: $OutputFolder" -ForegroundColor Yellow
Write-Host "לוג   : $LogFile" -ForegroundColor Yellow
explorer $OutputFolder
