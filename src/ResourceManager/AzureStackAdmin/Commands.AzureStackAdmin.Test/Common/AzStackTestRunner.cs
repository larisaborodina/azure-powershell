//------------------------------------------------------------
// Copyright (c) Microsoft Corporation.  All rights reserved.
//------------------------------------------------------------

using Microsoft.Azure.Common.Authentication;
using Microsoft.Azure.Test;
using Microsoft.AzureStack.Management;
using Microsoft.WindowsAzure.Commands.Common.Test.Mocks;
using Microsoft.WindowsAzure.Commands.ScenarioTest;

namespace Microsoft.AzureStack.Commands.Admin.Test.Common
{
    using System;
    using System.Collections.Generic;
    using System.Collections.ObjectModel;
    using System.Configuration;
    using System.Globalization;
    using System.IO;
    using System.Linq;
    using System.Management.Automation;

    public sealed class AzStackTestRunner
    {
       
        private EnvironmentSetupHelper helper;
        private CSMTestEnvironmentFactory armTestEnvironmentFactory;

        private AzureStackClient azureStackClient;

        public static AzStackTestRunner NewInstance
        {
            get
            {
                return new AzStackTestRunner();
            }
        }


        public AzStackTestRunner()
        {
            helper = new EnvironmentSetupHelper();
        }

        public List<string> SetupCommonModules()
        {
            List<string> modules = new List<string>();
            modules = new List<string>();
            bool aadEnvironement = Convert.ToBoolean(ReadAppSettings("AadEnvironment"), CultureInfo.InvariantCulture);

            if (aadEnvironement)
            {
                modules.Add(@"C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureRm.Profile\AzureRm.Profile.psd1");
                modules.Add(@"C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureRM.AzureStackAdmin\AzureRM.AzureStackAdmin.psd1");
                modules.Add(@"C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureRM.Resources\AzureRM.Resources.psd1");
            }

            // The modules are deployed to the test run directory with the test settings file
            modules.Add(@".\Assert.psm1");
            modules.Add(@".\GlobalVariables.psm1");
            modules.Add(@".\AuthOperations.psm1");
            modules.Add(@".\CommonOperations.psm1");
            modules.Add(@".\ArmOperations.psm1");
            modules.Add(@".\SqlOperations.psm1");
            modules.Add(@".\Utilities.psm1");
            
            return modules;
        }

        private string[] SetupAzureStackEnvironment(string testScript)
        {
            List<string> scripts =new List<string>();
            string azureStackMachine = ReadAppSettings("AzureStackMachineName");
            string defaultAdminPassword = ReadAppSettings("DefaultAdminPassword");
            string defaultAdminUser = ReadAppSettings("DefaultAdminUser");
            bool aadEnvironment = Convert.ToBoolean(ReadAppSettings("AadEnvironment"), CultureInfo.InvariantCulture);
            string aadTenantId = ReadAppSettings("AadTenantId", mandatory: false);
            string aadApplicationId = ReadAppSettings("AadApiApplicationId", mandatory: false);
            string armEndpoint = ReadAppSettings("ArmEndpoint", mandatory: false);
            string galleryEndpoint = ReadAppSettings("GalleryEndpoint", mandatory: false);
            string aadGraphUri = ReadAppSettings("AadGraphUri", mandatory: false);
            string aadLoginuri = ReadAppSettings("AadLoginUri", mandatory: false);
            
            string adminUserNamePs;
            string adminPasswordPs;
            string setupAzureStackEnvironmentPs;

            adminUserNamePs = "$adminUsername=\"" + defaultAdminUser + "\"";
            adminPasswordPs = "$adminPassword =  ConvertTo-SecureString -String \"" + defaultAdminPassword + "\" -AsPlainText -Force";
            string credentialPs = "$credential = New-Object System.Management.Automation.PSCredential($adminUsername, $adminPassword)";

            if (aadEnvironment)
            { 
                setupAzureStackEnvironmentPs = string.Format(
                    CultureInfo.InvariantCulture,
                    "Set-AzureStackEnvironment -AzureStackMachineName {0} -Credential $credential -AadTenantId {1} -AadApplicationId {2} -ArmEndpoint {3} -GalleryEndpoint {4} -AadGraphUri {5} -AadLoginUri {6}",
                    azureStackMachine,
                    aadTenantId,
                    aadApplicationId,
                    armEndpoint,
                    galleryEndpoint,
                    aadGraphUri,
                    aadLoginuri
                    );
            }
            else
            {
                setupAzureStackEnvironmentPs = "Set-AzureStackEnvironment -AzureStackMachineName " + azureStackMachine + " -Credential $credential";
            }

            // TODO: Remove Self Signed Cert when ready
            string selfSignedCertPs = "Ignore-SelfSignedCert";

            scripts.Add(adminUserNamePs);
            scripts.Add(adminPasswordPs);
            scripts.Add(credentialPs);
            scripts.Add(selfSignedCertPs);
            scripts.Add(setupAzureStackEnvironmentPs);
            
            scripts.Add(testScript);
            return scripts.ToArray();
        }

        public static string ReadAppSettings(string key, bool mandatory = true)
        {
            if (ConfigurationManager.AppSettings.AllKeys.Contains(key, StringComparer.OrdinalIgnoreCase))
            {
                return ConfigurationManager.AppSettings[key];
            }

            if (mandatory)
            {
                throw new ConfigurationErrorsException(string.Format(CultureInfo.InvariantCulture, "The app settings key {0} is missing in the settings file", key));
            }

            return null;
        }

        //private void SetupPowerShellModules(System.Management.Automation.PowerShell powershell)
        //{
        //    powershell.AddScript(string.Format(CultureInfo.InvariantCulture, "cd \"{0}\"", Environment.CurrentDirectory));

        //    powershell.AddScript("$VerbosePreference='SilentlyContinue'");

        //    foreach (string moduleName in this.Modules)
        //    {
        //        powershell.AddScript(string.Format(CultureInfo.InvariantCulture, "Import-Module \"{0}\" -Force -ErrorAction Stop", moduleName));
        //    }

        //    powershell.AddScript("$VerbosePreference='Continue'");
        //    powershell.AddScript("$DebugPreference='Continue'");
        //    powershell.AddScript("$ErrorActionPreference='Stop'");
        //    powershell.AddScript("$ProgressPreference='SilentlyContinue'");
        //}


        public void RunPsTest(string testScript)
        {
            var callingClassType = TestUtilities.GetCallingClass(2);
            var mockName = TestUtilities.GetCurrentMethodName(2);

            RunPsTestWorkflow(
                () => SetupAzureStackEnvironment(testScript),
                // no custom initializer
                null,
                // no custom cleanup 
                null,
                callingClassType,
                mockName);
        }


        public void RunPsTestWorkflow(
           Func<string[]> scriptBuilder,
           Action<CSMTestEnvironmentFactory> initialize,
           Action cleanup,
           string callingClassType,
           string mockName)
        {
            using (UndoContext context = UndoContext.Current)
            {
                context.Start(callingClassType, mockName);

                this.armTestEnvironmentFactory = new CSMTestEnvironmentFactory();

                if (initialize != null)
                {
                    initialize(this.armTestEnvironmentFactory);
                }

                helper.SetupEnvironment(AzureModule.AzureResourceManager);

                SetupManagementClients();

                var callingClassName = callingClassType
                                        .Split(new[] { "." }, StringSplitOptions.RemoveEmptyEntries)
                                        .Last();

                List<string> modules = this.SetupCommonModules();
                modules.Add(callingClassName + ".ps1");
                modules.Add(helper.RMProfileModule);
                modules.Add(helper.RMResourceModule);
                helper.SetupModules(AzureModule.AzureResourceManager, modules.ToArray());

                try
                {
                    if (scriptBuilder != null)
                    {
                        var psScripts = scriptBuilder();

                        if (psScripts != null)
                        {
                            helper.RunPowerShellTest(psScripts);
                        }
                    }
                }
                finally
                {
                    if (cleanup != null)
                    {
                        cleanup();
                    }
                }
            }
        }


        private void SetupManagementClients()
        {
            azureStackClient = TestBase.GetServiceClient<AzureStackClient>(this.armTestEnvironmentFactory);

            this.SetupManagementClients(azureStackClient);
        }

        /// <summary>
        /// Loads DummyManagementClientHelper with clients and throws exception if any client is missing.
        /// </summary>
        /// <param name="initializedManagementClients"></param>
        public void SetupManagementClients(params object[] initializedManagementClients)
        {
            AzureSession.ClientFactory = new MockClientFactory(initializedManagementClients);
        }


        //public virtual Collection<PSObject> RunPowerShellTest(params string[] scripts)
        //{
        //    using (var powershell = System.Management.Automation.PowerShell.Create())
        //    {
        //        this.SetupPowerShellModules(powershell);
        //        this.SetupAzureStackEnvironment(powershell);

        //        Collection<PSObject> output = null;
        //        for (int i = 0; i < scripts.Length; ++i)
        //        {
        //            Console.WriteLine(scripts[i]);
        //            powershell.AddScript(scripts[i]);
        //        }

        //        try
        //        {
        //            output = powershell.Invoke();

        //            if (powershell.Streams.Error.Count > 0)
        //            {
        //                throw new RuntimeException(
        //                    "Test failed due to a non-empty error stream, check the error stream in the test log for more details.");
        //            }

        //            return output;
        //        }
        //        catch (Exception powershellException)
        //        {
        //            powershell.LogPowerShellException(powershellException);
        //            throw;
        //        }
        //        finally
        //        {
        //            powershell.LogPowerShellResults(output);
        //        }
        //    }
        //}
    }
}
