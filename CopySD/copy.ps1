$PathToMonitor = '/media/pi'

$directoryOnCardToProcess = 'DCIM';
$fileTypeToProcess = 'mp4';

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