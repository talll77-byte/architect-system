# ============================================================
# 2_collect_russian.ps1
# השלמת איסוף - קבצים עם שמות ברוסית / קירילית
# מוסיף לתיקיית COLLECTED_FILES הקיימת
# ============================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$OutputFolder = "C:\COLLECTED_FILES\דיגום_ארובות_$(Get-Date -Format 'yyyy-MM-dd')"
$LogFile      = "$OutputFolder\_סיכום_רוסית.txt"
$DrivesToScan = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }).Root

$Extensions = @("*.pdf","*.doc","*.docx","*.xls","*.xlsx","*.ppt","*.pptx",
                "*.txt","*.csv","*.xml","*.zip","*.rar","*.7z",
                "*.jpg","*.jpeg","*.png","*.tif","*.tiff","*.dwg","*.dxf")

# מילות מפתח ברוסית - תחום פליטות וניטור ארובות
$RussianKeywords = @(
    # ארובה / צינור / פליטה
    "труб",       # труба = צינור/ארובה
    "дымо",       # дымоход = ארובה
    "выброс",     # פליטה
    "эмисси",     # emission
    "загрязн",    # זיהום
    # דיגום / בדיקה / מדידה
    "замер",      # מדידה
    "измерени",   # מדידה/איסוף
    "отбор",      # דגימה
    "проб",       # פרובה / דגימה
    "анализ",     # ניתוח
    "контрол",    # בקרה / ניטור
    "монитор",    # מוניטור
    # נהלים / טפסים / דוחות
    "протокол",   # נוהל / פרוטוקול
    "процедур",   # נוהל / פרוצדורה
    "форм",       # טופס
    "отчет",      # דוח
    "акт",        # אישור / מסמך רשמי
    "журнал",     # יומן / לוג
    # כללי
    "экологи",    # אקולוגיה / סביבה
    "охран",      # הגנה / שמירה
    "атмосфер"    # אטמוספרה
)

$ExcludeFolders = @("C:\Windows","C:\Program Files","C:\Program Files (x86)","C:\ProgramData\Microsoft")

New-Item -ItemType Directory -Force -Path "$OutputFolder\PDF"       | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\Word"      | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\Excel"     | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\תמונות"    | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\שונות"     | Out-Null
New-Item -ItemType Directory -Force -Path "$OutputFolder\רוסית"     | Out-Null

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

Write-Host "`n=== סריקת קבצים ברוסית ===" -ForegroundColor Cyan

foreach ($Drive in $DrivesToScan) {
    Write-Host "סורק: $Drive" -ForegroundColor Yellow
    foreach ($Ext in $Extensions) {
        Get-ChildItem -Path $Drive -Filter $Ext -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $f = $_
            $inExclude = $ExcludeFolders | Where-Object { $f.FullName.StartsWith($_) }
            if ($inExclude) { return $false }
            $name = $f.Name + " " + $f.DirectoryName
            ($RussianKeywords | Where-Object { $name -match $_ }).Count -gt 0
        } | ForEach-Object {
            $sub  = "רוסית"
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
}

"=== סיכום קבצים ברוסית ===`nתאריך: $(Get-Date)`nהועתקו: $Copied`nשגיאות: $Errors`n`n$($AllFound -join "`n")" |
    Out-File $LogFile -Encoding UTF8

Write-Host "`n=== סיום! הועתקו $Copied קבצים ברוסית ===" -ForegroundColor Green
Write-Host "לוג: $LogFile"
