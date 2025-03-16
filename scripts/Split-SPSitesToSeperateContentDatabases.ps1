param(
    [string]$webAppUrl = "https://your-sharepoint-webapp-url"
)
# Get all site collections excluding MySites
$sitecollections = (Get-SPWebApplication -Identity $webAppUrl).Sites | Where-Object { $_.Url -notlike "*-my*" }

# Create new content databases and move site collections
foreach ($site in $siteCollections) {
    $dbName = "ContentDB_" + ($site.Url -replace "https?://|/", "_")
    # Check if the database already exists
    if (Get-SPContentDatabase -WebApplication $webAppUrl | Where-Object { $_.Name -eq $dbName }) {
        Write-Host "Database $dbName already exists. Skipping creation."
        continue
    }
    else {
        # Create a new content database for each site collection
        Write-Host "Creating new content database: $dbName"
        New-SPContentDatabase -Name $dbName -WebApplication "https://your-sharepoint-webapp-url"
    }
    
    Move-SPSite -Identity $site.Url -DestinationDatabase $dbName
}