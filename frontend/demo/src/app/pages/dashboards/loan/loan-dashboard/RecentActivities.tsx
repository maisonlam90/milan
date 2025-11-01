// Import Dependencies
import {
  FaMoneyBillWave,
  FaHandHoldingUsd,
  FaCoins,
  FaPercent,
  FaCheckCircle,
  FaExclamationTriangle,
} from "react-icons/fa";
import { ArrowPathIcon } from "@heroicons/react/20/solid";
import { useEffect, useState, useMemo } from "react";
import axios from "axios";

// Local Imports
import {
  Timeline,
  TimelineItem,
  Card,
} from "@/components/ui";
import { JWT_HOST_API } from "@/configs/auth";

// ----------------------------------------------------------------------

interface Activity {
  id: string;
  title: string;
  description: string;
  amount: number;
  formatted_amount: string;
  contract_number: string;
  contact_name: string;
  transaction_type: string;
  icon_type: string;
  color: string;
  date: number;
  note?: string;
}

interface RecentActivitiesData {
  activities: Activity[];
  total_count: number;
  title: string;
  description: string;
}

export function RecentActivities() {
  const [data, setData] = useState<RecentActivitiesData>({
    activities: [],
    total_count: 0,
    title: "Hoạt động gần đây",
    description: "Các giao dịch cho vay mới nhất"
  });
  const [loading, setLoading] = useState(true);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("authToken") || "" : ""),
    []
  );

  const fetchRecentActivities = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const res = await axios.get(`${JWT_HOST_API}/loan/recent-activities`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setData(res.data || {});
    } catch (error) {
      console.error("Error fetching recent activities:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRecentActivities();
  }, [token]);

  const getIcon = (iconType: string) => {
    switch (iconType) {
      case "disbursement":
      case "additional":
        return <FaMoneyBillWave className="text-xs" />;
      case "principal":
        return <FaHandHoldingUsd className="text-xs" />;
      case "interest":
        return <FaPercent className="text-xs" />;
      case "settlement":
        return <FaCheckCircle className="text-xs" />;
      case "liquidation":
        return <FaExclamationTriangle className="text-xs" />;
      default:
        return <FaCoins className="text-xs" />;
    }
  };

  const formatTimeAgo = (timestamp: number) => {
    const now = Date.now();
    const diff = now - (timestamp * 1000);
    const minutes = Math.floor(diff / (1000 * 60));
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days > 0) {
      return `${days} ngày trước`;
    } else if (hours > 0) {
      return `${hours} giờ trước`;
    } else if (minutes > 0) {
      return `${minutes} phút trước`;
    } else {
      return "Vừa xong";
    }
  };

  return (
    <Card className="px-4 pb-5 sm:px-5">
      <div className="flex h-14 min-w-0 items-center justify-between py-3">
        <h2 className="dark:text-dark-100 truncate font-medium tracking-wide text-gray-800">
          {data.title}
        </h2>
        <button
          onClick={fetchRecentActivities}
          className="text-xs-plus text-primary-600 hover:text-primary-600/70 focus:text-primary-600/70 dark:text-primary-400 dark:hover:text-primary-400/70 dark:focus:text-primary-400/70 border-b border-dotted border-current pb-0.5 font-medium outline-hidden transition-colors duration-300 flex items-center gap-1"
        >
          <ArrowPathIcon className="size-3" />
          Làm mới
        </button>
      </div>
      <div className="max-w-lg">
        {loading ? (
          <div className="space-y-4">
            {Array.from({ length: 3 }).map((_, index) => (
              <div key={index} className="animate-pulse flex items-start space-x-3">
                <div className="w-6 h-6 bg-gray-200 dark:bg-dark-600 rounded-full"></div>
                <div className="flex-1">
                  <div className="h-4 bg-gray-200 dark:bg-dark-600 rounded w-3/4 mb-2"></div>
                  <div className="h-3 bg-gray-200 dark:bg-dark-600 rounded w-1/2"></div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <Timeline pointSize="1.5rem">
            {data.activities.map((activity) => (
              <TimelineItem
                key={activity.id}
                title={activity.title}
                time={activity.date * 1000}
                point={
                  <div className={`timeline-item-point this:${activity.color} text-this dark:text-this-light relative flex shrink-0 items-center justify-center rounded-full border border-current`}>
                    {getIcon(activity.icon_type)}
                  </div>
                }
              >
                <p className="text-sm">{activity.description}</p>
                <div className="mt-2 flex items-center justify-between">
                  <div className="text-xs text-gray-500 dark:text-dark-400">
                    {formatTimeAgo(activity.date)}
                  </div>
                  <div className="text-xs font-medium text-gray-700 dark:text-dark-200">
                    {activity.formatted_amount}
                  </div>
                </div>
                {activity.note && (
                  <div className="mt-1 text-xs text-gray-400 dark:text-dark-500">
                    Ghi chú: {activity.note}
                  </div>
                )}
              </TimelineItem>
            ))}
          </Timeline>
        )}
      </div>
    </Card>
  );
}
