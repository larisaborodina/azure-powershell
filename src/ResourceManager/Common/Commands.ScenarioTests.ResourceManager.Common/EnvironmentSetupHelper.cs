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

using Microsoft.Azure;
using Microsoft.Azure.Test;
using Microsoft.Azure.Test.HttpRecorder;
using Microsoft.WindowsAzure.Commands.Common.Test.Mocks;
using Microsoft.WindowsAzure.Commands.Utilities.Common;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using System.Security.Cryptography.X509Certificates;
using Microsoft.Azure.Commands.Common.Authentication;
using Microsoft.Azure.Commands.Common.Authentication.Models;
using Microsoft.Azure.ServiceManagemenet.Common;
using Microsoft.WindowsAzure.Commands.Common;

namespace Microsoft.WindowsAzure.Commands.ScenarioTest
{
    public class EnvironmentSetupHelper
    {
        private static string testEnvironmentName = "__test-environment";

        private static string testSubscriptionName = "__test-subscriptions";

        private AzureSubscription testSubscription;

        private AzureAccount testAccount;

        private const string PackageDirectoryFromCommon = @"..\..\..\..\Package\Debug";
        public string PackageDirectory = @"..\..\..\..\..\Package\Debug";

        protected List<string> modules;

        protected ProfileClient ProfileClient { get; set; }

        public EnvironmentSetupHelper()
        {
            var datastore = new MemoryDataStore();
            AzureSession.DataStore = datastore;
            var profile = new AzureSMProfile(Path.Combine(AzureSession.ProfileDirectory, AzureSession.ProfileFile));
            var rmprofile = new AzureRMProfile(Path.Combine(AzureSession.ProfileDirectory, AzureSession.ProfileFile));
            rmprofile.Environments.Add("foo", AzureEnvironment.PublicEnvironments.Values.FirstOrDefault());
            rmprofile.Context = new AzureContext(new AzureSubscription(), new AzureAccount(), rmprofile.Environments["foo"], new AzureTenant());
            rmprofile.Context.Subscription.Environment = "foo";
            if (AzureRmProfileProvider.Instance.Profile == null)
            {
                AzureRmProfileProvider.Instance.Profile = rmprofile;
            }

            AzureSession.DataStore = datastore;            
            ProfileClient = new ProfileClient(profile);

            // Ignore SSL errors
            System.Net.ServicePointManager.ServerCertificateValidationCallback += (se, cert, chain, sslerror) => true;

            // Set RunningMocked
            TestMockSupport.RunningMocked = HttpMockServer.GetCurrentMode() == HttpRecorderMode.Playback;
        }

        public string RMProfileModule
        {
            get
            {
                return Path.Combine(this.PackageDirectory, 
                                    @"ResourceManager\AzureResourceManager\AzureRM.Profile\AzureRM.Profile.psd1");
            }
        }

        public string RMResourceModule
        {
            get
            {
                return Path.Combine(this.PackageDirectory,
                                    @"ResourceManager\AzureResourceManager\AzureRM.Resources\AzureRM.Resources.psd1");
            }
        }

        public string RMStorageModule
        {
            get
            {
                return Path.Combine(this.PackageDirectory, 
                                    @"ResourceManager\AzureResourceManager\AzureRM.Storage\AzureRM.Storage.psd1");
            }
        }

        //TODO: clarify (data plane should not be under ARM folder)
        public string RMStorageDataPlaneModule
        {
            get
            {
                return Path.Combine(this.PackageDirectory,
                                     @"ResourceManager\AzureResourceManager\Azure.Storage\Azure.Storage.psd1");
            }
        }

        public string GetRMModulePath(string psd1FileName)
        {
            string basename = Path.GetFileNameWithoutExtension(psd1FileName);
            return Path.Combine(this.PackageDirectory, 
                                 @"ResourceManager\AzureResourceManager\" + basename + @"\" + psd1FileName); 
        }
        /// <summary>
        /// Loads DummyManagementClientHelper with clients and throws exception if any client is missing.
        /// </summary>
        /// <param name="initializedManagementClients"></param>
        public void SetupManagementClients(params object[] initializedManagementClients)
        {
            AzureSession.ClientFactory = new MockClientFactory(initializedManagementClients);
        }

        /// <summary>
        /// Loads DummyManagementClientHelper with clients and sets it up to create missing clients dynamically.
        /// </summary>
        /// <param name="initializedManagementClients"></param>
        public void SetupSomeOfManagementClients(params object[] initializedManagementClients)
        {
            AzureSession.ClientFactory = new MockClientFactory(initializedManagementClients, false);
        }

        public void SetupEnvironment(AzureModule mode)
        {
            SetupAzureEnvironmentFromEnvironmentVariables(mode);

            ProfileClient.Profile.Save();
        }

        private void SetupAzureEnvironmentFromEnvironmentVariables(AzureModule mode)
        {
            TestEnvironment currentEnvironment = null;
            if (mode == AzureModule.AzureResourceManager)
            {
                currentEnvironment = new CSMTestEnvironmentFactory().GetTestEnvironment();
            } 
            else
            {
                currentEnvironment = new RDFETestEnvironmentFactory().GetTestEnvironment();
            }

            if (currentEnvironment.UserName == null)
            {
                currentEnvironment.UserName = "fakeuser@microsoft.com";
            }

            SetAuthenticationFactory(mode, currentEnvironment);

            AzureEnvironment environment = new AzureEnvironment { Name = testEnvironmentName };

            Debug.Assert(currentEnvironment != null);
            environment.Endpoints[AzureEnvironment.Endpoint.ActiveDirectory] = currentEnvironment.Endpoints.AADAuthUri.AbsoluteUri;
            environment.Endpoints[AzureEnvironment.Endpoint.Gallery] = currentEnvironment.Endpoints.GalleryUri.AbsoluteUri;
            environment.Endpoints[AzureEnvironment.Endpoint.ServiceManagement] = currentEnvironment.BaseUri.AbsoluteUri;
            environment.Endpoints[AzureEnvironment.Endpoint.ResourceManager] = currentEnvironment.Endpoints.ResourceManagementUri.AbsoluteUri;
            environment.Endpoints[AzureEnvironment.Endpoint.Graph] = currentEnvironment.Endpoints.GraphUri.AbsoluteUri;
            environment.Endpoints[AzureEnvironment.Endpoint.AzureDataLakeAnalyticsCatalogAndJobEndpointSuffix] = currentEnvironment.Endpoints.DataLakeAnalyticsJobAndCatalogServiceUri.OriginalString.Replace("https://",""); // because it is just a sufix
            environment.Endpoints[AzureEnvironment.Endpoint.AzureDataLakeStoreFileSystemEndpointSuffix] = currentEnvironment.Endpoints.DataLakeStoreServiceUri.OriginalString.Replace("https://", ""); // because it is just a sufix

            if (!ProfileClient.Profile.Environments.ContainsKey(testEnvironmentName))
            {
                ProfileClient.AddOrSetEnvironment(environment);
            }

            if (!AzureRmProfileProvider.Instance.Profile.Environments.ContainsKey(testEnvironmentName))
            {
                AzureRmProfileProvider.Instance.Profile.Environments[testEnvironmentName] = environment;
            }

            if (currentEnvironment.SubscriptionId != null)
            {
                testSubscription = new AzureSubscription()
                {
                    Id = new Guid(currentEnvironment.SubscriptionId),
                    Name = testSubscriptionName,
                    Environment = testEnvironmentName,
                    Account = currentEnvironment.UserName,
                    Properties = new Dictionary<AzureSubscription.Property, string>
                    {
                        {AzureSubscription.Property.Default, "True"},
                        {
                            AzureSubscription.Property.StorageAccount,
                            Environment.GetEnvironmentVariable("AZURE_STORAGE_ACCOUNT")
                        },
                    }
                };

                testAccount = new AzureAccount()
                {
                    Id = currentEnvironment.UserName,
                    Type = AzureAccount.AccountType.User,
                    Properties = new Dictionary<AzureAccount.Property, string>
                    {
                        {AzureAccount.Property.Subscriptions, currentEnvironment.SubscriptionId},
                    }
                };

                ProfileClient.Profile.Subscriptions[testSubscription.Id] = testSubscription;
                ProfileClient.Profile.Accounts[testAccount.Id] = testAccount;
                ProfileClient.SetSubscriptionAsDefault(testSubscription.Name, testSubscription.Account);

                var testTenant = new AzureTenant() { Id = Guid.NewGuid() };
                if (!string.IsNullOrEmpty(currentEnvironment.Tenant))
                {
                    Guid tenant;
                    if (Guid.TryParse(currentEnvironment.Tenant, out tenant))
                    {
                        testTenant.Id = tenant;
                    }
                }
                AzureRmProfileProvider.Instance.Profile.Context = new AzureContext(testSubscription, testAccount, environment, testTenant);
            }
        }

        private void SetAuthenticationFactory(AzureModule mode, TestEnvironment environment)
        {
            string jwtToken = null;
            X509Certificate2 certificate = null;

            if (environment.Credentials is TokenCloudCredentials)
            {
                jwtToken = ((TokenCloudCredentials)environment.Credentials).Token;
            }
            if (environment.Credentials is CertificateCloudCredentials)
            {
                certificate = ((CertificateCloudCredentials)environment.Credentials).ManagementCertificate;
            }


            if (jwtToken != null)
            {
                AzureSession.AuthenticationFactory = new MockTokenAuthenticationFactory(environment.UserName,
                    jwtToken);
            }
            else if (certificate != null)
            {
                AzureSession.AuthenticationFactory = new MockCertificateAuthenticationFactory(environment.UserName,
                    certificate);
            }
        }

        public void SetupModules(AzureModule mode, params string[] modules)
        {
            this.modules = new List<string>();
            if (mode == AzureModule.AzureProfile)
            {
                this.modules.Add(Path.Combine(PackageDirectory, @"ServiceManagement\Azure\Azure.psd1"));
                this.modules.Add(Path.Combine(PackageDirectory, @"ResourceManager\AzureResourceManager\AzureResourceManager.psd1"));
            }
            else if (mode == AzureModule.AzureServiceManagement)
            {
                this.modules.Add(Path.Combine(PackageDirectory, @"ServiceManagement\Azure\Azure.psd1"));
            }
            
            this.modules.Add("Assert.ps1");
            this.modules.Add("Common.ps1");
            this.modules.AddRange(modules);
        }

        public void SetupModulesFromCommon(AzureModule mode, params string[] modules)
        {
            this.modules = new List<string>();
            if (mode == AzureModule.AzureProfile)
            {
                this.modules.Add(Path.Combine(PackageDirectoryFromCommon, @"ServiceManagement\Azure\Azure.psd1"));
                this.modules.Add(Path.Combine(PackageDirectoryFromCommon, @"ResourceManager\AzureResourceManager\AzureResourceManager.psd1"));
            }
            else if (mode == AzureModule.AzureServiceManagement)
            {
                this.modules.Add(Path.Combine(PackageDirectoryFromCommon, @"ServiceManagement\Azure\Azure.psd1"));
            }
            else if (mode == AzureModule.AzureResourceManager)
            {
                this.modules.Add(Path.Combine(PackageDirectoryFromCommon, @"ResourceManager\AzureResourceManager\AzureResourceManager.psd1"));
            }
            else
            {
                throw new ArgumentException("Unknown command type for testing");
            }
            this.modules.Add("Assert.ps1");
            this.modules.Add("Common.ps1");
            this.modules.AddRange(modules);
        }

        public void SetupModules(params string[] modules)
        {
            this.modules = new List<string>();
            this.modules.Add("Assert.ps1");
            this.modules.Add("Common.ps1");
            this.modules.AddRange(modules);
        }

        public virtual Collection<PSObject> RunPowerShellTest(params string[] scripts)
        {
            using (var powershell = System.Management.Automation.PowerShell.Create(RunspaceMode.NewRunspace))
            {
                SetupPowerShellModules(powershell);                

                Collection<PSObject> output = null;
                for (int i = 0; i < scripts.Length; ++i)
                {
                    Console.WriteLine(scripts[i]);
                    powershell.AddScript(scripts[i]);
                }
                try
                {
                    powershell.Runspace.Events.Subscribers.Clear();
                    output = powershell.Invoke();

                    if (powershell.Streams.Error.Count > 0)
                    {
                        throw new RuntimeException(
                            "Test failed due to a non-empty error stream, check the error stream in the test log for more details.");
                    }

                    return output;
                }
                catch (Exception psException)
                {
                    powershell.LogPowerShellException(psException);
                    throw;
                }
                finally
                {
                    powershell.LogPowerShellResults(output);
                    powershell.Streams.Error.Clear();
                }
            }
        }

        private void SetupPowerShellModules(System.Management.Automation.PowerShell powershell)
        {
            powershell.AddScript("$error.clear()");
            powershell.AddScript(string.Format("Write-Debug \"current directory: {0}\"", AppDomain.CurrentDomain.BaseDirectory));
            powershell.AddScript(string.Format("Write-Debug \"current executing assembly: {0}\"", Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)));
            powershell.AddScript(string.Format("cd \"{0}\"", AppDomain.CurrentDomain.BaseDirectory));

            foreach (string moduleName in modules)
            {
                powershell.AddScript(string.Format("Import-Module \"{0}\"", 
                    Path.Combine(AppDomain.CurrentDomain.BaseDirectory,moduleName)));
            }

            powershell.AddScript(
                string.Format(@"set-location {0}", AppDomain.CurrentDomain.BaseDirectory));
            powershell.AddScript(string.Format(@"$TestOutputRoot='{0}'", AppDomain.CurrentDomain.BaseDirectory));
            powershell.AddScript("$VerbosePreference='Continue'");
            powershell.AddScript("$DebugPreference='Continue'");
            powershell.AddScript("$ErrorActionPreference='Stop'");
            powershell.AddScript("Write-Debug \"AZURE_TEST_MODE = $($env:AZURE_TEST_MODE)\"");
            powershell.AddScript("Write-Debug \"TEST_HTTPMOCK_OUTPUT =  $($env:TEST_HTTPMOCK_OUTPUT)\"");
        }

    }
}
