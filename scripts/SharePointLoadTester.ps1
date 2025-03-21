param(
    $endPoints = @("https://{sharepointurl}"),
    $simulatedUserCounts = @(10,50,100,500,1000)
)


$credential = Get-Credential

$Configuration = [hashtable]::Synchronized(@{})
$Configuration.Results = @()


$Headers = @{

}

## TODO - configured some mechanism to measure - but just run this direct for now.
$Worker = {
    param($credential, $endPoints, $batch, $userId, $Configuration)
    

    Measure-Command {
    
        foreach($endpoint in $endPoints) {
            $sleepFor = Get-Random -Minimum 800 -Maximum 10000
            Start-Sleep -Milliseconds $sleepFor
            $time = Measure-Command {
                Invoke-WebRequest -Uri $endpoint -Credential $credential
            }

            $output = @{
                Batch  = $batch
                UserId = $userId
                EndPoint = $endpoint
                Seconds = $time.TotalSeconds
                Milliseconds = $time.TotalMilliseconds
            }

            $Configuration.Results += New-Object PSObject -Property $output

        }
   }
}




foreach($simulatedUserCount in $simulatedUserCounts) {
    Write-Host "Running Batch($($simulatedUserCount))"
    $userList = 1..$simulatedUserCount
    $MaxRunspaces = $simulatedUserCount


    $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxRunspaces, $SessionState, $Host)
    $RunspacePool.Open()

    $Jobs = New-Object System.Collections.ArrayList




    foreach($user in $userList) {
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        ## param($Headers, $endPoints, $userId, $Configuration)
    
        $PowerShell.AddScript($Worker).AddArgument($credential).AddArgument($endPoints).AddArgument("Batch:$($simulatedUserCount)").AddArgument("User '$($user)'").AddArgument($Configuration) | Out-Null
    
        $JobObj = New-Object -TypeName PSObject -Property @{
            Runspace = $PowerShell.BeginInvoke()
            PowerShell = $PowerShell  
        }

        $Jobs.Add($JobObj) | Out-Null
    }


    while ($Jobs.Runspace.IsCompleted -contains $false) {
        Write-Host (Get-date).Tostring() "Still running..."
        Start-Sleep -Seconds 20
    }
}

$ticks = (Get-Date).Ticks
$Configuration.Results | Export-Csv -Path ".\test-results-$($ticks).csv" -NoClobber -NoTypeInformation 