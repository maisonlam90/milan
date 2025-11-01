// Import Dependencies
import {
  Menu,
  MenuButton,
  MenuItem,
  MenuItems,
  Transition,
} from "@headlessui/react";
import { EllipsisHorizontalIcon } from "@heroicons/react/20/solid";
import { ArrowUpIcon, ArrowDownIcon } from "@heroicons/react/24/outline";
import clsx from "clsx";
import { Fragment, useEffect, useState, useMemo } from "react";
import Chart from "react-apexcharts";
import { ApexOptions } from "apexcharts";
import axios from "axios";

// Local Imports
import { Button, Card, Progress } from "@/components/ui";
import { JWT_HOST_API } from "@/configs/auth";

// ----------------------------------------------------------------------

interface ActivityItem {
  name: string;
  count: number;
  amount: number;
  unit: string;
  progress: number;
  color: string;
  target_label: string;
  is_active: boolean;
}

interface LoanActivityData {
  title: string;
  activities: ActivityItem[];
  performance: {
    value: string;
    trend: string;
  };
  chart_data: number[];
  month: number;
  year: number;
}

const chartConfig: ApexOptions = {
  colors: ["#4467EF"],
  chart: {
    parentHeightOffset: 0,
    toolbar: {
      show: false,
    },
    zoom: {
      enabled: false,
    },
  },
  dataLabels: {
    enabled: false,
  },
  stroke: {
    curve: "smooth",
    width: 2,
  },
  grid: {
    padding: {
      left: 0,
      right: 0,
      top: -28,
      bottom: -15,
    },
  },
  tooltip: {
    shared: true,
    custom: ({ series, seriesIndex, dataPointIndex }: any) => {
      const value = series[seriesIndex][dataPointIndex];
      const formatted = new Intl.NumberFormat("vi-VN", {
        style: "currency",
        currency: "VND",
      }).format(value);
      return `<div class="px-2 py-1">${formatted}</div>`;
    },
  },
  legend: {
    show: false,
  },
  yaxis: {
    show: false,
  },
  xaxis: {
    labels: {
      show: false,
    },
    axisTicks: {
      show: false,
    },
    axisBorder: {
      show: false,
    },
  },
};

export function LoanActivityReport() {
  const [data, setData] = useState<LoanActivityData>({
    title: "Báo cáo Hoạt động Cho vay",
    activities: [],
    performance: { value: "0.0%", trend: "up" },
    chart_data: [],
    month: 0,
    year: 0,
  });
  const [loading, setLoading] = useState(true);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("authToken") || "" : ""),
    []
  );

  const fetchActivityReport = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const res = await axios.get(`${JWT_HOST_API}/loan/activity-report`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setData(res.data || {});
    } catch (error) {
      console.error("Error fetching activity report:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchActivityReport();
  }, [token]);

  // Function để format số tiền ngắn gọn
  const formatCompactNumber = (num: number) => {
    if (num >= 1000000000) {
      return `${(num / 1000000000).toFixed(1)} tỷ`;
    } else if (num >= 1000000) {
      return `${(num / 1000000).toFixed(1)} tr`;
    } else if (num >= 1000) {
      return `${(num / 1000).toFixed(1)}k`;
    }
    return new Intl.NumberFormat("vi-VN").format(num);
  };

  const getColorClass = (color: string) => {
    switch (color) {
      case "success": return "success";
      case "info": return "info";
      case "warning": return "warning";
      case "error": return "error";
      case "secondary": return "secondary";
      default: return "primary";
    }
  };

  const series = [
    {
      name: "Hoạt động",
      data: data.chart_data,
    },
  ];

  return (
    <Card className="flex flex-col">
      <div className="flex h-14 min-w-0 items-center justify-between px-4 py-3 sm:px-5">
        <h2 className="dark:text-dark-100 truncate font-medium tracking-wide text-gray-800">
          {data.title}
        </h2>
        <ActionMenu onRefresh={fetchActivityReport} />
      </div>
      <div className="grid grid-cols-1 gap-4 px-4 sm:gap-5 sm:px-5 lg:grid-cols-2">
        {loading ? (
          // Loading skeleton
          Array.from({ length: 4 }).map((_, index) => (
            <div key={index} className="border-gray-150 dark:border-dark-600 rounded-lg border p-4 animate-pulse">
              <div className="flex justify-between">
                <div>
                  <div className="h-8 w-16 bg-gray-200 dark:bg-dark-600 rounded"></div>
                </div>
                <div className="h-4 w-20 bg-gray-200 dark:bg-dark-600 rounded"></div>
              </div>
              <div className="mt-3 h-1.5 bg-gray-200 dark:bg-dark-600 rounded"></div>
              <div className="mt-2 flex justify-between">
                <div className="h-3 w-16 bg-gray-200 dark:bg-dark-600 rounded"></div>
                <div className="h-3 w-8 bg-gray-200 dark:bg-dark-600 rounded"></div>
              </div>
            </div>
          ))
        ) : (
          data.activities.map((activity, index) => (
            <div key={index} className="border-gray-150 dark:border-dark-600 rounded-lg border p-4">
              <div className="flex justify-between">
                <div>
                  <span className="dark:text-dark-100 text-2xl font-medium text-gray-800">
                    {activity.count}
                  </span>
                  <span className="text-xs ml-1">{activity.unit}</span>
                </div>
                <p className="text-xs-plus">{activity.name}</p>
              </div>

              <Progress
                color={getColorClass(activity.color)}
                isActive={activity.is_active}
                value={activity.progress}
                classNames={{ root: "mt-3 h-1.5" }}
              />
              <div className="dark:text-dark-300 mt-2 flex justify-between text-xs text-gray-400">
                <p>{activity.target_label}</p>
                <p>{Math.round(activity.progress)}%</p>
              </div>
              
              {/* Hiển thị số tiền nếu có */}
              {activity.amount > 0 && (
                <div className="mt-1 text-xs text-gray-500 dark:text-dark-400">
                  Giá trị: {formatCompactNumber(activity.amount)} VND
                </div>
              )}
            </div>
          ))
        )}
      </div>

      <div className="mt-4 grow px-4 sm:px-5">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <p className="text-xs-plus">Hiệu suất</p>
            <p className="dark:text-dark-100 text-gray-800">
              {loading ? "..." : data.performance.value}
            </p>
            {data.performance.trend === "up" ? (
              <ArrowUpIcon className="this:success text-this dark:text-this-lighter size-4" />
            ) : (
              <ArrowDownIcon className="this:error text-this dark:text-this-lighter size-4" />
            )}
          </div>
          <button
            onClick={fetchActivityReport}
            className="text-xs-plus text-primary-600 hover:text-primary-600/70 focus:text-primary-600/70 dark:text-primary-400 dark:hover:text-primary-400/70 dark:focus:text-primary-400/70 border-b border-dotted border-current pb-0.5 font-medium outline-hidden transition-colors duration-300"
          >
            Làm mới dữ liệu
          </button>
        </div>
      </div>

      <div className="ax-transparent-gridline ax-rounded-b-lg">
        <Chart type="area" height={320} series={series} options={chartConfig} />
      </div>
    </Card>
  );
}

function ActionMenu({ onRefresh }: { onRefresh: () => void }) {
  return (
    <Menu
      as="div"
      className="relative inline-block text-left ltr:-mr-1.5 rtl:-ml-1.5"
    >
      <MenuButton
        as={Button}
        variant="flat"
        isIcon
        className="size-8 rounded-full"
      >
        <EllipsisHorizontalIcon className="size-5" />
      </MenuButton>
      <Transition
        as={Fragment}
        enter="transition ease-out"
        enterFrom="opacity-0 translate-y-2"
        enterTo="opacity-100 translate-y-0"
        leave="transition ease-in"
        leaveFrom="opacity-100 translate-y-0"
        leaveTo="opacity-0 translate-y-2"
      >
        <MenuItems className="dark:border-dark-500 dark:bg-dark-700 absolute z-100 mt-1.5 min-w-[10rem] rounded-lg border border-gray-300 bg-white py-1 shadow-lg shadow-gray-200/50 outline-hidden focus-visible:outline-hidden ltr:right-0 rtl:left-0 dark:shadow-none">
          <MenuItem>
            {({ focus }) => (
              <button
                onClick={onRefresh}
                className={clsx(
                  "flex h-9 w-full items-center px-3 tracking-wide outline-hidden transition-colors",
                  focus &&
                    "dark:bg-dark-600 dark:text-dark-100 bg-gray-100 text-gray-800",
                )}
              >
                <span>Làm mới dữ liệu</span>
              </button>
            )}
          </MenuItem>
          <MenuItem>
            {({ focus }) => (
              <button
                className={clsx(
                  "flex h-9 w-full items-center px-3 tracking-wide outline-hidden transition-colors",
                  focus &&
                    "dark:bg-dark-600 dark:text-dark-100 bg-gray-100 text-gray-800",
                )}
              >
                <span>Xuất báo cáo</span>
              </button>
            )}
          </MenuItem>
          <MenuItem>
            {({ focus }) => (
              <button
                className={clsx(
                  "flex h-9 w-full items-center px-3 tracking-wide outline-hidden transition-colors",
                  focus &&
                    "dark:bg-dark-600 dark:text-dark-100 bg-gray-100 text-gray-800",
                )}
              >
                <span>Cài đặt mục tiêu</span>
              </button>
            )}
          </MenuItem>

          <hr className="border-gray-150 dark:border-dark-500 mx-3 my-1.5 h-px" />

          <MenuItem>
            {({ focus }) => (
              <button
                className={clsx(
                  "flex h-9 w-full items-center px-3 tracking-wide outline-hidden transition-colors",
                  focus &&
                    "dark:bg-dark-600 dark:text-dark-100 bg-gray-100 text-gray-800",
                )}
              >
                <span>Xem chi tiết</span>
              </button>
            )}
          </MenuItem>
        </MenuItems>
      </Transition>
    </Menu>
  );
}
