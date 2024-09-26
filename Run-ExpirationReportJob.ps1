$adminUrl = "https://XY-admin.sharepoint.com/"

Connect-SPOService -Url $adminUrl

# Check if VersionExpiration is enabled
$tenantSettings = Get-SPOTenant
if ($tenantSettings.EnableVersionExpirationSetting) {
    
    # Get all site collections
    $sites = Get-SPOSite -Limit 10 -Filter { Url -notlike "-my.sharepoint.com" } | Select-Object Url, Title, StorageUsageCurrent | Sort-Object -Property StorageUsageCurrent -Descending


    # Iterate through each site collection
    foreach ($site in $sites) {
        $siteUrl = $site.Url
        $siteTitle = $site.Title
        $siteReport = $siteUrl + "/Shared Documents/" + $siteTitle + "-ExpirationReportJob.csv"

        # Create a new file version expiration report job
        New-SPOSiteFileVersionExpirationReportJob -Identity $siteUrl -ReportUrl "$siteReport" -Confirm:$False
        if (!$error) {Write-Host -ForegroundColor Green "File version expiration report job created for site: $siteUrl"}
    }
}
else {
    Write-Host -ForegroundColor Cyan 'Please enable Version Expiriation Feature by running "Set-SPOTenant -EnableVersionExpirationSetting $true"'
    exit
} 

