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
        public void TestResourceGroup()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-ResourceGroup");
        }

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
        public void TestTenantSubscription()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-TenantSubscription");
        }

        [Fact]
        public void TestDelegatedOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-DelegatedOffer");
        }

        [Fact]
        public void TestUpdateSubscriptionServiceQuota()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-UpdateSubscriptionServiceQuota");
        }

        [Fact]
        public void TestAddDelegatedOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-AddDelegatedOffer");
        }

        [Fact]
        public void TestManagedLocation()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-ManagedLocation");
        }

    }
}
