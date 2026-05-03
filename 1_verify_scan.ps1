Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$CollectedFolder = "C:\COLLECTED_FILES"
$ReportFile      = "$CollectedFolder\אימות_סריקה.txt"

$Extensions     = @("*.pdf","*.doc","*.docx","*.xls","*.xlsx","*.ppt","*.pptx",
                    "*.txt","*.csv","*.xml","*.zip","*.rar","*.7z",
                    "*.jpg","*.jpeg","*.png","*.tif","*.tiff","*.dwg","*.dxf")
$ExcludeFolders = @("C:\Windows","C:\Program Files","C:\Program Files (x86)","C:\ProgramData\Microsoft")
$DrivesToScan   = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }).Root

Write-Host "`n=== אימות סריקה ===" -ForegroundColor Cyan

# ספור קבצים שנאספו
$CollectedCount = @{}; $CollectedTotal = 0
$i = 0
foreach ($Ext in $Extensions) {
    $i++
    Write-Progress -Id 1 -Activity "סופר קבצים שנאספו" `
        -Status "בודק $Ext" -PercentComplete ([int]($i / $Extensions.Count * 100))
    $clean = $Ext.Replace("*","")
    $count = (Get-ChildItem -Path $CollectedFolder -Filter $Ext -Recurse -ErrorAction SilentlyContinue).Count
    if ($count -gt 0) { $CollectedCount[$clean] = $count; $CollectedTotal += $count }
}
Write-Progress -Id 1 -Activity "סופר קבצים שנאספו" -Completed

# ספור קבצים על הדיסקים
$DiskCount = @{}; $DiskTotal = 0
$DriveIndex = 0
foreach ($Drive in $DrivesToScan) {
    $DriveIndex++
    Write-Progress -Id 2 -Activity "סורק דיסקים" `
        -Status "דיסק $DriveIndex/$($DrivesToScan.Count): $Drive" `
        -PercentComplete ([int]($DriveIndex / $DrivesToScan.Count * 100))

    $j = 0
    foreach ($Ext in $Extensions) {
        $j++
        Write-Progress -Id 3 -ParentId 2 -Activity "סוג קובץ" `
            -Status "מחפש $Ext" -PercentComplete ([int]($j / $Extensions.Count * 100))

        $clean = $Ext.Replace("*","")
        $count = (Get-ChildItem -Path $Drive -Filter $Ext -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $f = $_
                -not ($ExcludeFolders | Where-Object { $f.FullName.StartsWith($_) })
            } | Measure-Object).Count
        if ($count -gt 0) {
            if ($DiskCount.ContainsKey($clean)) { $DiskCount[$clean] += $count }
            else { $DiskCount[$clean] = $count }
            $DiskTotal += $count
        }
    }
    Write-Progress -Id 3 -ParentId 2 -Activity "סוג קובץ" -Completed
}
Write-Progress -Id 2 -Activity "סורק דיסקים" -Completed

# בנה דוח
$Lines  = @()
$Lines += "=" * 60
$Lines += "   דוח אימות סריקה"
$Lines += "   תאריך: $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
$Lines += "=" * 60
$Lines += "דיסקים שנסרקו: $($DrivesToScan -join ', ')"
$Lines += ""
$Lines += "-" * 60
$Lines += "  סיומת     | על דיסק | נאסף | פספוס"
$Lines += "-" * 60

foreach ($Ext in ($DiskCount.Keys | Sort-Object)) {
    $onDisk    = $DiskCount[$Ext]
    $collected = if ($CollectedCount.ContainsKey($Ext)) { $CollectedCount[$Ext] } else { 0 }
    $missed    = $onDisk - $collected
    $flag      = if ($missed -gt 0) { "  << יתכן שחסרים" } else { "" }
    $Lines    += "  {0,-10} {1,8}   {2,6}   {3,6}{4}" -f $Ext, $onDisk, $collected, $missed, $flag
}

$Lines += "-" * 60
$Lines += "  סה""כ        $DiskTotal      $CollectedTotal     $($DiskTotal - $CollectedTotal)"
$Lines += ""
$Lines += "הערה: פספוס אינו בהכרח שגיאה — קבצים ללא שם רלוונטי לא נאספו בכוונה."
$Lines += "=" * 60

$Lines | ForEach-Object { Write-Host $_ }
$Lines | Out-File -FilePath $ReportFile -Encoding UTF8
Write-Host "`nדוח נשמר: $ReportFile" -ForegroundColor Green
