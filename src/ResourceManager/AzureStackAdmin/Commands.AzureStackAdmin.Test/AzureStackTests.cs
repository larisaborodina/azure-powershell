﻿// ----------------------------------------------------------------------------------
//
// Copyright Microsoft Corporation
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------------------

namespace Microsoft.AzureStack.Commands.Admin.Test
{
    using Microsoft.AzureStack.Commands.Admin.Test.Common;
    using Xunit;
    using Microsoft.WindowsAzure.Commands.ScenarioTest;

    /// <summary>
    /// The filename and the class name is expected to be same
    /// The filename should also match the file containing the PowerShell cmdlets called except for the extension
    /// </summary>
    public class AzureStackTests
    {
        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestResourceGroup()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-ResourceGroup");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestPlan()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-Plan");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-Offer");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestTenantSubscription()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-TenantSubscription");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestDelegatedOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-DelegatedOffer");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestUpdateSubscriptionServiceQuota()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-UpdateSubscriptionServiceQuota");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestAddDelegatedOffer()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-AddDelegatedOffer");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestManagedLocation()
        {
            AzStackTestRunner.NewInstance.RunPsTest("Test-ManagedLocation");
        }

        [Fact]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void TestGalleryItem()
        {
            var testRunner = AzStackTestRunner.NewInstance;
            testRunner.ApiVersion = "2015-04-01";
            testRunner.RunPsTest("Test-GalleryItem");
        }

    }
}
