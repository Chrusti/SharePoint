
#Function to Download All Files from a SharePoint Online Folder - Recursively  
Function Download-SPOFolder([Microsoft.SharePoint.Client.Folder]$Folder, $DestinationFolder)
{  
    #Get the Folder's Site Relative URL
    $FolderURL = $Folder.ServerRelativeUrl.Substring($Folder.Context.Web.ServerRelativeUrl.Length)
    $LocalFolder = $DestinationFolder + ($FolderURL -replace "/","\")
    #Create Local Folder, if it doesn't exist or clear if exists
    If (!(Test-Path -Path $LocalFolder)) {
            New-Item -ItemType Directory -Path $LocalFolder | Out-Null
            Write-host -f Yellow "Created a New Folder '$LocalFolder'"
    }else {
        Remove-Item -Path $LocalFolder\* -Recurse
        Write-host -f Cyan "Cleared Folder '$LocalFolder'"
    }
           
    #Get all Files from the folder
    $FilesColl = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderURL -ItemType File 
    #Iterate through each file and download
    Foreach($File in $FilesColl)
    {
        Get-PnPFile -ServerRelativeUrl $File.ServerRelativeUrl -Path $LocalFolder -FileName $File.Name -AsFile -force
        Write-host -f Green "`tDownloaded File from '$($File.ServerRelativeUrl)'"
    }
    #Get Subfolders of the Folder and call the function recursively
    $SubFolders = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderURL -ItemType Folder
    Foreach ($Folder in $SubFolders | Where {$_.Name -ne "Forms"})
    {
        Download-SPOFolder $Folder $DestinationFolder
    }
}  
 
#Set Parameters
$SiteURL = "<SharePoint Online Site URL>"
$LibraryURL = "/Shared Documents/Testfolder" #Site Relative URL
$DownloadPath = "<Temporary Download Path>"
$LogPath = "<Path to .log File>"
$TenantName = '<tenant>.onmicrosoft.com'
$ClientId = '<Cliend-ID>' #ClientId of EntraID app registration
$Thumbprint = '<Certificate Thumbprint>' #Thumbprint of certificate used for app registration

$LogFileSize = (Get-ChildItem $LogPath).Length
If($LogFileSize -ge 10000000){
    Start-Transcript -Path $LogPath
    Write-host -f Cyan "Cleared Logfile '$LogPath' because >10MB"
}else {
    Start-Transcript -Path $LogPath -Append
}

#Connect to PnP Online
Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Tenant $TenantName -Thumbprint $Thumbprint
#Get The Root folder of the Library
$Folder = Get-PnPFolder -Url $LibraryURL
 
#Call the function to download the document library
Download-SPOFolder $Folder $DownloadPath

#Distribute Files to definitive locations
$SourcePath = $DownloadPath + ($LibraryURL -replace "/","\")
Move-Item -Path $SourcePath\CA\* -Destination '<Destination Path>' -Force


Stop-Transcript
