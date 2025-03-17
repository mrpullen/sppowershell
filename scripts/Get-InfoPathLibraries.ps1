param(
    [string]$webAppUrl = "http://YourWebApplicationURL"
)

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$webApp = Get-SPWebApplication $webAppUrl

foreach ($site in $webApp.Sites) {
    foreach ($web in $site.AllWebs) {
        foreach ($list in $web.Lists) {
            if ($list.BaseType -eq "DocumentLibrary" -and $list.ContentTypesEnabled -eq $true) {
                foreach ($contentType in $list.ContentTypes) {
                    if ($contentType.Name -eq "Form") {
                        Write-Host "InfoPath Form Library found: $($list.Title) at $($web.Url)" -ForegroundColor Green
                        break
                    }
                }
            }
        }
        $web.Dispose()
    }
    $site.Dispose()
}