function New-S1DVQuery {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet("events","processes")]
        [String]
        $QueryType="events",

        [Parameter(Mandatory=$True)]
        $Query,

        [Parameter(Mandatory=$True,ParameterSetName="TimeFrame")]
        [ValidateSet("Last Hour","Last 24 Hours","Today", "Last 48 Hours", "Last 7 Days", "Last 30 Days", "This Month", "Last 2 Months", "Last 3 Months")]
        [String]
        $TimeFrame,

        [Parameter(Mandatory=$True,ParameterSetName="CustomTime")]
        [DateTime]
        $ToDate,

        [Parameter(Mandatory=$True,ParameterSetName="CustomTime")]
        [DateTime]
        $FromDate,

        [Parameter(Mandatory=$False)]
        [String[]]
        $GroupID,

        [Parameter(Mandatory=$False)]
        [String[]]
        $SiteID,

        [Parameter(Mandatory=$False)]
        [String[]]
        $AccountID
    )

    # Log the function and parameters being executed
    $InitializationLog = $MyInvocation.MyCommand.Name
    $MyInvocation.BoundParameters.GetEnumerator() | ForEach-Object { $InitializationLog = $InitializationLog + " -$($_.Key) $($_.Value)"}
    Write-Log -Message $InitializationLog -Level Informational

    if ($PSCmdlet.ParameterSetName -eq "TimeFrame") {
        $ToDate = [DateTime]::Now
        switch ($TimeFrame) {
            "Last Hour" { $FromDate = $ToDate.AddHours(-1) }
            "Last 24 Hours" { $FromDate = $ToDate.AddDays(-1) }
            "Today" { $FromDate = [DateTime]::Today }
            "Last 48 Hours" { $FromDate = $ToDate.AddDays(-2) }
            "Last 7 Days" { $FromDate = $ToDate.AddDays(-7) }
            "Last 30 Days" { $FromDate = $ToDate.AddDays(-30) }
            "This Month" { $FromDate = Get-Date -Year $ToDate.Year -Month $ToDate.Month -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0 }
            "Last 2 Months" { $FromDate = Get-Date -Year $ToDate.Year -Month $ToDate.AddMonths(-1).Month -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0 }
            "Last 3 Months" { $FromDate = Get-Date -Year $ToDate.Year -Month $ToDate.AddMonths(-2).Month -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0 }
        }
    }

    $Epoch = [DateTime]::new(1970,1,1,0,0,0,([DateTimeKind]::Utc))
    $To = [int64]($ToDate.ToUniversalTime() - $Epoch).TotalMilliseconds
    $From = [int64]($FromDate.ToUniversalTime() - $Epoch).TotalMilliseconds

    $URI = "/web/api/v2.1/dv/init-query"
    $Method = "POST"
    $Body = @{
        fromDate = $To
        toDate = $From
        query = $Query
        queryType = @( $QueryType )
    }
    if ($GroupID) { $Body.Add("groupdIds", @($GroupId -join ",") )}
    if ($SiteID) { $Body.Add("siteIds", @($SiteID -join ",") )}
    if ($AccountID) { $Body.Add("accountIds", @($AccountID -join ",") )}

    $Response = Invoke-S1Query -URI $URI -Method $Method -Body ($Body | ConvertTo-Json) -ContentType "application/json"

    Write-Output $Response.data
}