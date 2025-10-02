// Local Imports
import { Page } from "@/components/shared/Page";
import { Overview } from "./Overview";
import { DashboardStats } from "./DashboardStats";
import { ContractStatus } from "./ContractStatus";
import { LoanPortfolioQuality } from "./LoanPortfolioQuality";
import { TopContracts } from "./TopContracts";
import { RecentActivities } from "./RecentActivities";
import { LoanActivityReport } from "./LoanActivityReport";

// ----------------------------------------------------------------------

export default function CRMAnalytics() {
  return (
    <Page title="CRM Analytics Dashboard">
      <div className="overflow-hidden pb-8">
        <div className="transition-content mt-4 grid grid-cols-12 gap-4 px-(--margin-x) sm:mt-5 sm:gap-5 lg:mt-6 lg:gap-6">
          <Overview />
          <DashboardStats />
          <ContractStatus />
          <LoanPortfolioQuality />
        </div>
        <TopContracts />
        <div className="transition-content mt-4 grid grid-cols-1 gap-4 px-(--margin-x) sm:mt-5 sm:grid-cols-2 sm:gap-5 lg:mt-6 lg:gap-6">
          <LoanActivityReport />
          <RecentActivities />
        </div>
      </div>
    </Page>
  );
}
