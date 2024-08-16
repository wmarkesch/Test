$desktopPath = [Environment]::GetFolderPath('Desktop')
New-Item -ItemType Directory -Path "$desktopPath\UsnJournal" | Out-Null
$errorActionPreference = 'SilentlyContinue'
$current_process = Get-Process -Id $PID
$current_process.PriorityClass = "High"

$ntfsDisks = Get-WmiObject Win32_LogicalDisk | Where-Object {$_.FileSystem -eq "NTFS"} | Select-Object DeviceID
foreach ($disk in $ntfsDisks) {
    $driveLetter = $disk.DeviceID.ToLower()
    $journal = fsutil usn readjournal $driveLetter csv
    $journal | Select-String -Pattern "0x00001000" | Out-File -FilePath "$desktopPath\UsnJournal\old_file_names.txt"
    $journal | Select-String -Pattern "0x00002000" | Out-File -FilePath "$desktopPath\UsnJournal\new_file_names.txt"
}
Write-Host "Detecting replaced files..."
    $oldFile = "$desktopPath\UsnJournal\old_file_names.txt"
    $newFile = "$desktopPath\UsnJournal\new_file_names.txt"
    $matchedLines = @()
    $oldContent = Get-Content $oldFile
    foreach ($oldLine in $oldContent) {
        $oldValues = $oldLine -split ','
        $oldPath = $oldValues[1]
        $oldTime = $oldValues[5]
        $newContent = Get-Content $newFile
        foreach ($newLine in $newContent) {
            $newValues = $newLine -split ','
            $newPath = $newValues[1]
            $newTime = $newValues[5]
            if ($oldPath -eq $newPath -and $oldTime -eq $newTime -and $oldTime -match '\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}:\d{2}') {
                $matchedLines += $oldLine
                $matchedLines += $newLine
            }
        }
    }
    if ($matchedLines.Count -gt 0) {
        $replacedFile = "$desktopPath\UsnJournal\replaced_files.txt"
        $matchedLines | Out-File $replacedFile
    }
    Remove-Item -Path "$desktopPath\UsnJournal\old_file_names.txt" -Force
    Remove-Item -Path "$desktopPath\UsnJournal\new_file_names.txt" -Force
    else {
    }

explorer.exe $desktopPath\UsnJournal