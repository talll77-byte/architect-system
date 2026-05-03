# ============================================================
# 3_generate_log.ps1
# יצירת לוג מסודר ומאורגן של כל הקבצים שנאספו
# עם הפרדות נושאים ברורות
# ============================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$CollectedFolder = "C:\COLLECTED_FILES"
$LogFile         = "$CollectedFolder\תיעוד_קבצים_מלא.txt"

$Lines = @()

$Lines += "=" * 70
$Lines += ""
$Lines += "        תיעוד קבצים שנאספו - דיגום ארובות"
$Lines += "        תאריך יצירה: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$Lines += "        מחשב מקור: $env:COMPUTERNAME"
$Lines += "        משתמש: $env:USERNAME"
$Lines += ""
$Lines += "=" * 70

# --- נתוני כלל הקבצים שנאספו ---
$AllFiles = Get-ChildItem -Path $CollectedFolder -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch "^_" }  # דלג על קבצי לוג פנימיים

$TotalCount = $AllFiles.Count
$TotalSize  = ($AllFiles | Measure-Object -Property Length -Sum).Sum
$TotalSizeMB = [math]::Round($TotalSize / 1MB, 2)

$Lines += ""
$Lines += "סיכום כללי"
$Lines += "-" * 40
$Lines += "  סה""כ קבצים שנאספו : $TotalCount"
$Lines += "  גודל כולל          : $TotalSizeMB MB"
$Lines += "  תיקיית איסוף       : $CollectedFolder"
$Lines += ""

# --- הפרדה לפי תת-תיקיות ---
$SubFolders = Get-ChildItem -Path $CollectedFolder -Directory -ErrorAction SilentlyContinue

foreach ($Sub in ($SubFolders | Sort-Object Name)) {
    $Files = Get-ChildItem -Path $Sub.FullName -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch "^_" }
    $Count   = $Files.Count
    $SizeMB  = [math]::Round(($Files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

    $Lines += ""
    $Lines += "=" * 70
    $Lines += "  קטגוריה: $($Sub.Name)   |   $Count קבצים   |   $SizeMB MB"
    $Lines += "=" * 70
    $Lines += ""

    if ($Count -eq 0) {
        $Lines += "  (אין קבצים בקטגוריה זו)"
        continue
    }

    $Lines += "  {0,-5} {1,-50} {2,10} {3,-22}" -f "#", "שם קובץ", "גודל KB", "תאריך שינוי אחרון"
    $Lines += "  " + "-" * 90

    $i = 1
    foreach ($File in ($Files | Sort-Object Name)) {
        $SizeKB   = [math]::Round($File.Length / 1KB, 1)
        $Modified = $File.LastWriteTime.ToString("dd/MM/yyyy HH:mm")
        $Lines   += "  {0,-5} {1,-50} {2,10} {3,-22}" -f $i, $File.Name, $SizeKB, $Modified
        $i++
    }
}

# --- הפרדה לפי סוג קובץ ---
$Lines += ""
$Lines += "=" * 70
$Lines += "  ריכוז לפי סוג קובץ (סיומת)"
$Lines += "=" * 70
$Lines += ""

$ByExt = $AllFiles | Group-Object Extension | Sort-Object Name
foreach ($Group in $ByExt) {
    $ExtSize = [math]::Round(($Group.Group | Measure-Object -Property Length -Sum).Sum / 1KB, 1)
    $Lines  += "  {0,-10}  {1,5} קבצים   {2,10} KB" -f $Group.Name, $Group.Count, $ExtSize
}

# --- רשימה אלפביתית מלאה ---
$Lines += ""
$Lines += "=" * 70
$Lines += "  רשימה אלפביתית מלאה של כל הקבצים"
$Lines += "=" * 70
$Lines += ""
$Lines += "  {0,-5} {1,-50} {2,-30} {3,10} {4,-22}" -f "#", "שם קובץ", "תת-תיקייה", "גודל KB", "תאריך שינוי"
$Lines += "  " + "-" * 120

$j = 1
foreach ($File in ($AllFiles | Sort-Object Name)) {
    $SizeKB   = [math]::Round($File.Length / 1KB, 1)
    $Modified = $File.LastWriteTime.ToString("dd/MM/yyyy HH:mm")
    $SubName  = $File.Directory.Name
    $Lines   += "  {0,-5} {1,-50} {2,-30} {3,10} {4,-22}" -f $j, $File.Name, $SubName, $SizeKB, $Modified
    $j++
}

$Lines += ""
$Lines += "=" * 70
$Lines += "  סוף מסמך תיעוד"
$Lines += "  נוצר אוטומטית ב: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$Lines += "=" * 70

# שמור
$Lines | Out-File -FilePath $LogFile -Encoding UTF8
$Lines | ForEach-Object { Write-Host $_ }

Write-Host "`nתיעוד נשמר: $LogFile" -ForegroundColor Green
notepad $LogFile
