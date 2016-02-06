<#
.Synopsis
   Test the flow of Admin user creates a plan, offer and a tenant subscription for the specified user and deletes the created resources
   The plan and offer contains the Subscriptions and Sql services by default.
.EXAMPLE
    This example creates the subscription  with a new plan and offer. It deletes the created resources as well
    Test-TenantSubscription -SubscriptionUser "azurestackmachine\tenantuser1"

.EXAMPLE
    This example creates the subscription  with a new plan and offer. It does not delete the created resources
    Test-TenantSubscription -SubscriptionUser "azurestackmachine\tenantuser1" -DoNotDelete
.EXAMPLET
    This example creates the reseller subscription  with a new plan and offer. It deletes the created resources as well
    Test-TenantSubscription -Services @("Microsoft.Subscriptions") -SubscriptionUser "azurestackmachine\tenantuser1"
.NOTES
     The function is called only after Ignore-SelfSignedCert and Set-AzureStackEnvironment with the correct parameters
#>
function Test-TenantSubscription
{
    param
    (
        # Specifies the user name for the subscription
        [Parameter(Mandatory=$true)]
        [String] $SubscriptionUser,

        [String] $OfferName,

        [String] $BasePlanName,

        [String] $ResourceGroupName,

        [ValidateSet("Public", "Private", "Decommissioned")]
        [String] $State = "Public",

        # Specifies the services included in the plan, offer and subscription
        [String[]] $Services=@("Microsoft.Subscriptions","Microsoft.Sql"),

        # Specifies whether to delete the created resources
        [Switch] $DoNotDelete
    )

    if (!$OfferName)
    {
        $OfferName = "TestOffer-"  + [Guid]::NewGuid().ToString()
    }

    if (!$BasePlanName)
    {
        $BasePlanName = "TestPlan-"  + [Guid]::NewGuid().ToString()
    }

    if (!$ResourceGroupName)
    {
        $ResourceGroupName = "TestRG-" + [Guid]::NewGuid().ToString()
    }

    New-ResourceGroup -ResourceGroupName $ResourceGroupName

    New-Plan -PlanName $BasePlanName -ResourceGroupName $ResourceGroupName -Services $Services
    $plan = Get-Plan -PlanName $BasePlanName -ResourceGroupName $ResourceGroupName

    Assert-NotNull $plan
    Assert-True { $plan.Properties.DisplayName -eq  $BasePlanName}

    Set-Plan -Plan $plan -ResourceGroup $ResourceGroupName -State $State

    New-Offer -OfferName $offerName -BasePlan $plan -ResourceGroupName $ResourceGroupName

    $offer = Get-Offer -OfferName $offerName -ResourceGroupName $ResourceGroupName
    # call made https://<>:30005/subscriptions/a0ebe67a-ac93-4cea-9275-cb4e7cc15b86/resourcegroups/TestRG-a4a39db7-89af-42ee-a865-3f50cab74fae/providers/Microsoft.Subscriptions/offers/TestOffer-426c1a72-125c-4ee1-a687-950781150e5f?api-version=1.0
    # Offer ID returned by the previous call is id=/subscriptions/a0ebe67a-ac93-4cea-9275-cb4e7cc15b86/resourceGroups/TestRG-a4a39db7-89af-42ee-a865-3f50cab74fae/providers/Microsoft.Subscriptions/offers/TestOffer-426c1a72-125c-4ee1-a687-950781150e5f

    Assert-NotNull $offer
    Assert-True { $offer.Properties.DisplayName -eq  $offerName}

    Set-Offer -Offer $offer -ResourceGroup $ResourceGroupName -State "Public"

    $publicOffer = Get-Offer -OfferName $offerName -Token $AzureStackConfig.Token

    $subscription = New-Subscription -SubscriptionUser $SubscriptionUser -OfferId $publicOffer.Id

    Set-Offer -Offer $offer -ResourceGroup $ResourceGroupName -State $State

    if (!$DoNotDelete)
    {
        Remove-Subscription -TargetSubscriptionId $subscription.SubscriptionId
        Remove-Offer -OfferName $offerName -ResourceGroupName $ResourceGroupName
        Remove-Plan -PlanName $BasePlanName -ResourceGroupName $ResourceGroupName
        Remove-ResourceGroup -ResourceGroupName $ResourceGroupName
    }
}

<#
.Synopsis
   Acquire token as Tenant user and then subscribe to offer and deletes the created plan, offer, subscription resources
   The plan and offer contains the Subscriptions and Sql services by default.
.EXAMPLE
    This example creates the subscription  with a new plan and offer. It deletes the created resources as well
    Test-TenantSubscribeToOffer -SubscriptionUser "azurestackmachine\tenantuser1"  -UserPassword $password

.EXAMPLE
    This example creates the subscription  with a new plan and offer. It does not delete the created resources
    Test-TenantSubscribeToOffer -SubscriptionUser "azurestackmachine\tenantuser1" -UserPassword $password -DoNotDelete
.EXAMPLE
    This example creates the reseller subscription  with a new plan and offer. It deletes the created resources as well
    Test-TenantSubscribeToOffer -Services @("Microsoft.Subscriptions") -SubscriptionUser "azurestackmachine\tenantuser1" -UserPassword $password
.NOTES
     The function is called only after Ignore-SelfSignedCert and Set-AzureStackEnvironment with the correct parameters
#>
function Test-TenantSubscribeToOffer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $SubscriptionUser,

        [Parameter(Mandatory=$true)]
        [String] $UserPassword,

        [String[]] $Services=@("Microsoft.Subscriptions","Microsoft.Sql"),

        [Switch] $DoNotDelete
    )

    $offerName = "TestOffer-"  + [Guid]::NewGuid().ToString()
    $planName = "TestPlan-"  + [Guid]::NewGuid().ToString()
    $rgName = "TestRG-" + [Guid]::NewGuid().ToString()
    $subDisplayName = "$SubscriptionUser Test Subscription"

    New-ResourceGroup -ResourceGroupName $rgName

    New-Plan -PlanName $planName -ResourceGroupName $rgName -Services $Services
    $plan = Get-Plan -PlanName $planName -ResourceGroupName $rgName

    Assert-NotNull $plan
    Assert-True {$plan.Properties.DisplayName -eq  $planName}

    Set-Plan -Plan $plan -ResourceGroup $rgName -State "Public"

    New-Offer -OfferName $offerName -BasePlan $plan -ResourceGroupName $rgName
    $offer = Get-Offer -OfferName $offerName -ResourceGroupName $rgName

    Assert-NotNull $offer
    Assert-True { $offer.Properties.DisplayName -eq  $offerName}

    Set-Offer -Offer $offer -ResourceGroup $rgName -State "Public"

    $password = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($SubscriptionUser, $password)

    $token =  Get-EnvironmentSpecificToken -Credential $credential

    # Check whether the plan created is visible for the tenant
    $tenantOffer = Get-Offer -OfferName $offerName -Token $token

    # Creating a subscription with Tenant Token
    $subscription = New-Subscription -SubscriptionUser $SubscriptionUser -OfferId $tenantOffer.Id -Token $token

    if (!$DoNotDelete)
    {
        Remove-Subscription -TargetSubscriptionId $subscription.SubscriptionId
        Remove-Offer -OfferName $offerName -ResourceGroupName $rgName
        Remove-Plan -PlanName $planName -ResourceGroupName $rgName
        Remove-ResourceGroup -ResourceGroupName $rgName
    }
 }

 <#
.Synopsis
    Creates and Deletes a new plan. The plan contains the Subscriptions and Sql services by default.
.EXAMPLE
    This example creates and deletes a new plan
    Test-Plan
.EXAMPLE
    This example creates a plan named DefaultPlan and does not delete it
    Test-Plan -Services @("Microsoft.Subscriptions") -PlanName DefaultPlan -DoNotDelete
.NOTES
     The function is called only after Ignore-SelfSignedCert and Set-AzureStackEnvironment with the correct parameters
#>
function Test-Plan
{
    param
    (
        [Alias("Name")]
        [String] $PlanName,

        [String[]] $Services=@("Microsoft.Subscriptions","Microsoft.Sql"),

        [ValidateSet("Public", "Private", "Decommissioned")]
        [String] $State = "Public",

        [Switch] $DoNotDelete
    )

    if (!$PlanName)
    {
        $PlanName = "TestPlan-"  + [Guid]::NewGuid().ToString()
    }

    $rgName = "TestRG-" + [Guid]::NewGuid().ToString()

    New-ResourceGroup -ResourceGroupName $rgName

    New-Plan -PlanName $PlanName -ResourceGroupName $rgName -Services $Services

    $plan = Get-Plan -PlanName $PlanName -ResourceGroupName $rgName
    Assert-NotNull $plan
    Assert-True { $plan.Properties.DisplayName -eq  $PlanName}

    Set-Plan -Plan $plan -ResourceGroup $rgName -State $State

    if (!$DoNotDelete)
    {
        Remove-Plan -PlanName $PlanName -ResourceGroupName $rgName
        Remove-ResourceGroup -ResourceGroupName $rgName
    }
 }

 <#
.Synopsis
    Creates and Deletes a new offer and plan. The plan and offer contains the Subscriptions and Sql services by default.
.EXAMPLE
    This example creates and deletes a new plan and offer
    Test-Offer
.EXAMPLE
    This example creates a offer named DefaultOffer, a plan named DefaultPlan and does not delete them
    Test-Offer -Services @("Microsoft.Subscriptions") -OfferName DefaultOffer -BasePlanName DefaultPlan -DoNotDelete
.NOTES
     The function is called only after Ignore-SelfSignedCert and Set-AzureStackEnvironment with the correct parameters
#>
function Test-Offer
{
    param
    (
        [Alias("Name")]
        [String] $OfferName,

        [String] $BasePlanName,

        [String] $ResourceGroupName,

        [String[]] $Services=@("Microsoft.Subscriptions","Microsoft.Sql"),

        [ValidateSet("Public", "Private", "Decommissioned")]
        [String] $State = "Public",

        [Switch] $DoNotDelete
    )

    if (!$OfferName)
    {
        $OfferName = "TestOffer-"  + [Guid]::NewGuid().ToString()
    }

    if (!$BasePlanName)
    {
        $BasePlanName = "TestPlan-"  + [Guid]::NewGuid().ToString()
    }

    if (!$ResourceGroupName)
    {
        $ResourceGroupName = "TestRG-" + [Guid]::NewGuid().ToString()
    }

    New-ResourceGroup -ResourceGroupName $ResourceGroupName

    $plan = New-Plan -PlanName $BasePlanName -ResourceGroupName $ResourceGroupName -Services $Services
    $plan = Get-Plan -PlanName $BasePlanName -ResourceGroupName $ResourceGroupName
    Assert-NotNull $plan
    Assert-True { $plan.Properties.DisplayName -eq  $BasePlanName}
    Set-Plan -Plan $plan -ResourceGroup $ResourceGroupName -State $State

    New-Offer -OfferName $OfferName -BasePlan $plan -ResourceGroupName $ResourceGroupName

    $offer = Get-Offer -OfferName $OfferName -ResourceGroupName $ResourceGroupName

    Set-Offer -Offer $offer -ResourceGroup $ResourceGroupName -State $State

    if (!$DoNotDelete)
    {
        Remove-Offer -OfferName $OfferName -ResourceGroupName $ResourceGroupName
        Remove-Plan -PlanName $BasePlanName -ResourceGroupName $ResourceGroupName
        Remove-ResourceGroup -ResourceGroupName $ResourceGroupName
    }
}


<#
.Synopsis
    Creates an offer having public delegated offers. Creates a subscription for the user
.EXAMPLE
    This example creates and deletes a new plan and offer
    Test-Offer
.EXAMPLE
    This example creates a offer named DefaultOffer, a plan named DefaultPlan and does not delete them
    Test-Offer -Services @("Microsoft.Subscriptions") -OfferName DefaultOffer -BasePlanName DefaultPlan -DoNotDelete
.NOTES
     The function is called only after Ignore-SelfSignedCert and Set-AzureStackEnvironment with the correct parameters
#>
function Test-DelegatedOffer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $SubscriptionUser,

        [Parameter(Mandatory=$true)]
        [String] $UserPassword,

        [String[]] $Services=@("Microsoft.Subscriptions","Microsoft.Sql"),

        [Switch] $DoNotDelete
    )

    $delegatedOfferName = "TestOfferDelegated-"  + [Guid]::NewGuid().ToString()
    $delegatedPlanName = "TestPlanDelegated-"  + [Guid]::NewGuid().ToString()
    $offerName = "TestOffer-"  + [Guid]::NewGuid().ToString()
    $planName = "TestPlan-"  + [Guid]::NewGuid().ToString()

    $rgName = "TestRG-" + [Guid]::NewGuid().ToString()

    New-ResourceGroup -ResourceGroupName $rgName

    New-Plan -PlanName $delegatedPlanName -ResourceGroupName $rgName -Services $Services

    $delegatedPlan = Get-Plan -PlanName $delegatedPlanName -ResourceGroupName $rgName
    Assert-NotNull $delegatedPlan
    Assert-True {$delegatedPlan.Properties.DisplayName -eq  $delegatedPlanName}
    Set-Plan -Plan $delegatedPlan -ResourceGroup $rgName -State "Public"

    New-Offer -OfferName $delegatedOfferName -BasePlan $delegatedPlan -ResourceGroupName $rgName

    $delegatedOffer = Get-Offer -OfferName $delegatedOfferName -ResourceGroupName $rgName
    Assert-NotNull $delegatedOffer
    Set-Offer -Offer $delegatedOffer -ResourceGroup $rgName -State "Public"

    # Creating a plan having a delegated offer
    New-Plan -PlanName $planName -ResourceGroupName $rgName -Services $Services -DelegatedOfferName @($delegatedOfferName)

    $plan = Get-Plan -PlanName $planName -ResourceGroupName $rgName

    Assert-NotNull $plan
    Assert-True {$plan.Properties.DisplayName -eq  $planName}
    Set-Plan -Plan $plan -ResourceGroup $rgName -State "Public"

    New-Offer -OfferName $offerName -BasePlan $plan -ResourceGroupName $rgName

    $offer = Get-Offer -OfferName $offerName -ResourceGroupName $rgName
    Assert-NotNull $offer
    Set-Offer -Offer $offer -ResourceGroup $rgName -State "Public"

    $password = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($SubscriptionUser, $password)

    $token =  Get-EnvironmentSpecificToken -Credential $credential

    # Check whether the plan created is visible for the tenant
    $tenantOffer = Get-Offer -OfferName $offerName -Token $token
    $subDisplayName = "$SubscriptionUser Test Subscription"

    # Creating a subscription with Tenant Token
    $subscription = New-Subscription -SubscriptionUser $SubscriptionUser -OfferId $tenantOffer.Id -Token $token

    # Get the delegated offer, with the reseller token
    $resellerViewOffer = Get-Offer -OfferName $delegatedOfferName -Token $token
    Assert-NotNull $resellerViewOffer
    Assert-True { $resellerViewOffer.DisplayName -eq $delegatedOfferName }

    if (!$DoNotDelete)
    {
        Remove-Subscription -TargetSubscriptionId $subscription.SubscriptionId
        Remove-Offer -OfferName $delegatedOfferName -ResourceGroupName $rgName
        Remove-Plan -PlanName $delegatedPlanName -ResourceGroupName $rgName
        Remove-Offer -OfferName $OfferName -ResourceGroupName $rgName
        Remove-Plan -PlanName $PlanName -ResourceGroupName $rgName
        Remove-ResourceGroup -ResourceGroupName $rgName
    }
}

<#
.Synopsis
    Creates a new plan with Subscription service, then updates the Subscription service default quota
.NOTES
     The function is called only after Ignore-SelfSignedCert and Set-AzureStackEnvironment with the correct parameters
#>
function Test-UpdateSubscriptionServiceQuota
{
    param
    (
        [Switch] $AddDelegatedOffer
    )

    $sqlOfferName = "TestOfferSQL-"  + [Guid]::NewGuid().ToString()
    $sqlPlanName = "TestPlanSQL-"  + [Guid]::NewGuid().ToString()
    $resellerPlanName = "TestPlanReseller-" + [Guid]::NewGuid().ToString()

    $sqlServices= @("Microsoft.Sql")
    $subscriptionServices= @("Microsoft.Subscriptions")

    $rgName = "TestRG-" + [Guid]::NewGuid().ToString()

    New-ResourceGroup -ResourceGroupName $rgName

    New-Plan -PlanName $sqlPlanName -ResourceGroupName $rgName -Services $sqlServices

    $sqlPlan = Get-Plan -PlanName $sqlPlanName -ResourceGroupName $rgName
    Assert-NotNull $sqlPlan
    Assert-True {$sqlPlan.Properties.DisplayName -eq  $sqlPlanName}
    Set-Plan -Plan $sqlPlan -ResourceGroup $rgName -State "Public"

    New-Offer -OfferName $sqlOfferName -BasePlan $sqlPlan -ResourceGroupName $rgName

    $sqlOffer = Get-Offer -OfferName $sqlOfferName -ResourceGroupName $rgName
    Assert-NotNull $sqlOffer
    Set-Offer -Offer $sqlOffer -ResourceGroup $rgName -State "Public"

    # Creating a reseller plan having a delegated offer
    New-Plan -PlanName $resellerPlanName -ResourceGroupName $rgName -Services $subscriptionServices -DelegatedOfferName @($sqlOfferName)

    $resellerplan = Get-Plan -PlanName $resellerPlanName -ResourceGroupName $rgName

    Assert-NotNull $resellerplan
    Assert-True {$resellerplan.Properties.DisplayName -eq  $resellerPlanName}

    $subscriptionsQutoas = $resellerplan.Properties.ServiceQuotas[0].QuotaSettings | ConvertFrom-Json
    $subscriptionsQutoas.delegatedProviderQuotas[0].maximumDelegationDepth = 5
    $subscriptionsQutoas.delegatedProviderQuotas[0].delegatedOffers[0].accessibilityState = "Private"

    $resellerplan.Properties.ServiceQuotas[0].QuotaSettings = $subscriptionsQutoas | ConvertTo-Json -Depth 5

    Set-Plan -Plan $resellerplan -ResourceGroup $rgName -State "Public"

    $updatedResellerplan = Get-Plan -PlanName $resellerPlanName -ResourceGroupName $rgName
    $updatedSubscriptionsQutoas = $updatedResellerplan.Properties.ServiceQuotas[0].QuotaSettings | ConvertFrom-Json

    Assert-AreEqual -expected $updatedSubscriptionsQutoas.delegatedProviderQuotas[0].maximumDelegationDepth -actual $subscriptionsQutoas.delegatedProviderQuotas[0].maximumDelegationDepth
    Assert-AreEqual -expected $updatedSubscriptionsQutoas.delegatedProviderQuotas[0].delegatedOffers[0].accessibilityState -actual $subscriptionsQutoas.delegatedProviderQuotas[0].delegatedOffers[0].accessibilityState

    # Add additional delegated offer to the subscription service for the existing reseller plan
    if ($AddDelegatedOffer)
    {
        $sqlOfferName1 = "TestOfferSQL-"  + [Guid]::NewGuid().ToString()
        $sqlPlanName1 = "TestPlanSQL-"  + [Guid]::NewGuid().ToString()

        New-Plan -PlanName $sqlPlanName1 -ResourceGroupName $rgName -Services $sqlServices
        $sqlPlan = Get-Plan -PlanName $sqlPlanName1 -ResourceGroupName $rgName
        Set-Plan -Plan $sqlPlan -ResourceGroup $rgName -State "Public"

        New-Offer -OfferName $sqlOfferName1 -BasePlan $sqlPlan -ResourceGroupName $rgName
        $sqlOffer = Get-Offer -OfferName $sqlOfferName1 -ResourceGroupName $rgName
        Set-Offer -Offer $sqlOffer -ResourceGroup $rgName -State "Public"

        $planQuota = $updatedResellerplan.Properties.ServiceQuotas[0].QuotaSettings | ConvertFrom-Json
        $resellerQuotasObject = $updatedResellerplan.Properties.ServiceQuotas[0].QuotaSettings | ConvertFrom-Json
        $resellerQuotasObject.delegatedProviderQuotas[0].delegatedOffers[0].offerName = $sqlOfferName1

        $planQuota.delegatedProviderQuotas[0].delegatedOffers +=  $resellerQuotasObject.delegatedProviderQuotas[0].delegatedOffers[0]

        $updatedResellerplan.Properties.ServiceQuotas[0].QuotaSettings = $planQuota | ConvertTo-Json -Depth 5

        Set-Plan -Plan  $updatedResellerplan -ResourceGroup $rgName -State "Public"

        $delegatedOfferAddedplan = Get-Plan -PlanName $resellerPlanName -ResourceGroupName $rgName
        $expectedQutoas = $delegatedOfferAddedplan.Properties.ServiceQuotas[0].QuotaSettings | ConvertFrom-Json

        Assert-AreEqual -expected "2" -actual $expectedQutoas.delegatedProviderQuotas[0].delegatedOffers.Count

        Remove-Offer -OfferName $sqlOfferName1 -ResourceGroupName $rgName
        Remove-Plan -PlanName $sqlPlanName1 -ResourceGroupName $rgName
    }

    Remove-Offer -OfferName $sqlOfferName -ResourceGroupName $rgName
    Remove-Plan -PlanName $sqlPlanName -ResourceGroupName $rgName
    Remove-Plan -PlanName $resellerPlanName -ResourceGroupName $rgName

    Remove-ResourceGroup -ResourceGroupName $rgName
}

<#
.Synopsis
    Creates a new plan with Subscription service, then add a sql service to the plan
.NOTES
     The function is called only after Ignore-SelfSignedCert and Set-AzureStackEnvironment with the correct parameters
#>
function Test-AddServiceToPlan
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String] $SubscriptionUser,

        [Parameter(Mandatory=$true)]
        [String] $UserPassword
    )

    $sqlOfferName = "TestOfferSQL-"  + [Guid]::NewGuid().ToString()
    $sqlPlanName = "TestPlanSQL-"  + [Guid]::NewGuid().ToString()
    $resellerPlanName = "TestPlanReseller-" + [Guid]::NewGuid().ToString()
    $resellerOfferName = "OfferReseller-" + [Guid]::NewGuid().ToString()

    $sqlServices= @("Microsoft.Sql")
    $subscriptionServices= @("Microsoft.Subscriptions")

    $rgName = "TestRG-" + [Guid]::NewGuid().ToString()

    New-ResourceGroup -ResourceGroupName $rgName

    New-Plan -PlanName $sqlPlanName -ResourceGroupName $rgName -Services $sqlServices

    $sqlPlan = Get-Plan -PlanName $sqlPlanName -ResourceGroupName $rgName
    Assert-NotNull $sqlPlan
    Assert-True {$sqlPlan.Properties.DisplayName -eq  $sqlPlanName}
    Set-Plan -Plan $sqlPlan -ResourceGroup $rgName -State "Public"

    New-Offer -OfferName $sqlOfferName -BasePlan $sqlPlan -ResourceGroupName $rgName

    $sqlOffer = Get-Offer -OfferName $sqlOfferName -ResourceGroupName $rgName
    Assert-NotNull $sqlOffer
    Set-Offer -Offer $sqlOffer -ResourceGroup $rgName -State "Public"

    # Creating a reseller plan having a delegated offer
    New-Plan -PlanName $resellerPlanName -ResourceGroupName $rgName -Services $subscriptionServices -DelegatedOfferName @($sqlOfferName)

    $resellerplan = Get-Plan -PlanName $resellerPlanName -ResourceGroupName $rgName
    Set-Plan -Plan $resellerplan -ResourceGroup $rgName -State "Public"

    # Create a reseller Offer
    New-Offer -OfferName $resellerOfferName -BasePlan $resellerplan -ResourceGroupName $rgName

    $resellerOffer = Get-Offer -OfferName $resellerOfferName -ResourceGroupName $rgName
    Assert-NotNull $resellerOffer
    Set-Offer -Offer $resellerOffer -ResourceGroup $rgName -State "Public"

    $password = ConvertTo-SecureString $UserPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($SubscriptionUser, $password)

    $token =  Get-EnvironmentSpecificToken -Credential $credential

    # Check whether the plan created is visible for the tenant
    $tenantOffer = Get-Offer -OfferName $resellerOfferName -Token $token
    $subDisplayName = "$SubscriptionUser Test Subscription"

    # Creating a subscription with Tenant Token
    $subscription = New-Subscription -SubscriptionUser $SubscriptionUser -OfferId $tenantOffer.Id -Token $token

    # Add sql service to existing plan
    $serviceQuotas = Get-ServiceQuotas  -rpServices $sqlServices -StrongTypedObject
    $resellerplan.properties.ServiceQuotas.Add($serviceQuotas)
    Set-Plan -Plan $resellerplan -ResourceGroup $rgName -State "Public"

    $resellerplan = Get-Plan -PlanName $resellerPlanName -ResourceGroupName $rgName

    Assert-AreEqual -expected "2" -actual $resellerplan.properties.ServiceQuotas.Count

    # Get the subscription after adding a sql service to the plan
    $updatedSubscription = Get-Subscription -SubscriptionId $subscription.SubscriptionId
    Assert-AreEqual -expected "2" -actual $updatedSubscription.ServiceQuotas.QuotaSettings.Count

    Remove-Subscription -TargetSubscriptionId $subscription.SubscriptionId
    Remove-Offer -OfferName $resellerOfferName -ResourceGroupName $rgName
    Remove-Offer -OfferName $sqlOfferName -ResourceGroupName $rgName
    Remove-Plan -PlanName $sqlPlanName -ResourceGroupName $rgName
    Remove-Plan -PlanName $resellerPlanName -ResourceGroupName $rgName
}
