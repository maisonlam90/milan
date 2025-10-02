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
  const [cacheAvailable, setCacheAvailable] = useState(false);

  useEffect(() => {
    // Check cache availability bằng cách test 1 API nhẹ
    const checkCache = async () => {
      try {
        const token = localStorage.getItem("authToken");
        const startTime = Date.now();
        
        const response = await fetch("/api/loan/dashboard-stats", {
          headers: {
            "Authorization": `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        });
        
        const loadTime = Date.now() - startTime;
        
        // Nếu response < 100ms thì có cache
        if (response.ok && loadTime < 100) {
          setCacheAvailable(true);
          // Load tất cả ngay lập tức nếu có cache
          setLoadingPhase(4);
        } else {
          setCacheAvailable(false);
          // Sequential loading nếu không có cache
          const timer1 = setTimeout(() => setLoadingPhase(2), 800);
          const timer2 = setTimeout(() => setLoadingPhase(3), 1600);
          const timer3 = setTimeout(() => setLoadingPhase(4), 2400);

          return () => {
            clearTimeout(timer1);
            clearTimeout(timer2);
            clearTimeout(timer3);
          };
        }
      } catch (error) {
        console.log("Cache check failed, using sequential loading");
        setCacheAvailable(false);
        
        // Sequential loading nếu lỗi
        const timer1 = setTimeout(() => setLoadingPhase(2), 800);
        const timer2 = setTimeout(() => setLoadingPhase(3), 1600);
        const timer3 = setTimeout(() => setLoadingPhase(4), 2400);

        return () => {
          clearTimeout(timer1);
          clearTimeout(timer2);
          clearTimeout(timer3);
        };
      }
    };

    checkCache();
  }, []);

  return (
    <Page title="CRM Analytics Dashboard">
      <div className="overflow-hidden pb-8">
        {/* Phase 1: Always load chart và stats đầu tiên */}
        <div className="transition-content mt-4 grid grid-cols-12 gap-4 px-(--margin-x) sm:mt-5 sm:gap-5 lg:mt-6 lg:gap-6">
          <Overview />
          <DashboardStats />
          
          {/* Phase 2: Load contract status */}
          {loadingPhase >= 2 && (
            <>
              <ContractStatus />
              <LoanPortfolioQuality />
            </>
          )}
        </div>

        {/* Phase 3: Load top contracts */}
        {loadingPhase >= 3 && <TopContracts />}

        {/* Phase 4: Load activities */}
        {loadingPhase >= 4 && (
          <div className="transition-content mt-4 grid grid-cols-1 gap-4 px-(--margin-x) sm:mt-5 sm:grid-cols-2 sm:gap-5 lg:mt-6 lg:gap-6">
            <LoanActivityReport />
            <RecentActivities />
          </div>
        )}

        {/* Debug info */}
        {process.env.NODE_ENV === 'development' && (
          <div className="fixed bottom-4 right-4 bg-black/80 text-white text-xs p-2 rounded">
            Cache: {cacheAvailable ? "✅ Fast" : "❌ Slow"} | Phase: {loadingPhase}
          </div>
        )}
      </div>
    </Page>
  );
}
