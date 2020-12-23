$PathToMonitor = "$($home)/Documents/Video"

$FolderToCopyTo = "$($home)/Videos/"

$directoryOnCardToProcess = 'DCIM';
$fileTypeToProcess = 'mp4';

if((Test-Path -Path $FolderToCopyTo) -eq $false){
    Write-Host "Folder to copy to $FolderToCopyTo doesn't exist"
    return;
}

function GetDestinationFolder{
    
    $now = Get-Date -Format "yyyy-MM-dd"
    
    $currentDayDestination = Join-Path -Path $FolderToCopyTo -ChildPath $now;
    if((Test-Path -Path $currentDayDestination) -eq $false){
        Write-Host "Creating $currentDayDestination since it doesn't exist yet" -ForegroundColor Green
        New-Item -Path $FolderToCopyTo -Name $now -ItemType "directory"

    }
    
    return $currentDayDestination;
}

function CheckIfPathIsAlreadyMounted {
    $subfolders = Get-ChildItem -Path $PathToMonitor -Directory
    $amountOfDirectoriesInPath = $subfolders.Length;
    if($amountOfDirectoriesInPath -eq 0){
        Write-Host "No folders mounted yet. Continuing with filewatcher" -ForegroundColor Yellow
        return
    }
    if($amountOfDirectoriesInPath -eq 1){
        Write-Host "Found one directory in $PathToMonitor. Will process this one."
        ProcessCreatedEvent $subfolders[0];
        return
    }

    if($amountOfDirectoriesInPath -gt 1){
        Write-Host "There are more than two directories already mounted in $PathToMonitor" -ForegroundColor Yellow
        Write-Host "Unsure what to do with them, so I'll stop and continue watching" -ForegroundColor Yellow
        Write-Host "Suggestion: remove all cards and only insert the one you want to copy" -ForegroundColor Yellow
        return
    }

    
}

function ProcessCreatedEvent{
    param (
        [Parameter(Mandatory)]
        [string]
        $fullPath
    )
    Write-Host "Processing $($fullPath)";
    $files = Get-ChildItem -Path $fullPath -File -Recurse -Include "*.$fileTypeToProcess"
    Write-Host "Found $($files.Length) files of type $fileTypeToProcess";
    foreach ($file in $files) {
        CopyFile $file
        Write-Host "-------"
    }
}

function CopyFile{
    param(
        [Parameter(Mandatory)]
        [string]
        $originFile
    )

    $fileSizeInBytes = (Get-Item $originFile).Length
    $fileSizeHumanFriendly = Format-FileSize $fileSizeInBytes
    Write-Host "File size is $fileSizeHumanFriendly"
    $fileName = (Get-Item $originFile).Name;
    $destinationFolder = GetDestinationFolder
    $destinationFile = Join-Path -Path $destinationFolder -ChildPath $fileName ;
    Write-Host "About to copy $originFile -> $destinationFile";
    Copy-Item -Path $originFile -Destination $destinationFile -Force
}

Function Format-FileSize() {
    Param ([float] $size)
    If ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -gt 0) {[string]::Format("{0:0.00} B", $size)}
    Else {""}
}




$FileSystemWatcher = New-Object System.IO.FileSystemWatcher
$FileSystemWatcher.Path  = $PathToMonitor
$FileSystemWatcher.IncludeSubdirectories = $false

# make sure the watcher emits events
$FileSystemWatcher.EnableRaisingEvents = $true


$Action = {
    $details = $event.SourceEventArgs
    $Name = $details.Name
    $FullPath = $details.FullPath
    $OldFullPath = $details.OldFullPath
    $OldName = $details.OldName
    $ChangeType = $details.ChangeType
    $Timestamp = $event.TimeGenerated
    $text = "{0} was {1} at {2}" -f $FullPath, $ChangeType, $Timestamp
    Write-Host ""
    Write-Host $text -ForegroundColor Green
    
    # you can also execute code based on change type here
    switch ($ChangeType)
    {
        'Changed' { "CHANGE" }
        'Created' { 
            Write-Host "Created event fired";
            ProcessCreatedEvent $FullPath
        }
        'Deleted' { "DELETED"
            # uncomment the below to mimick a time intensive handler
            <#
            Write-Host "Deletion Handler Start" -ForegroundColor Gray
            Start-Sleep -Seconds 4    
            Write-Host "Deletion Handler End" -ForegroundColor Gray
            #>
        }
        'Renamed' { 
            # this executes only when a file was renamed
            $text = "File {0} was renamed to {1}" -f $OldName, $Name
            Write-Host $text -ForegroundColor Yellow
        }
        default { Write-Host $_ -ForegroundColor Red -BackgroundColor White }
    }
}

# add event handlers
$handlers = . {
    Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Changed -Action $Action -SourceIdentifier FSChange
    Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Created -Action $Action -SourceIdentifier FSCreate
    Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Deleted -Action $Action -SourceIdentifier FSDelete
    Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Renamed -Action $Action -SourceIdentifier FSRename
}

Write-Host "Check if $($PathToMonitor) isn't already mounted";
CheckIfPathIsAlreadyMounted

Write-Host "Watching for changes to $PathToMonitor"

try
{
    do
    {
        Wait-Event -Timeout 1
        Write-Host "." -NoNewline
        
    } while ($true)
}
finally
{
    # this gets executed when user presses CTRL+C
    # remove the event handlers
    Unregister-Event -SourceIdentifier FSChange
    Unregister-Event -SourceIdentifier FSCreate
    Unregister-Event -SourceIdentifier FSDelete
    Unregister-Event -SourceIdentifier FSRename
    # remove background jobs
    $handlers | Remove-Job
    # remove filesystemwatcher
    $FileSystemWatcher.EnableRaisingEvents = $false
    $FileSystemWatcher.Dispose()
    "Event Handler disabled."
}