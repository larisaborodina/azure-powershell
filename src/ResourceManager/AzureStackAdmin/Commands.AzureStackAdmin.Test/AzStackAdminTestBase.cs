using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.Test.HttpRecorder;

namespace Microsoft.AzureStack.Commands.Admin.Test
{
    public class AzStackAdminTestBase
    {
        public string ResourceGroupName { get; set; }
        public string PlanName { get; set; }
        public string OfferName { get; set; }

        public AzStackAdminTestBase()
        {
            this.Initialize();
        }

        private void Initialize()
        {
            if (HttpMockServer.Mode == HttpRecorderMode.Record)
            {
                this.ResourceGroupName = "TestRg" + Guid.NewGuid();
                this.PlanName = "TestPlan" + Guid.NewGuid();
                this.ResourceGroupName = "TestOffer" + Guid.NewGuid();

                HttpMockServer.Variables["ResourceGroupName"] = ResourceGroupName;
                HttpMockServer.Variables["PlanName"] = PlanName;
                HttpMockServer.Variables["OfferName"] = OfferName;
            }
            else
            {
                this.ResourceGroupName = HttpMockServer.Variables["ResourceGroupName"];
                this.PlanName = HttpMockServer.Variables["PlanName"];
                this.OfferName = HttpMockServer.Variables["OfferName"];
            }
        }
    }
}
