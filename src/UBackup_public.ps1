#Set-ExecutionPolicy Unrestricted #run this first and by itself to enable script execution.
#I've uploaded this file and a couple of programs you'll need to make it all work.
#I did not include winrar...You probably have it installed
#It's very important to use the version of yEncBinPoster included. See this reddit thread:
#https://www.reddit.com/r/usenet/comments/3esv98/looking_for_a_windows_command_line_exe_to_post/

#Remeber to configure yEncBinPoster first.

#Enable debugging
Set-PSDebug -trace 1 -strict

#Stop processing on errors.  This only works for the built in command lets. Default is Continue
#$ErrorActionPreference = "Stop"

#Spaces in paths are a real PIA!  I'm only working from paths that have no spaces. If I were you, I'd do the same...
$todaysDate              = Get-Date -Format yyyy-MM-dd
$usenetTmpDir            = "I:\usernet-tmp"
$backupSourceDir         = "I:\Fileserver_backups"
$pathTo_rarEXE           = "C:\usenet\RAR\Rar.exe"
$password                = "SuperSECRETPassWordGoesHERe"
$archiveName             = "backup-stuff"
$pathTo_parEXE           = "C:\usenet\MultiPar\par2j64.exe"
$pathTo_yEncBinPosterEXE = "C:\usenet\yEncBin_Poster\yEncBinPoster.exe"
$pathTo_nzbBackups       = "I:\Fileserver_backups\archive_of_nzb_uploads"
$headerMsg               = "Backup-crap"
$newsGroup               = "alt.binaries.backup"
$nzbName                 = "$todaysDate-backup-crap.nzb"

#Create or Delete all files from C:\usernet-tmp\*.*
if(!(Test-Path -Path $usenetTmpDir ))
{
    New-Item -ItemType directory -Path $usenetTmpDir
}
else 
{
    Remove-Item $usenetTmpDir\* -Recurse
}

<#
#Not needed anymore.  I can rar the files directly from the source dir.  As long there are no spaces in the path!
#If you have spaces in your path, you may need to copy the files.
#Copy file from I:\Fileserver backups\*.* to C:\usernet-tmp\  --This will only copy files and directories with extensions
if(Test-Path $backupSourceDir\*.*){
    Copy-Item $backupSourceDir\*.* $usenetTmpDir}
else {
    echo "Nothing to backup"
    exit
}
#>

#Need to cd to $usenetTmpDir so the rar get created there
cd $usenetTmpDir

if( Test-Path $backupSourceDir\*.* )
{
    #rar the files
    #a - Add files to archive.
    #ep1 - results in removing the path from the file names inside the archive.
    #m0 - No compression.  File was compressed with backup software
    #hp - hide files within rar file and encrypt with password
    #v100M - split the file into 100 MG splits
    #ag+YYYY-MM-DD-NN- "FS-backup" - Add the current date + incremental number to start of the filename.  eg. 2015-07-28-01-FS-backup
    $exe  = $pathTo_rarEXE
    $arg1 = "a"
    $arg2 = "-ep1"
    $arg3 = "-m0"
    $arg4 = "-hp$($password)"
    $arg5 = "-v100M"
    $arg6 = "-ag+YYYY-MM-DD-NN-"
    $arg7 = "$($archiveName)"
    $arg8 = "$($backupSourceDir)\*.*"
    #Debug statements
    #& $exe $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8
    #Start-Process cmd -ArgumentList '/k',"$($exe) $($arg1) $($arg2) $($arg3) $($arg4) $($arg5) $($arg6) $($arg7) $($arg8)" -Wait # keep waiting
    
    
    echo "Creating rar files..."
    #Exec program with parms and wait for it to fininsh before continuing.  The nice thing doing it this way
    #is that a cmd will show the progress
    Start-Process $exe -ArgumentList "$arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8" -Wait 
}
else 
{
    echo "Nothing to backup"
    exit
}

cd $usenetTmpDir

#Create par files
#    c - create
#/rr15 - 15% redundancy
#/lr   - Limits the number of recovery blocks per file.
#/d    - Set the working dir <--Very important
$exe  = $pathTo_parEXE                                    
$arg1 = 'c'                                               
$arg2 = "/rr15"                                           
$arg3 = "/lr"                                             
$arg4 = "/d $usenetTmpDir"                                
$arg4 = "$($usenetTmpDir)\$($todaysDate)-$($archiveName)" 
$arg5 = "$($usenetTmpDir)\*.rar"                          
#Debug statements
#& $exe $arg1 $arg2 $arg3 $arg4 $arg5 | Out-Null
#Start-Process cmd -ArgumentList '/k',"$($exe) $($arg1) $($arg2) $($arg3) $($arg4) $($arg5)" -Wait

echo "Creating PAR files..."
#Exec program with parms and wait for it to fininsh before continuing.  The nice thing doing it this way
#is that a cmd will show the progress
Start-Process $exe -ArgumentList "$arg1 $arg2 $arg3 $arg4 $arg5" -Wait

#post the files to usenet
#/P - Post immediately
#/C - Close program after upload is complete
#/F - Update all files from C:\usernet-tmp\
#/H - Subject header
#/N - post to this newsgroup
#/Z - Create a nzb file
$exe  = $pathTo_yEncBinPosterEXE
$arg1 = "/P"
$arg2 = "/C"
$arg3 = "/F$($usenetTmpDir)"
$arg4 = "/H$($headerMsg)"
$arg5 = "/N$($newsGroup)"
$arg6 = "/Z$($nzbName)"
#Debug statement
#& $exe $arg1 $arg2 $arg3 $arg4 $arg5 $arg6

echo "Uploading to usenet..."
#Exec program with parms and wait for it to fininsh before continuing.  
Start-Process $exe -ArgumentList "$arg1 $arg2 $arg3 $arg4 $arg5 $arg6" -Wait

cd $usenetTmpDir

#Move nzb file above to nzb storage dir, overwrite if file exists.
#If needed just grab the backup nzb file and download it :)
Move-Item *.nzb $pathTo_nzbBackups -Force
