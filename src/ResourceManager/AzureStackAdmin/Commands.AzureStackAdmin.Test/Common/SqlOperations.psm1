function Get-SqlConnectionString
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $DataSource,

        [Parameter(Mandatory=$true)]
        [string] $UserId,

        [Parameter(Mandatory=$true)]
        [string] $Password
    )

    $builder = New-Object -TypeName 'System.Data.SqlClient.SqlConnectionStringBuilder'
    $builder['Data Source'] = $DataSource
    $builder['User ID'] = $UserId
    $builder['Password'] = $Password
    $builder['Asynchronous Processing'] = $true
    return $builder.ConnectionString
}

function Add-SqlHostingServer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $SqlServerName,

        [Parameter(Mandatory=$true)]
        [string] $ConnectionString,

        [Alias("Name")]
        [Parameter(ValueFromPipeline=$true, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $ResourceGroupName
    )

    $putSqlServer = @{
        Uri = "{0}subscriptions/{1}/resourcegroups/{2}/providers/Microsoft.Sql.Admin/hostingservers/{3}?api-version=2.0" -f $Global:AzureStackConfig.AdminUri, $Global:AzureStackConfig.SubscriptionId, $ResourceGroupName, $SqlServerName
        Method = "PUT"
        Headers = @{ "Authorization" = "Bearer "+ $Global:AzureStackConfig.Token }
        ContentType = "application/json"
    }

    $sqlServerRequestBody = [pscustomobject]@{
        name = $SqlServerName
        location = $Global:AzureStackConfig.ArmLocation
        tags = @{}
        properties =
            @{
               name = $SqlServerName
               serverId = 0
               alwaysOnEnabled = $false
               availabilityGroup = $null
               uncFileShare = $null
               availableSpaceMB = 0
               totalSpaceMB = 10240000
               databaseCount = 0
               connectionString = $ConnectionString
               state = $null
            }
    }


    if ($Global:AzureStackConfig.IsAad)
    {
        $resourceType = "Microsoft.Sql.Admin/hostingservers"
        $apiVersion ="2.0"
        # TODO: - Remove ErrorAction when bug 3923719 is fixed
        $ErrorActionPreference='SilentlyContinue'
        return New-AzureRmResource -ResourceName $SqlServerName -Location $Global:AzureStackConfig.ArmLocation -ResourceGroupName $ResourceGroupName -ResourceType $resourceType -PropertyObject $sqlServerRequestBody.Properties -ApiVersion $apiVersion  -Force -ErrorAction SilentlyContinue
        $ErrorActionPreference='Stop'
    }

    # Make the API call
    $sqlServerAdded = $sqlServerRequestBody | ConvertTo-Json -Depth 6 | Invoke-RestMethod @putSqlServer

    Write-Verbose  "Sql $SqlServerName added successfully"
    return $sqlServerAdded
}

function Get-SqlHostingServers
{

    $getSqlServers = @{
        Uri = "{0}/subscriptions/{1}/providers/Microsoft.Sql.Admin/hostingservers?api-version=2.0" -f $Global:AzureStackConfig.AdminUri, $Global:AzureStackConfig.SubscriptionId
        Method = "GET"
        Headers = @{ "Authorization" = "Bearer "+ $Global:AzureStackConfig.Token }
        ContentType = "application/json"
    }

    # Make the API call
    $sqlServers = Invoke-RestMethod @getSqlServers
    return $sqlServers.value
}

function Get-SqlHostingServer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $SqlServerName,

        [Parameter(Mandatory=$false)]
        [string] $ResourceGroupName
    )

    if ($ResourceGroupName)
    {
        $getSqlServer = @{
            Uri = "{0}subscriptions/{1}/resourceGroups/{2}/providers/Microsoft.Sql.Admin/hostingservers/{3}?api-version=2.0" -f $Global:AzureStackConfig.AdminUri, $Global:AzureStackConfig.SubscriptionId, $ResourceGroupName, $SqlServerName
            Method = "GET"
            Headers = @{ "Authorization" = "Bearer "+ $Global:AzureStackConfig.Token }
            ContentType = "application/json"
        }

        return Invoke-RestMethod @getSqlServer
    }

    foreach( $sqlServer in Get-SqlHostingServers )
    {
        if ($sqlServer.Name -ieq $SqlServerName)
        {
            return $sqlServer
        }
    }

    return $null
}

function Remove-SqlHostingServer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $SqlServerId

    )


    if ($Global:AzureStackConfig.IsAad)
    {
        Remove-AzureRmResource -ResourceId $SqlServerId -Force
    }

    $deleteSqlServer = @{
        Uri = "{0}{1}?api-version=2.0" -f $Global:AzureStackConfig.AdminUri, $SqlServerId
        Method = "DELETE"
        Headers = @{ "Authorization" = "Bearer "+ $Global:AzureStackConfig.Token }
        ContentType = "application/json"
    }

    Invoke-RestMethod @deleteSqlServer
}

function Get-NewSqlDatabaseNewServerTemplate
{
    param
    (
        [Parameter(Mandatory=$false)]
        [string] $Token
    )

    Write-Verbose "Getting new sql database template from the gallery endpoint"
    $getSqlDbTemplate = @{
        Uri = "{0}Providers/Microsoft.Gallery/GalleryItems/Microsoft.SqlDatabase.0.1.0?api-version=2015-04-01" -f $Global:AzureStackConfig.AdminUri
        Method = "GET"
        Headers = @{ "Authorization" = "Bearer "+ $Token }
        ContentType = "application/json"
    }

    $SqlDatabaseTemplate = Invoke-RestMethod @getSqlDbTemplate
    Write-Verbose "Got the TemplateLink"

    return $SqlDatabaseTemplate.artifacts[1].uri
}

function Get-SqlDatabases
{
    param
    (
        [Parameter(Mandatory=$false)]
        [string] $SubscriptionId,

        [Parameter(Mandatory=$false)]
        [string] $Token
    )

    $sqlUri = "{0}subscriptions/{1}/resources?api-version=1.0&`$filter=resourceType%20eq%20'Microsoft.Sql%2Fservers%2Fdatabases'" -f $Global:AzureStackConfig.AdminUri, $SubscriptionId
    $sqlHeaders = @{ "Authorization" = "Bearer "+ $Token }
    $sqlContentType = "application/json"

    Invoke-RestMethod -Method GET -Uri $sqlUri -Headers $sqlHeaders -ContentType $sqlContentType

}

# There is no support for quering the sql resource directly for now
# TODO: Change after RDtask 3923719
function Get-SqlDatabase
{
    param
    (
        # SqlDb of the form logicalserver/databasename
        [Parameter(Mandatory=$true)]
        [string] $SqlDatabase,

        [Parameter(Mandatory=$false)]
        [string] $SubscriptionId,

        [Parameter(Mandatory=$false)]
        [string] $Token
    )

    return (Get-SqlDatabases -SubscriptionId $SubscriptionId -Token $Token).value | Where-Object { $_.name -ieq $SqlDatabase }
}

function New-SqlDatabase
{
    param
    (

        [Parameter(Mandatory=$true)]
        [string] $LogicalServerName,

        [Parameter(Mandatory=$true)]
        [string] $DatabaseName,

        [Parameter(Mandatory=$true)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory=$false)]
        [string] $SubscriptionId,

        [Parameter(Mandatory=$false)]
        [string] $Token

    )

    if ($Global:AzureStackConfig.IsAad)
    {
        $serverResourceType = "Microsoft.Sql/servers"
        $dbResourceType = "Microsoft.Sql/servers/databases"
        $apiVersion="2.0"

        # If existing , just updates it , no harm
        New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Global:AzureStackConfig.ArmLocation -Force

        $logicalServerProperties = @{"administratorLogin" = "adminuser"; "administratorLoginPassword" = "P@ssword1"}
        $SqlDatabaseProperties = @{"edition" = "Web"; "collation" = "SQL_Latin1_General_CP1_CI_AS"; "maxSizeBytes" = "10485760"}
        $databaseResource = "$LogicalServerName/$DatabaseName"

        # TODO: -Remove this after BUG 3923719 is fixed
        $ErrorActionPreference='SilentlyContinue'
        try  { $server = New-AzureRmResource -ResourceName $DatabaseName -Location $Global:AzureStackConfig.ArmLocation -ResourceGroupName $ResourceGroupName -ResourceType $serverResourceType -PropertyObject $logicalServerProperties -ApiVersion $apiVersion -Force -ErrorAction SilentlyContinue} catch { }
        try  { $SqlDatabase = New-AzureRmResource -ResourceName $databaseResource -Location $Global:AzureStackConfig.ArmLocation -ResourceGroupName $ResourceGroupName -ResourceType $dbResourceType -PropertyObject $SqlDatabaseProperties -ApiVersion $apiVersion -Force -ErrorAction SilentlyContinue } catch { }

        $ErrorActionPreference='Stop'
        Write-Verbose "Created sql database successfully"
        return
    }

    $deploymentId = [Guid]::NewGuid().ToString()
    $templateLink = Get-NewSqlDatabaseNewServerTemplate -Token $Token

    New-ResourceGroup  -ResourceGroupName $ResourceGroupName -SubscriptionID $SubscriptionID -Token $Token

    $createSqlDbRequest = @{
        Uri = "{0}subscriptions/{1}/resourcegroups/{2}/deployments/{3}?api-version=1.0" -f $Global:AzureStackConfig.AdminUri, $SubscriptionId, $ResourceGroupName, $deploymentId
        Method = "PUT"
        Headers = @{ "Authorization" = "Bearer "+ $Token }
        ContentType = "application/json"
    }

    $sqlUri = "{0}subscriptions/{1}/resourcegroups/{2}/deployments/{3}?api-version=1.0" -f $Global:AzureStackConfig.AdminUri, $SubscriptionId, $ResourceGroupName, $deploymentId
    $sqlHeaders = @{ "Authorization" = "Bearer "+ $Token }
    $sqlContentType = "application/json"

    $SqlDatabaseRequestBody = [pscustomobject]@{
    properties =
        @{
            templateLink = @{ uri = $templateLink }
            mode = "incremental"
            parameters = @{
                collation = @{value = "SQL_Latin1_General_CP1_CI_AS"}
                databaseName = @{value = $DatabaseName}
                edition = @{ value ="Web" }
                serverName = @{ value = $DatabaseName}
                administratorLogin = @{ value = $DatabaseName}
                administratorLoginPassword = @{ value = "test@123" }
                location = @{value= $Global:AzureStackConfig.ArmLocation}
            }
        }
    }
    #$SqlDatabaseRequestBody | ConvertTo-Json -Depth 6 | Invoke-RestMethod $createSqlDbRequest

    $sqlJson = $SqlDatabaseRequestBody | ConvertTo-Json -Depth 6
    $createdDb = Invoke-RestMethod -Method Put -Uri $sqlUri -Headers $sqlHeaders -ContentType $sqlContentType -Body $sqlJson

    Write-Verbose "Create sql database deployment request created successfully"
    Start-Sleep -Seconds 30

    Write-Verbose "checking on the deployment status"
    $result = Retry-Function  -scriptBlock { return (Get-DeploymentStatus  -ResourceGroupName $ResourceGroupName -DeploymentName $deploymentId -SubscriptionId $SubscriptionId -Token $Token) -ieq "Succeeded" } -argument $null -maxTries 20 -interval 10

    Assert-True -script {$result} -message "Create Database deployment request fired successfully, but the status of the db provisioning is not suceeeded"
    Write-Verbose "Deployment succeeded. The database '$DatabaseName' is created"

}

function Remove-SqlDatabase
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $SqlDatabaseId,

        [Parameter(Mandatory=$true)]
        [string] $Token
    )

    Write-Verbose "Deleting Sql Database : '$DatabaseName'"

    if ($Global:AzureStackConfig.IsAad)
    {
        #$dbId = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Sql/servers/{2}/databases/{3}" -f $Global:AzureStackConfig.SubscriptionId, $ResourceGroupName, $LogicalServerName, $DatabaseName
        try {Remove-AzureRmResource -ResourceId $SqlDatabaseId -Force} catch {}
        return
    }

    $deleteSqlDb = @{
    Uri = "{0}{1}?api-version=2.0" -f $Global:AzureStackConfig.AdminUri, $SqlDatabaseId
    Method = "DELETE"
    Headers = @{ "Authorization" = "Bearer "+ $Token }
    ContentType = "application/json"
    }

    Invoke-RestMethod @deleteSqlDb

    Write-Verbose "Successfully Delete Sql Database request fired: '$DatabaseName'"
}

function Remove-SqlLogicalServer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $SqlLogicalServerId,

        [Parameter(Mandatory=$true)]
        [string] $Token
    )

    if ($Global:AzureStackConfig.IsAad)
    {
        Remove-AzureRmResource -ResourceId $SqlLogicalServerId -Force
        return
    }

    $deleteSqlLogicalServer = @{
    Uri = "{0}{1}?api-version=2.0" -f $Global:AzureStackConfig.AdminUri, $SqlLogicalServerId
    Method = "DELETE"
    Headers = @{ "Authorization" = "Bearer "+ $Token }
    ContentType = "application/json"
    }

    Invoke-RestMethod @deleteSqlLogicalServer
}
