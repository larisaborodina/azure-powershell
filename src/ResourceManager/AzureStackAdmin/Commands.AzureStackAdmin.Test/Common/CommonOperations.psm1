function Get-ResourceProviderRegistration
{
    if ($Global:AzureStackConfig.IsAAD)
    {
        $providers = Get-AzureRMResourceProviderRegistration -ResourceGroup $systemResourceGroup
    }
    else
    {
        $providers = Get-AzureRMResourceProviderRegistration -ResourceGroup $systemResourceGroup -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token -ApiVersion $ApiVersion
    }

    return $providers
}

function Get-SQLRPDefaultQuota
{
    param
    (
       [Switch] $StrongTypedObject
    )

    $ApiVersion = "1.0"
    $providerNamespace = "Microsoft.Sql"
    $systemResourceGroup = "System"

    # TODO:  Make quotas parameterized when needed
    $defaultQuotaSettings = @{}
    $editions = @()
    $quota = @{}
    $quota.maxDatabaseSize = 1024
    $quota.maxDatabaseCount = 10000
    $quota.name = "Web"
    $quota.displayName = "Web"
    $quota.baseDatabaseSize = 10
    $editions += $quota
    $defaultQuotaSettings.editions = $editions

    $providers = Get-ResourceProviderRegistration
    $sqlProvider = $providers.Properties | Where-Object {$_.Manifest.Namespace -eq $providerNamespace }

    if ($StrongTypedObject)
    {
       return [Microsoft.AzureStack.Management.Models.ServiceQuotaDefinition]@{
         Location = "redmond"
         QuotaSyncState = "InSync"
         ResourceProviderId = "SQL-REDMOND"
         ResourceProviderNameSpace = "Microsoft.Sql"
         ResourceProviderDisplayName = "Sql"
         QuotaSettings = $defaultQuotaSettings | ConvertTo-Json
       }
    }
    else {
       $sqlDefaultQuota = [PSCustomObject]@{
         Location = "redmond"
         QuotaSyncState = "InSync"
         ResourceProviderId = "SQL-REDMOND"
         ResourceProviderNameSpace = "Microsoft.Sql"
         ResourceProviderDisplayName = "Sql"
         QuotaSettings = $defaultQuotaSettings
       }

       return $sqlDefaultQuota
    }
}

function Get-SubscriptionsDefaultQuota
{
    $ApiVersion = "1.0"
    $providerNamespace = "Microsoft.Subscriptions"
    $systemResourceGroup = "System"

    # TODO:  Make quotas parameterized when needed
    $defaultQuotaSettings = @{}
    $delegatedProviderQuotas = @{
        maximumDelegationDepth = 2
        allowCustomPortalBranding = $false
        allowResourceProviderRegistration = $false
        delegatedOffers=@()
    }

    $defaultQuotaSettings.delegatedProviderQuotas = $delegatedProviderQuotas

    $providers = Get-ResourceProviderRegistration
    $subscriptionsProvider = $providers.Properties | Where-Object {$_.Manifest.Namespace -eq $providerNamespace }

    $subscriptionsDefaultQuota = [PSCustomObject]@{
        location = $subscriptionsProvider.Location
        quotaSyncState = "InSync"
        resourceProviderDisplayName = ""
        resourceProviderId = $subscriptionsProvider.Name
        resourceProviderNameSpace = $subscriptionsProvider.Manifest.Namespace
        quotaSettings = $defaultQuotaSettings
    }

   return $subscriptionsDefaultQuota
}

function Get-SubscriptionsQuota
{
    param
    (
        [Parameter(Mandatory=$false)]
        [String[]] $DelegatedOfferNames
    )

    $quota = Get-SubscriptionsDefaultQuota

    $delegatedOffers=@()
    foreach ($offerName in $DelegatedOfferNames)
    {
        $delegatedOffers +=  @{
                                   offerName = $offerName
                                   accessibilityState = "Private"
                              }
    }

    # TODO: Add this when needed
    #$quota.quotaSettings["delegatedProviderQuotas"].maximumDelegationDepth = $DelegationDepth

    $quota.quotaSettings["delegatedProviderQuotas"].delegatedOffers += $delegatedOffers

    Write-Output $quota
}

function Get-StorageDefaultQuota
{
    $ApiVersion = "1.0"
    $providerNamespace = "Microsoft.Storage"
    $systemResourceGroup = "System"

    $defaultQuotaSettings = @{
        maxCapacityInGB = 500
        maxStorageAccounts = 20
    }
    
    $providers = Get-ResourceProviderRegistration    
    $subscriptionsProvider = $providers.Properties | Where-Object {$_.Manifest.Namespace -eq $providerNamespace }

    $defaultQuota = @{
        location = $subscriptionsProvider.Location
        quotaSyncState = "InSync"
        resourceProviderDisplayName = ""
        resourceProviderId = $subscriptionsProvider.Name
        resourceProviderNameSpace = $subscriptionsProvider.Manifest.Namespace
        quotaSettings = $defaultQuotaSettings
    }

   Write-Output $defaultQuota
}


function Get-NetworkDefaultQuota
{
    $ApiVersion = "1.0"
    $providerNamespace = "Microsoft.Network"
    $systemResourceGroup = "System"

    $defaultQuotaSettings = @{
        egressMaxBandwdith = 100
        egressReservedBandwidth = 25
        ingressMaxBandwith = 10
        virtualNetworks = 25
        publicIPAddresses = 5
        gateways = 2
        networkInterfaces = 100
    }

    $providers = Get-ResourceProviderRegistration
    $subscriptionsProvider = $providers.Properties | Where-Object {$_.Manifest.Namespace -eq $providerNamespace }

    $defaultQuota = @{
        location = $subscriptionsProvider.Location
        quotaSyncState = "InSync"
        resourceProviderDisplayName = ""
        resourceProviderId = $subscriptionsProvider.Name
        resourceProviderNameSpace = $subscriptionsProvider.Manifest.Namespace
        quotaSettings = $defaultQuotaSettings
    }

   Write-Output $defaultQuota
}

function Get-ComputeDefaultQuota
{
    $ApiVersion = "1.0"
    $providerNamespace = "Microsoft.Compute"
    $systemResourceGroup = "System"
    $name = [System.Guid]::NewGuid().ToString()

    $defaultQuotaSettings = @{
          numberOfVMs = -1
          amountOfMemory = -1
          numberOfCPUs= -1
          name= $name
    }

    $providers = Get-ResourceProviderRegistration
    $subscriptionsProvider = $providers.Properties | Where-Object {$_.Manifest.Namespace -eq $providerNamespace }

    $defaultQuota = @{
        location = $subscriptionsProvider.Location
        quotaSyncState = "InSync"
        resourceProviderDisplayName = ""
        resourceProviderId = $subscriptionsProvider.Name
        resourceProviderNameSpace = $subscriptionsProvider.Manifest.Namespace
        quotaSettings = $defaultQuotaSettings
    }

   Write-Output $defaultQuota
}

function Set-Offer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [PSObject] $Offer,

        [Parameter(Mandatory=$true)]
        [String] $ResourceGroup,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Public", "Private", "Decommissioned")]
        [String] $State
    )

    $Offer.properties.state = $State
    if ($Global:AzureStackConfig.IsAAD)
    {
        $Offer | Set-AzureRMOffer -ResourceGroup $ResourceGroup  
    }
    else
    {
        $Offer | Set-AzureRMOffer -ResourceGroup $ResourceGroup -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token -ApiVersion $Global:AzureStackConfig.ApiVersion
    }

    Write-Verbose "$Offer state got updated to $State"
}

function Set-Plan
{
    param
    (
        [Parameter(Mandatory=$true)]
        [PSObject] $Plan,

        [Parameter(Mandatory=$true)]
        [String] $ResourceGroup,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Public", "Private", "Decommissioned")]
        [String] $State
    )

    $Plan.properties.state = $State

    if ($Global:AzureStackConfig.IsAAD)
    {
        $Plan | Set-AzureRMPlan -ResourceGroup $ResourceGroup -SubscriptionId $Global:AzureStackConfig.SubscriptionId
    }
    else
    {
        $Plan | Set-AzureRMPlan -ResourceGroup $ResourceGroup -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token -ApiVersion $Global:AzureStackConfig.ApiVersion
    }

    Write-Verbose "$Plan state got updated to $State"
}

function Get-ServiceQuotas
{
    param
    (
        [Parameter(Mandatory=$false)]
        [String[]] $rpServices,

        [Parameter(Mandatory=$false)]
        [String[]] $DelegatedOfferNames,

        [Switch] $StrongTypedObject
    )

    $serviceQuotas = @()
    $serviceNames = $rpServices -split ","
    foreach ($service in $serviceNames)
    {
       switch($service)
       {
            "Microsoft.Sql" { 
			    if ($StrongTypedObject)
			    {
			       $serviceQuotas += Get-SQLRPDefaultQuota -StrongTypedObject
			    } else {
			       $serviceQuotas += Get-SQLRPDefaultQuota
			    }
            } 
            "Microsoft.Subscriptions" { $serviceQuotas += Get-SubscriptionsQuota -DelegatedOfferNames $DelegatedOfferNames }
            "Microsoft.Storage" { $serviceQuotas +=  Get-StorageDefaultQuota }
            "Microsoft.Network" { $serviceQuotas +=  Get-NetworkDefaultQuota }
            "Microsoft.Compute" { $serviceQuotas +=  Get-ComputeDefaultQuota }
            Default { "Wrong service name provided" }
       }
    }

    return $serviceQuotas
}

function New-Plan
{
    param
    (
        [Alias("Name")]
        [Parameter(Mandatory=$true)]
        [String] $PlanName,

        [Parameter(Mandatory=$true)]
        [String[]] $Services,

        [Parameter(Mandatory=$true)]
        [String] $ResourceGroupName,

        [String[]] $DelegatedOfferNames
    )

    Write-Verbose "Creating the plan: $PlanName"

    $name = [System.Guid]::NewGuid().ToString()

    $putPlan = @{
        Uri = $Global:AzureStackConfig.AdminUri + "subscriptions/" + $Global:AzureStackConfig.SubscriptionId + "/resourcegroups/${ResourceGroupName}/providers/Microsoft.Subscriptions/plans/${PlanName}?api-version=1.0"
        Method = "PUT"
        Headers = @{ "Authorization" = "Bearer " + $Global:AzureStackConfig.Token }
        ContentType = "application/json"
    }

    $serviceQuotas = Get-ServiceQuotas  -rpServices $Services -DelegatedOfferNames $DelegatedOfferNames
    $rpServiceQuotas = @($serviceQuotas)

    $planRequestBody = [pscustomobject]@{
        name = $PlanName
        location = $Global:AzureStackConfig.ArmLocation
        tags = @{}
        type = "Microsoft.Subscriptions/plans"
        properties = [pscustomobject]@{
               displayName = $PlanName
               name = $PlanName
               quotaSyncState = "InSync"
               state = "Private"
               serviceQuotas = $rpServiceQuotas
            }
    }

    # Make the API call
    $planCreated = $planRequestBody | ConvertTo-Json -Depth 7 | Invoke-RestMethod @putPlan
    Write-Verbose "Plan created successfully: $PlanName"

    $plan = Get-Plan -PlanName $PlanName -ResourceGroupName $ResourceGroupName

    Assert-NotNull $plan
    Assert-True { $plan.Properties.DisplayName -eq  $PlanName}

    Write-Output $plan
}

# TODO: pass subscription id when needed
function Remove-Plan
{
 param
    (
        [Alias("Name")]
        [Parameter(Mandatory=$true)]
        [String] $PlanName,

        [Parameter( Mandatory=$true)]
        [String] $ResourceGroupName
    )

    if ($Global:AzureStackConfig.IsAAD)
    {
        Remove-AzureRMPlan -Name $PlanName -ResourceGroup $ResourceGroupName -SubscriptionId $Global:AzureStackConfig.SubscriptionId 
    }
    else
    {
        Remove-AzureRMPlan -Name $PlanName -ResourceGroup $ResourceGroupName -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token -ApiVersion $Global:AzureStackConfig.ApiVersion
    }
    
    Assert-ResourceDeletion {Get-Plan -PlanName $PlanName -ResourceGroupName $ResourceGroupName}

    Write-Verbose "Deleted the plan successfully: $PlanName"
}

# TODO: pass subscription id when needed
function Get-Plan
{
 param
    (
        [Alias("Name")]
        [Parameter(Mandatory=$true)]
        [String] $PlanName,

        [Parameter(Mandatory=$true)]
        [String] $ResourceGroupName
    )

    if ($Global:AzureStackConfig.IsAAD)
    {
        return Get-AzureRMPlan -Name $PlanName -SubscriptionId $AzureStackConfig.SubscriptionId -ResourceGroup $ResourceGroupName -Managed 
    }
    else
    {
        return Get-AzureRMPlan -Name $PlanName -AdminUri $AzureStackConfig.AdminUri -Token $AzureStackConfig.Token -ApiVersion $AzureStackConfig.ApiVersion -SubscriptionId $AzureStackConfig.SubscriptionId -ResourceGroup $ResourceGroupName -Managed
    }
}

# TODO: pass subscripion id when needed
function New-Offer
{
 param
    (
        [Alias("Name")]
        [Parameter(Mandatory=$false)]
        [String] $OfferName,

        # TODO: allow multiple base plans when needed
        [Parameter(Mandatory=$false)]
        [PSObject] $BasePlan,

        [Parameter(ValueFromPipeline=$true, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [String] $ResourceGroupName
    )

    if ($Global:AzureStackConfig.IsAAD)
    {
        $offer = New-AzureRMOffer -Name $OfferName -DisplayName $OfferName -State Private -BasePlans @($BasePlan) -ArmLocation $AzureStackConfig.ArmLocation -ResourceGroup $ResourceGroupName -SubscriptionId $AzureStackConfig.SubscriptionId
    }
    else
    {
        $offer = New-AzureRMOffer -Name $OfferName -DisplayName $OfferName -State Private -BasePlans @($BasePlan) -ArmLocation $AzureStackConfig.ArmLocation -ResourceGroup $ResourceGroupName -SubscriptionId $AzureStackConfig.SubscriptionId -Token $AzureStackConfig.Token -AdminUri $AzureStackConfig.AdminUri -ApiVersion $AzureStackConfig.ApiVersion
    }

    Assert-NotNull $offer
    Assert-True {$offer.Properties.DisplayName -eq  $OfferName}

    return $offer
}

function Remove-Offer
{
 param
    (
        [Alias("Name")]
        [Parameter(Mandatory=$true)]
        [String] $OfferName,

        [Parameter( Mandatory=$true)]
        [String] $ResourceGroupName
    )
    if ($Global:AzureStackConfig.IsAAD)
    {
        $offer = Remove-AzureRMOffer -Name $OfferName -ResourceGroup $ResourceGroupName -SubscriptionId $Global:AzureStackConfig.SubscriptionId
    }
    else
    {
        $offer = Remove-AzureRMOffer -Name $OfferName -ResourceGroup $ResourceGroupName -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token -ApiVersion $Global:AzureStackConfig.ApiVersion
    }

    Assert-ResourceDeletion {Get-Offer -OfferName $OfferName -ResourceGroupName $ResourceGroupName}

    Write-Verbose "Deleted the offer successfully: $OfferName"
}

function Get-Offer
{
 param
    (
        [Alias("Name")]
        [Parameter(Mandatory=$true, ParameterSetName="Admin")]
        [Parameter(Mandatory=$true, ParameterSetName="Tenant")]
        [String] $OfferName,

        [Parameter(Mandatory=$true, ParameterSetName="Admin")]
        [String] $ResourceGroupName,

        [Parameter(Mandatory=$true, ParameterSetName="Tenant")]
        [String] $Token
    )

    switch ($PsCmdlet.ParameterSetName)
    {
        "Admin"
        {
            if ($Global:AzureStackConfig.IsAAD)
            {
                return Get-AzureRMOffer -Name $OfferName -SubscriptionId $AzureStackConfig.SubscriptionId -ResourceGroup $ResourceGroupName -Managed
            }
            else
            {
                return Get-AzureRMOffer -Name $OfferName -AdminUri $AzureStackConfig.AdminUri -Token $AzureStackConfig.Token -ApiVersion $AzureStackConfig.ApiVersion -SubscriptionId $AzureStackConfig.SubscriptionId -ResourceGroup $ResourceGroupName -Managed
            }
        }
        "Tenant"
        {
            if ($Global:AzureStackConfig.IsAAD)
            {
                return Get-AzureRMOffer -Provider "default" | where name -eq $OfferName
            }
            else
            {
                return Get-AzureRMOffer -Provider "default" -AdminUri $AzureStackConfig.AdminUri -Token $Token -ApiVersion $AzureStackConfig.ApiVersion | where name -eq $OfferName
            }
            #ToDo- Not to hardcode default
        }
    }
}

function New-Subscription
{
    param
    (
        [Parameter(Mandatory=$true, ParameterSetName="Admin")]
        [Parameter(Mandatory=$true, ParameterSetName="Tenant")]
        [String] $SubscriptionUser,

        [Parameter(Mandatory=$true, ParameterSetName="Admin")]
        [Parameter(Mandatory=$true, ParameterSetName="Tenant")]
        [String] $OfferId,

        [Parameter(Mandatory=$true, ParameterSetName="Tenant")]
        [String] $Token
    )

    Write-Verbose "Creating the subscription for the user : $SubscriptionUser"
    $subDisplayName = "$SubscriptionUser Test User"

    switch ($PsCmdlet.ParameterSetName)
    {
        "Admin"
        {
            if ($Global:AzureStackConfig.IsAAD)
            {
                $subscription = New-AzureRmManagedSubscription -Owner $SubscriptionUser -OfferId $OfferId -DisplayName $subDisplayName -SubscriptionId $Global:AzureStackConfig.SubscriptionId
            }
            else
            {
                $subscription = New-AzureRmManagedSubscription -Owner $SubscriptionUser -OfferId $OfferId -DisplayName $subDisplayName -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token -ApiVersion $Global:AzureStackConfig.ApiVersion
            }
            $Token = $Global:AzureStackConfig.Token
        }
        "Tenant"
        {
            if ($Global:AzureStackConfig.IsAAD)
            {
                $subscription = New-AzureRmTenantSubscription -Owner $SubscriptionUser -OfferId $OfferId -DisplayName $subDisplayName
            }
            else
            {
                $subscription = New-AzureRmTenantSubscription -Owner $SubscriptionUser -OfferId $OfferId -DisplayName $subDisplayName -AdminUri $Global:AzureStackConfig.AdminUri -Token $token -ApiVersion $Global:AzureStackConfig.ApiVersion
            }
        }
    }

    Assert-True { $subscription.DisplayName -eq $subDisplayName } | Out-Null
    $Global:CreatedSubscriptions += @{
        SubscriptionId = $subscription.SubscriptionId
        Token = $Token
        }

    Retry-Function -ScriptBlock {(Get-AzureRmManagedSubscription -TargetSubscriptionId $subscription.SubscriptionId -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token).QuotaSyncState -ieq "InSync"} -MaxTries 12 -IntervalInSeconds 5 | Out-Null

    Write-Verbose "Successfully created the subscription for user : $SubscriptionUser"
    return $subscription
}

function Get-Subscription
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $SubscriptionId
    )

    if ($Global:AzureStackConfig.IsAAD)
    {
        return AzureRm.AzureStackAdmin\Get-AzureRmManagedSubscription -TargetSubscriptionId $SubscriptionId
    }
    else
    {
        return AzureRm.AzureStackAdmin\Get-AzureRmManagedSubscription -TargetSubscriptionId $SubscriptionId -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token -ApiVersion $Global:AzureStackConfig.ApiVersion
    }
}

function Remove-Subscription
{
   param
   (
       [Parameter(Mandatory=$true)]
       [String] $TargetSubscriptionId
   )
    Write-Verbose "Deleting the subscription : $TargetSubscriptionId"

    $subscription = Get-Subscription -SubscriptionId $TargetSubscriptionId
    $subscription.State = "disabled"

    if ($Global:AzureStackConfig.IsAAD)
    {
        Set-AzureRMManagedSubscription -Subscription $subscription
        Retry-Function -ScriptBlock {(Get-AzureRmManagedSubscription -TargetSubscriptionId $subscription.SubscriptionId).QuotaSyncState -ieq "InSync"} -MaxTries 12 -IntervalInSeconds 5
        Remove-AzureRmManagedSubscription -TargetSubscriptionId $TargetSubscriptionId
    }
    else
    {
        Set-AzureRMManagedSubscription -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token -Subscription $subscription 
        Retry-Function -ScriptBlock {(Get-AzureRmManagedSubscription -TargetSubscriptionId $subscription.SubscriptionId -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token).QuotaSyncState -ieq "InSync"} -MaxTries 12 -IntervalInSeconds 5
        Remove-AzureRmManagedSubscription -TargetSubscriptionId $TargetSubscriptionId -SubscriptionId $Global:AzureStackConfig.SubscriptionId -AdminUri $Global:AzureStackConfig.AdminUri -Token $Global:AzureStackConfig.Token -ApiVersion $Global:AzureStackConfig.ApiVersion
    }
    
    Assert-SubscriptionDeletion {Get-Subscription -SubscriptionId $TargetSubscriptionId}
    Write-Verbose "Successfully deleted the subscription : $TargetSubscriptionId"
}

function Get-TenantPublicOffers
{
 param
    (
        [Parameter(Mandatory=$true)]
        [String] $Token
    )

    #ToDo- Not to hardcode default
    if ($Global:AzureStackConfig.IsAAD)
    {
        return Get-AzureRMOffer -Provider "default"
    }
    else
    {
        return Get-AzureRMOffer -Provider "default" -AdminUri $Global:AzureStackConfig.AdminUri -Token $Token -ApiVersion $AzureStackConfig.ApiVersion
    }
}

function Get-Subscriptions
{
    param
    (
        [Parameter( Mandatory=$true)]
        [String] $Token
    )

    $getSubscriptions = @{
        Uri = $Global:AzureStackConfig.AdminUri + "subscriptions?api-version=2014-04-01-preview"
        Method = "GET"
        Headers = @{ "Authorization" = "Bearer " + $Token }
        ContentType = "application/json"
    }

    $subscriptions = Invoke-RestMethod @getSubscriptions

    return $subscriptions.value
}

function Get-DeploymentStatus
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] $DeploymentName,

        [Parameter(Mandatory=$true)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory=$true)]
        [string] $SubscriptionId,

        [Parameter(Mandatory=$true)]
        [string] $Token
    )

    $deploymentUri = "{0}subscriptions/{1}/resourcegroups/{2}/deployments/{3}?api-version=1.0" -f  $Global:AzureStackConfig.AdminUri, $SubscriptionId, $ResourceGroupName, $DeploymentName
    $deploymentHeaders = @{ "Authorization" = "Bearer "+ $Token }
    $deploymentContentType = "application/json"

    $deploymentResponse = Invoke-RestMethod -Method Get -Uri $deploymentUri -Headers $deploymentHeaders -ContentType $deploymentContentType

    return $deploymentResponse.properties.provisioningState
}

