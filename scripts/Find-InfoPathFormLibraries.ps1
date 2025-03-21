##
#   Find-InfoPathFormLibraries
#   This script will scan all site collections in a web application and look for InfoPath Form Libraries
#   Dependency: Add-PSSnapin Microsoft.SharePoint.PowerShell
#   Dependency: Run on SharePoint Server

#   @param {string} $webAppUrl - The URL of the site to grant permissions to
#   @param {string} $spoDeploymentPrincipalAppId - The App ID of the SPO Deployment Principal
#   @param {string} $clientId - The Client ID of the Azure AD App (PnP PowerShell)
#   @param {string} $displayName - The display name of the Azure AD App
#   @param {string} $permission - The permission to grant to the Azure AD App
#
##

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern("^(https?:\/\/)?([\da-z\.\-]+)\.([a-z\.]{2,6})([\/\w\-\.\?\%&]*)?")]
    [string]$webAppUrl = "http://YourWebApplicationURL"
)

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$webApp = Get-SPWebApplication $webAppUrl

$results = @()

foreach ($site in $webApp.Sites) {
    try {
    ##Write-Host "Listing Webs"
    foreach ($web in $site.AllWebs) {
   ## Write-Host "Listing Lists"
        foreach ($list in $web.Lists) {
            if($list.BaseTemplate -eq "XMLForm") {
                Write-Host "InfoPath Form Library found: $($list.Title) at $($web.Url)" -ForegroundColor Green
                        
                $properties = @{
                    SiteName = $site.RootWeb.Title
                    WebName  = $web.Title
                    ListUrl = $list.DefaultViewUrl
                    ItemCount = $list.ItemCount  
                }
                $result = New-Object PSObject -Property $properties

                $results += $result
            }
            elseif ($list.BaseType -eq "DocumentLibrary" -and $list.ContentTypesEnabled -eq $true -or $list.BaseTemplate -eq "XMLForm") {
                foreach ($contentType in $list.ContentTypes) {
                    if ($contentType.Name -eq "Form") {
                       Write-Host "InfoPath Form Library found: $($list.Title) at $($web.Url)" -ForegroundColor Green
                        
                        $properties = @{
                            SiteName = $site.RootWeb.Title
                            WebName  = $web.Title
                            ListUrl = $list.DefaultViewUrl
                            ItemCount = $list.ItemCount  
                        }
                        $result = New-Object PSObject -Property $properties

                        $results += $result
                        break
                    }
                }
            }
        }
        $web.Dispose()
    }
    }
    catch {
        Write-Host "Unable to scan : $($site.Url)"
       ## Write-Host $Error
    }
    finally {
        $site.Dispose()
    }
}

$results | Export-Csv -Path D:\scripts\infopath-forms.csv -NoClobber -NoTypeInformation -Force