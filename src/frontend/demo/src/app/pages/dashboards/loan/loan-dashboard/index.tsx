// Local Imports
import { Page } from "@/components/shared/Page";
import { Overview } from "./Overview";
import { DashboardStats } from "./DashboardStats";
import { ContractStatus } from "./ContractStatus";
import { LoanPortfolioQuality } from "./LoanPortfolioQuality";
import { TopContracts } from "./TopContracts";
import { RecentActivities } from "./RecentActivities";
import { LoanActivityReport } from "./LoanActivityReport";
import { useEffect, useState } from "react";

// ----------------------------------------------------------------------

export default function CRMAnalytics() {
  const [loadingPhase, setLoadingPhase] = useState(1);

  useEffect(() => {
    // Sequential loading để tránh quá tải DB connections
    const timer1 = setTimeout(() => setLoadingPhase(2), 1000);  // Load phase 2 sau 1s
    const timer2 = setTimeout(() => setLoadingPhase(3), 2000);  // Load phase 3 sau 2s
    const timer3 = setTimeout(() => setLoadingPhase(4), 3000);  // Load phase 4 sau 3s

    return () => {
      clearTimeout(timer1);
      clearTimeout(timer2);
      clearTimeout(timer3);
    };
  }, []);

  return (
    <Page title="CRM Analytics Dashboard">
      <div className="overflow-hidden pb-8">
        {/* Phase 1: Load chart và stats cơ bản */}
        <div className="transition-content mt-4 grid grid-cols-12 gap-4 px-(--margin-x) sm:mt-5 sm:gap-5 lg:mt-6 lg:gap-6">
          <Overview />
          <DashboardStats />
          
          {/* Phase 2: Load contract status sau 1s */}
          {loadingPhase >= 2 && (
            <>
              <ContractStatus />
              <LoanPortfolioQuality />
            </>
          )}
        </div>

        {/* Phase 3: Load top contracts sau 2s */}
        {loadingPhase >= 3 && <TopContracts />}

        {/* Phase 4: Load activities sau 3s */}
        {loadingPhase >= 4 && (
          <div className="transition-content mt-4 grid grid-cols-1 gap-4 px-(--margin-x) sm:mt-5 sm:grid-cols-2 sm:gap-5 lg:mt-6 lg:gap-6">
            <LoanActivityReport />
            <RecentActivities />
          </div>
        )}
      </div>
    </Page>
  );
}
