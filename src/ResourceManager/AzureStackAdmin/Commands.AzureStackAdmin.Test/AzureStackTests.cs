using Microsoft.AzureStack.Commands.Admin.Test.Common;
using Xunit;

namespace Microsoft.AzureStack.Commands.Admin.Test
{
    using System.Globalization;

    /// <summary>
    /// The filename and the class name is expected to be same
    /// The filename should also match the file containing the PowerShell cmdlets called except for the extension
    /// </summary>
    public class AzureStackTests
    {
        [Fact]
        public void TestPlan()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-Plan");
        }

        [Fact]
        public void TestOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-Offer");
        }

        [Fact]
        public void TestSqlOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-Offer -Services @(\"Microsoft.Sql\")");
        }

        [Fact]
        public void TestResellerOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-Offer -Services @(\"Microsoft.Subscriptions\")");
        }

        [Fact]
        public void TestXrpOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-Offer -Services @(\"Microsoft.Storage\", \"Microsoft.Network\", \"Microsoft.Compute\")");
        }

        [Fact]
        
        public void TestTenantSubscription()
        {
            string tenantUser1 = AzStackTestRunner.ReadAppSettings("TenantUser1");
            AzStackTestRunner.NewInstance.RunPsTest("Test-TenantSubscription -SubscriptionUser " + tenantUser1);
        }

        [Fact]
        
        
        public void TestXrpTenantSubscription()
        {
            string tenantUser1 = AzStackTestRunner.ReadAppSettings("TenantUser1");
            AzStackTestRunner.NewInstance.RunPsTest("Test-TenantSubscription -Services @(\"Microsoft.Storage\", \"Microsoft.Network\", \"Microsoft.Compute\") -SubscriptionUser " + tenantUser1);
        }

        [Fact]
        
        public void TestTenantResellerSubscription()
        {
            string tenantUser1 = AzStackTestRunner.ReadAppSettings("TenantUser1");
            AzStackTestRunner.NewInstance.RunPsTest("Test-TenantSubscription -Services @(\"Microsoft.Subscriptions\") -SubscriptionUser " + tenantUser1);
        }

        [Fact]
        
        public void TestTenantSubscribeToOffer()
        {
            string tenantUser1 = AzStackTestRunner.ReadAppSettings("TenantUser1");
            string tenantUser1Password = AzStackTestRunner.ReadAppSettings("TenantUser1Password");
            string script = string.Format(
                CultureInfo.InvariantCulture,
                "Test-TenantSubscribeToOffer -SubscriptionUser {0} -UserPassword {1}",
                tenantUser1,
                tenantUser1Password);
            AzStackTestRunner.NewInstance.RunPsTest(script);
        }

        [Fact]
        
        public void TestDelegatedOffer()
        {
            string tenantUser1 = AzStackTestRunner.ReadAppSettings("TenantUser1");
            string tenantUser1Password = AzStackTestRunner.ReadAppSettings("TenantUser1Password");
            string script = string.Format(
                CultureInfo.InvariantCulture,
                "Test-DelegatedOffer -SubscriptionUser {0} -UserPassword {1}",
                tenantUser1,
                tenantUser1Password);
            AzStackTestRunner.NewInstance.RunPsTest(script);
        }

        [Fact]
        
        public void TestUpdateSubscriptionServiceQuota()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-UpdateSubscriptionServiceQuota");
        }

        [Fact]
        
        public void TestAddDelegatedOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-UpdateSubscriptionServiceQuota -AddDelegatedOffer");
        }

        [Fact]
        
        public void TestAddServicetoPlan()
        {
            string tenantUser1 = AzStackTestRunner.ReadAppSettings("TenantUser1");
            string tenantUser1Password = AzStackTestRunner.ReadAppSettings("TenantUser1Password");
            string script = string.Format(
                CultureInfo.InvariantCulture,
                "Test-AddServiceToPlan -SubscriptionUser {0} -UserPassword {1}",
                tenantUser1,
                tenantUser1Password);
            AzStackTestRunner.NewInstance.RunPsTest(script);
        }

        [Fact]
        
        
        public void TestTenantSubscribeToXrpOffer()
        {
            string tenantUser1 = AzStackTestRunner.ReadAppSettings("TenantUser1");
            string tenantUser1Password = AzStackTestRunner.ReadAppSettings("TenantUser1Password");
            string script = string.Format(
                CultureInfo.InvariantCulture,
                "Test-TenantSubscribeToOffer -SubscriptionUser {0} -UserPassword {1}  -Services @(\"Microsoft.Storage\", \"Microsoft.Network\", \"Microsoft.Compute\")",
                tenantUser1,
                tenantUser1Password);
            AzStackTestRunner.NewInstance.RunPsTest(script);
        }

        [Fact]
        
        public void TestCreateXrpTenantSubscription()
        {
            string planName = AzStackTestRunner.ReadAppSettings("XrpPlanName");
            string resourceGroupName = AzStackTestRunner.ReadAppSettings("XrpResourceGroupName");
            string offerName = AzStackTestRunner.ReadAppSettings("XrpOfferName");
            string tenantUser1 = AzStackTestRunner.ReadAppSettings("TenantUser1");

            string script =
                string.Format(
                    CultureInfo.InvariantCulture,
                    "Test-TenantSubscription -ResourceGroupName {0} -BasePlanName {1} -OfferName {2} -Services @(\"Microsoft.Storage\", \"Microsoft.Network\", \"Microsoft.Compute\") -SubscriptionUser {3}",
                    resourceGroupName,
                    planName,
                    offerName,
                    tenantUser1);

            AzStackTestRunner.NewInstance.RunPsTest(script);
        }
    }
}
