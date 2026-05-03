# ============================================================
# collect_files.ps1
# סקריפט איסוף קבצי דיגום ארובות
# הרץ כ: PowerShell -ExecutionPolicy Bypass -File collect_files.ps1
# ============================================================

# --- הגדרות ---
$OutputFolder = "C:\COLLECTED_FILES\דיגום_ארובות_$(Get-Date -Format 'yyyy-MM-dd')"
$LogFile      = "$OutputFolder\_סיכום_איסוף.txt"

# תיקיות לסריקה (כל הדיסקים הזמינים)
$DrivesToScan = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }).Root

# סיומות קבצים לאיסוף
$Extensions = @(
    "*.pdf",
    "*.doc", "*.docx",
    "*.xls", "*.xlsx",
    "*.ppt", "*.pptx",
    "*.txt",
    "*.csv",
    "*.xml",
    "*.zip", "*.rar", "*.7z",
    "*.jpg", "*.jpeg", "*.png", "*.tif", "*.tiff",
    "*.dwg", "*.dxf"
)

# מילות מפתח לסינון (קבצים שמכילים אחת מהמילים האלה בשמם)
$Keywords = @(
    "ארוב", "ארובה", "ארובות",
    "דיגום", "דגימ",
    "פליטה", "פליטות",
    "נוהל", "נהלים",
    "טופס", "טפסים",
    "בדיקה", "בדיקות",
    "מדידה", "מדידות",
    "emission", "stack", "chimney",
    "sampling", "monitoring",
    "protocol", "procedure",
    "form", "report", "דוח"
)

# תיקיות לדלג עליהן (מערכת)
$ExcludeFolders = @(
    "C:\Windows",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\ProgramData\Microsoft",
    "C:\Users\All Users\Microsoft"
)

# ============================================================
# יצירת תיקיית פלט
# ============================================================
Write-Host "`n=== סקריפט איסוף קבצי דיגום ארובות ===" -ForegroundColor Cyan
Write-Host "תיקיית יעד: $OutputFolder" -ForegroundColor Yellow

New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputFolder\PDF"        -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputFolder\Word"       -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputFolder\Excel"      -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputFolder\תמונות"     -Force | Out-Null
New-Item -ItemType Directory -Path "$OutputFolder\שונות"      -Force | Out-Null

# ============================================================
# פונקציה: קביעת תת-תיקייה לפי סיומת
# ============================================================
function Get-TargetSubfolder($ext) {
    switch ($ext.ToLower()) {
        ".pdf"  { return "PDF" }
        ".doc"  { return "Word" }
        ".docx" { return "Word" }
        ".xls"  { return "Excel" }
        ".xlsx" { return "Excel" }
        ".jpg"  { return "תמונות" }
        ".jpeg" { return "תמונות" }
        ".png"  { return "תמונות" }
        ".tif"  { return "תמונות" }
        ".tiff" { return "תמונות" }
        default { return "שונות" }
    }
}

# ============================================================
# סריקה
# ============================================================
$AllFound    = @()
$Copied      = 0
$Skipped     = 0
$Errors      = 0

Write-Host "`nמתחיל סריקה על: $($DrivesToScan -join ', ')" -ForegroundColor Green

foreach ($Drive in $DrivesToScan) {
    Write-Host "`nסורק: $Drive" -ForegroundColor White

    foreach ($Ext in $Extensions) {
        try {
            $Files = Get-ChildItem -Path $Drive -Filter $Ext -Recurse -ErrorAction SilentlyContinue |
                Where-Object {
                    # דלג על תיקיות מערכת
                    $skip = $false
                    foreach ($ex in $ExcludeFolders) {
                        if ($_.FullName.StartsWith($ex)) { $skip = $true; break }
                    }
                    -not $skip
                }

            foreach ($File in $Files) {
                # בדוק אם שם הקובץ מכיל מילת מפתח, או אסוף הכל אם לא צוינו מילות מפתח
                $matchesKeyword = $false
                foreach ($kw in $Keywords) {
                    if ($File.Name -match $kw -or $File.DirectoryName -match $kw) {
                        $matchesKeyword = $true
                        break
                    }
                }

                if ($matchesKeyword) {
                    $AllFound += $File.FullName

                    $SubFolder   = Get-TargetSubfolder $File.Extension
                    $Destination = "$OutputFolder\$SubFolder\$($File.Name)"

                    # טיפול בכפילויות - הוסף מספר אם קיים
                    if (Test-Path $Destination) {
                        $BaseName  = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
                        $FileExt   = $File.Extension
                        $Counter   = 1
                        while (Test-Path "$OutputFolder\$SubFolder\${BaseName}_${Counter}${FileExt}") { $Counter++ }
                        $Destination = "$OutputFolder\$SubFolder\${BaseName}_${Counter}${FileExt}"
                    }

                    try {
                        Copy-Item -Path $File.FullName -Destination $Destination -ErrorAction Stop
                        Write-Host "  [OK] $($File.FullName)" -ForegroundColor Green
                        $Copied++
                    } catch {
                        Write-Host "  [ERR] $($File.FullName): $_" -ForegroundColor Red
                        $Errors++
                    }
                } else {
                    $Skipped++
                }
            }
        } catch {
            # תיקייה לא נגישה - המשך
        }
    }
}

# ============================================================
# כתיבת לוג סיכום
# ============================================================
$Summary = @"
=== סיכום איסוף קבצים ===
תאריך: $(Get-Date -Format 'dd/MM/yyyy HH:mm')
תיקיית יעד: $OutputFolder

נסרקו דיסקים: $($DrivesToScan -join ', ')
קבצים שהועתקו: $Copied
קבצים שדולגו (לא רלוונטים): $Skipped
שגיאות: $Errors

=== רשימת קבצים שנאספו ===
$($AllFound | ForEach-Object { "  $_" } | Out-String)
"@

$Summary | Out-File -FilePath $LogFile -Encoding UTF8
Write-Host "`n=== סיום ===" -ForegroundColor Cyan
Write-Host "הועתקו $Copied קבצים" -ForegroundColor Green
Write-Host "שגיאות: $Errors" -ForegroundColor $(if ($Errors -gt 0) { "Red" } else { "Green" })
Write-Host "לוג מלא: $LogFile" -ForegroundColor Yellow
Write-Host "פתח את התיקייה: explorer `"$OutputFolder`"" -ForegroundColor White
