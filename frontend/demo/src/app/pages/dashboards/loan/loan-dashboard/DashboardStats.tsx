// Import Dependencies
import {
  CheckBadgeIcon,
  ClockIcon,
  CubeIcon,
  CurrencyDollarIcon,
  DocumentTextIcon,
  BanknotesIcon,
} from "@heroicons/react/24/outline";
import { useEffect, useState, useMemo } from "react";
import axios from "axios";

// Local Imports
import { Card } from "@/components/ui";
import { JWT_HOST_API } from "@/configs/auth";

// ----------------------------------------------------------------------

interface DashboardStats {
  monthly_interest: number;
  settled_this_month: number;
  active_contracts: number;
  new_contracts_this_month: number;
  total_outstanding: number;
  total_contracts: number;
  month: number;
  year: number;
}

export function DashboardStats() {
  const [stats, setStats] = useState<DashboardStats>({
    monthly_interest: 0,
    settled_this_month: 0,
    active_contracts: 0,
    new_contracts_this_month: 0,
    total_outstanding: 0,
    total_contracts: 0,
    month: 0,
    year: 0,
  });
  const [loading, setLoading] = useState(true);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("authToken") || "" : ""),
    []
  );

  const fetchDashboardStats = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const res = await axios.get(`${JWT_HOST_API}/loan/dashboard-stats`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setStats(res.data || {});
    } catch (error) {
      console.error("Error fetching dashboard stats:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardStats();
  }, [token]);


  // Function để format số tiền ngắn gọn
  const formatCompactCurrency = (amount: number) => {
    if (amount >= 1000000000) {
      return `${(amount / 1000000000).toFixed(1)} tỷ`;
    } else if (amount >= 1000000) {
      return `${(amount / 1000000).toFixed(1)} tr`;
    } else if (amount >= 1000) {
      return `${(amount / 1000).toFixed(1)}k`;
    }
    return new Intl.NumberFormat("vi-VN").format(amount);
  };

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat("vi-VN").format(num);
  };

  return (
    <div className="col-span-12 lg:col-span-4">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-5 lg:grid-cols-2">
        {/* Lãi thu tháng này */}
        <Card className="p-3 lg:p-4">
          <div className="flex justify-between gap-1">
               <p className="text-xl font-semibold text-gray-800 dark:text-dark-100">
                 {loading ? "..." : formatCompactCurrency(stats.monthly_interest)}
               </p>
            <CurrencyDollarIcon className="this:primary size-5 text-this dark:text-this-light" />
          </div>
          <p className="mt-1 text-xs-plus">Lãi thu tháng này</p>
        </Card>

        {/* Hợp đồng tất toán tháng này */}
        <Card className="p-3 lg:p-4">
          <div className="flex justify-between gap-1">
            <p className="text-xl font-semibold text-gray-800 dark:text-dark-100">
              {loading ? "..." : formatNumber(stats.settled_this_month)}
            </p>
            <CheckBadgeIcon className="this:success size-5 text-this dark:text-this-light" />
          </div>
          <p className="mt-1 text-xs-plus">Tất toán tháng này</p>
        </Card>

        {/* Hợp đồng đang hoạt động */}
        <Card className="p-3 lg:p-4">
          <div className="flex justify-between gap-1">
            <p className="text-xl font-semibold text-gray-800 dark:text-dark-100">
              {loading ? "..." : formatNumber(stats.active_contracts)}
            </p>
            <ClockIcon className="this:warning size-5 text-this dark:text-this-light" />
          </div>
          <p className="mt-1 text-xs-plus">Hợp đồng hoạt động</p>
        </Card>

        {/* Hợp đồng mới tháng này */}
        <Card className="p-3 lg:p-4">
          <div className="flex justify-between gap-1">
            <p className="text-xl font-semibold text-gray-800 dark:text-dark-100">
              {loading ? "..." : formatNumber(stats.new_contracts_this_month)}
            </p>
            <DocumentTextIcon className="this:info size-5 text-this dark:text-this-light" />
          </div>
          <p className="mt-1 text-xs-plus">Hợp đồng mới tháng này</p>
        </Card>

        {/* Tổng dư nợ hiện tại */}
        <Card className="p-3 lg:p-4">
          <div className="flex justify-between gap-1">
               <p className="text-xl font-semibold text-gray-800 dark:text-dark-100">
                 {loading ? "..." : formatCompactCurrency(stats.total_outstanding)}
               </p>
            <BanknotesIcon className="this:secondary size-5 text-this dark:text-this-light" />
          </div>
          <p className="mt-1 text-xs-plus">Tổng dư nợ</p>
        </Card>

        {/* Tổng số hợp đồng */}
        <Card className="p-3 lg:p-4">
          <div className="flex justify-between gap-1">
            <p className="text-xl font-semibold text-gray-800 dark:text-dark-100">
              {loading ? "..." : formatNumber(stats.total_contracts)}
            </p>
            <CubeIcon className="this:error size-5 text-this dark:text-this-light" />
          </div>
          <p className="mt-1 text-xs-plus">Tổng hợp đồng</p>
        </Card>
      </div>
    </div>
  );
}
