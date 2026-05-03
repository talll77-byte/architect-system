# ============================================================
# 1_verify_scan.ps1
# אימות סריקה - מציג כמה קבצים מכל סוג יש על הדיסקים
# לעומת כמה נאספו בפועל לתיקיית COLLECTED_FILES
# הרץ ב-PowerShell כמנהל
# ============================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$CollectedFolder = "C:\COLLECTED_FILES"
$ReportFile      = "$CollectedFolder\אימות_סריקה.txt"

$Extensions = @("*.pdf","*.doc","*.docx","*.xls","*.xlsx","*.ppt","*.pptx",
                "*.txt","*.csv","*.xml","*.zip","*.rar","*.7z",
                "*.jpg","*.jpeg","*.png","*.tif","*.tiff","*.dwg","*.dxf")

$ExcludeFolders = @("C:\Windows","C:\Program Files","C:\Program Files (x86)","C:\ProgramData\Microsoft")

$DrivesToScan = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }).Root

Write-Host "`n=== אימות סריקה ===" -ForegroundColor Cyan

# --- ספור קבצים שנאספו ---
$CollectedCount = @{}
$CollectedTotal = 0
foreach ($Ext in $Extensions) {
    $clean = $Ext.Replace("*","")
    $count = (Get-ChildItem -Path $CollectedFolder -Filter $Ext -Recurse -ErrorAction SilentlyContinue).Count
    if ($count -gt 0) { $CollectedCount[$clean] = $count; $CollectedTotal += $count }
}

# --- ספור כל הקבצים על הדיסקים ---
$DiskCount = @{}
$DiskTotal = 0
foreach ($Drive in $DrivesToScan) {
    Write-Host "סורק דיסק לאימות: $Drive" -ForegroundColor Yellow
    foreach ($Ext in $Extensions) {
        $clean = $Ext.Replace("*","")
        $files = Get-ChildItem -Path $Drive -Filter $Ext -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $f = $_
                $inExclude = $ExcludeFolders | Where-Object { $f.FullName.StartsWith($_) }
                -not $inExclude
            }
        $count = ($files | Measure-Object).Count
        if ($count -gt 0) {
            if ($DiskCount.ContainsKey($clean)) { $DiskCount[$clean] += $count }
            else { $DiskCount[$clean] = $count }
            $DiskTotal += $count
        }
    }
}

# --- בנה דוח ---
$Lines = @()
$Lines += "=" * 60
$Lines += "   דוח אימות סריקה"
$Lines += "   תאריך: $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
$Lines += "=" * 60
$Lines += ""
$Lines += "דיסקים שנסרקו: $($DrivesToScan -join ', ')"
$Lines += ""
$Lines += "-" * 60
$Lines += "  סיומת   |  קיים על דיסק  |  נאסף  |  פספוס"
$Lines += "-" * 60

foreach ($Ext in ($DiskCount.Keys | Sort-Object)) {
    $onDisk    = $DiskCount[$Ext]
    $collected = if ($CollectedCount.ContainsKey($Ext)) { $CollectedCount[$Ext] } else { 0 }
    $missed    = $onDisk - $collected
    $flag      = if ($missed -gt 0) { "  << יתכן שחסרים" } else { "" }
    $Lines    += "  {0,-10} {1,12}     {2,6}    {3,6}{4}" -f $Ext, $onDisk, $collected, $missed, $flag
}

$Lines += "-" * 60
$Lines += "  סה""כ       $DiskTotal              $CollectedTotal    $($DiskTotal - $CollectedTotal)"
$Lines += ""
$Lines += "=" * 60
$Lines += "הערה: 'פספוס' אינו בהכרח שגיאה - קבצים ללא מילת מפתח"
$Lines += "      רלוונטית בשמם/נתיבם לא נאספו בכוונה."
$Lines += "      אם הפספוס גדול - הרץ את סקריפט ההשלמה."
$Lines += "=" * 60

$Lines | ForEach-Object { Write-Host $_ }
$Lines | Out-File -FilePath $ReportFile -Encoding UTF8

Write-Host "`nדוח נשמר: $ReportFile" -ForegroundColor Green
