Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$CollectedFolder = "C:\COLLECTED_FILES"
$LogFile         = "$CollectedFolder\תיעוד_קבצים_מלא.txt"

Write-Host "`n=== יוצר לוג מסודר ===" -ForegroundColor Cyan

Write-Progress -Id 1 -Activity "טוען קבצים" -Status "סורק תיקיית COLLECTED_FILES..." -PercentComplete 10

$AllFiles = Get-ChildItem -Path $CollectedFolder -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch "^\." -and $_.Extension -ne ".txt" -or $_.Name -match "אימות|סיכום" -eq $false }

$AllFiles = Get-ChildItem -Path $CollectedFolder -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike "_*" -and $_.Name -notlike "אימות*" -and $_.Name -notlike "תיעוד*" }

Write-Progress -Id 1 -Activity "טוען קבצים" -Status "נמצאו $($AllFiles.Count) קבצים" -PercentComplete 30

$TotalCount  = $AllFiles.Count
$TotalSizeMB = [math]::Round(($AllFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

$Lines = @()
$Lines += "=" * 70
$Lines += ""
$Lines += "        תיעוד קבצים שנאספו - דיגום ארובות"
$Lines += "        תאריך יצירה : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$Lines += "        מחשב מקור  : $env:COMPUTERNAME"
$Lines += "        משתמש      : $env:USERNAME"
$Lines += ""
$Lines += "=" * 70
$Lines += ""
$Lines += "סיכום כללי"
$Lines += "-" * 40
$Lines += "  סה""כ קבצים   : $TotalCount"
$Lines += "  גודל כולל    : $TotalSizeMB MB"
$Lines += "  תיקיית איסוף: $CollectedFolder"
$Lines += ""

Write-Progress -Id 1 -Activity "טוען קבצים" -Status "מעבד קטגוריות..." -PercentComplete 50

$SubFolders  = Get-ChildItem -Path $CollectedFolder -Directory -ErrorAction SilentlyContinue
$SubIndex    = 0

foreach ($Sub in ($SubFolders | Sort-Object Name)) {
    $SubIndex++
    Write-Progress -Id 2 -ParentId 1 -Activity "קטגוריות" `
        -Status "מעבד: $($Sub.Name)" `
        -PercentComplete ([int]($SubIndex / $SubFolders.Count * 100))

    $Files   = Get-ChildItem -Path $Sub.FullName -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Name -notlike "_*" }
    $Count   = $Files.Count
    $SizeMB  = [math]::Round(($Files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

    $Lines  += ""
    $Lines  += "=" * 70
    $Lines  += "  קטגוריה: $($Sub.Name)   |   $Count קבצים   |   $SizeMB MB"
    $Lines  += "=" * 70
    $Lines  += ""

    if ($Count -eq 0) { $Lines += "  (אין קבצים בקטגוריה זו)"; continue }

    $Lines += "  {0,-5} {1,-50} {2,10} {3,-22}" -f "#", "שם קובץ", "גודל KB", "תאריך שינוי"
    $Lines += "  " + "-" * 92
    $i = 1
    foreach ($File in ($Files | Sort-Object Name)) {
        $Lines += "  {0,-5} {1,-50} {2,10} {3,-22}" -f $i, $File.Name, [math]::Round($File.Length/1KB,1), $File.LastWriteTime.ToString("dd/MM/yyyy HH:mm")
        $i++
    }
}
Write-Progress -Id 2 -ParentId 1 -Activity "קטגוריות" -Completed

Write-Progress -Id 1 -Activity "טוען קבצים" -Status "מסכם לפי סוג..." -PercentComplete 80

$Lines += ""
$Lines += "=" * 70
$Lines += "  ריכוז לפי סוג קובץ"
$Lines += "=" * 70
$Lines += ""
$AllFiles | Group-Object Extension | Sort-Object Name | ForEach-Object {
    $Lines += "  {0,-10}  {1,5} קבצים   {2,10} KB" -f $_.Name, $_.Count, [math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum/1KB,1)
}

$Lines += ""
$Lines += "=" * 70
$Lines += "  רשימה אלפביתית מלאה"
$Lines += "=" * 70
$Lines += ""
$Lines += "  {0,-5} {1,-50} {2,-20} {3,10} {4,-22}" -f "#", "שם קובץ", "קטגוריה", "גודל KB", "תאריך שינוי"
$Lines += "  " + "-" * 112
$j = 1
foreach ($File in ($AllFiles | Sort-Object Name)) {
    $Lines += "  {0,-5} {1,-50} {2,-20} {3,10} {4,-22}" -f $j, $File.Name, $File.Directory.Name, [math]::Round($File.Length/1KB,1), $File.LastWriteTime.ToString("dd/MM/yyyy HH:mm")
    $j++
}

$Lines += ""
$Lines += "=" * 70
$Lines += "  סוף מסמך  |  נוצר: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$Lines += "=" * 70

Write-Progress -Id 1 -Activity "טוען קבצים" -Status "שומר קובץ..." -PercentComplete 95
$Lines | Out-File -FilePath $LogFile -Encoding UTF8
Write-Progress -Id 1 -Activity "טוען קבצים" -Completed

$Lines | ForEach-Object { Write-Host $_ }
Write-Host "`nתיעוד נשמר: $LogFile" -ForegroundColor Green
notepad $LogFile
