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

using Microsoft.WindowsAzure.Management.Compute;
using Microsoft.WindowsAzure.Management.Storage;

namespace Microsoft.WindowsAzure.Commands.ServiceManagement.Network.Test.ScenarioTests
{
    using Microsoft.Azure.Commands.Common.Authentication;
    using Microsoft.Azure.Test;
    using Microsoft.Azure.Test.HttpRecorder;
    using Microsoft.WindowsAzure.Commands.ScenarioTest;
    using Microsoft.WindowsAzure.Management;
    using Microsoft.WindowsAzure.Management.Network;
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using Xunit;

    public class ReservedIP
    {
        private readonly EnvironmentSetupHelper helper = new EnvironmentSetupHelper();
        
        [Fact]
        [Trait(Category.Service, Category.Network)]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void AzureReservedIPSimpleOps()
        {
            RunPowerShellTest("Test-AzureReservedIPSimpleOperations");
        }

        [Fact]
        [Trait(Category.Service, Category.Network)]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void CreateVMWithReservedIP()
        {
            RunPowerShellTest("Test-CreateVMWithReservedIP");
        }

        [Fact]
        [Trait(Category.Service, Category.Network)]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void SetReservedIPAssocSimple()
        {
            RunPowerShellTest("Test-SetAzureReservedIPAssociationSingleVip");
        }

        [Fact]
        [Trait(Category.Service, Category.Network)]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void RemoveReservedIPAssocSimple()
        {
            RunPowerShellTest("Test-RemoveAzureReservedIPAssociationSingleVip");
        }

        [Fact]
        [Trait(Category.Service, Category.Network)]
        [Trait(Category.AcceptanceType, Category.CheckIn)]
        public void ReserveExistingDepIP()
        {
            RunPowerShellTest("Test-ReserveExistingDeploymentIP");
        }

        #region Test setup
        protected void SetupManagementClients()
        {
            var client = TestBase.GetServiceClient<NetworkManagementClient>(new RDFETestEnvironmentFactory());
            var client2 = TestBase.GetServiceClient<ManagementClient>(new RDFETestEnvironmentFactory());
            var client3 = TestBase.GetServiceClient<ComputeManagementClient>(new RDFETestEnvironmentFactory());
            var client4 = TestBase.GetServiceClient<StorageManagementClient>(new RDFETestEnvironmentFactory());
            helper.SetupManagementClients(client, client2, client3, client4);
        }

        protected void RunPowerShellTest(params string[] scripts)
        {
            HttpMockServer.RecordsDirectory = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SessionRecords");
            using (UndoContext context = UndoContext.Current)
            {
                context.Start(TestUtilities.GetCallingClass(2), TestUtilities.GetCurrentMethodName(2));

                List<string> modules = Directory.GetFiles(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "ScenarioTests\\ReservedIPs"), "*.ps1").ToList();
                modules.AddRange(Directory.GetFiles(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"ScenarioTests"), "*.ps1"));
                modules.Add("Common.ps1");

                SetupManagementClients();

                helper.SetupEnvironment(AzureModule.AzureServiceManagement);
                helper.SetupModules(AzureModule.AzureServiceManagement, modules.ToArray());

                helper.RunPowerShellTest(scripts);
            }
        }
        #endregion
    }
}
