// Import Dependencies
import {
  Menu,
  MenuButton,
  MenuItem,
  MenuItems,
  Transition,
} from "@headlessui/react";
import { EllipsisHorizontalIcon, InformationCircleIcon } from "@heroicons/react/20/solid";
import clsx from "clsx";
import { Fragment, useEffect, useState, useMemo } from "react";
import axios from "axios";

// Local Imports
import { Box, Button } from "@/components/ui";
import { JWT_HOST_API } from "@/configs/auth";

// ----------------------------------------------------------------------

interface PortfolioCategory {
  name: string;
  count: number;
  percentage: number;
  color: string;
}

interface PortfolioQuality {
  quality_score: string;
  total_active_contracts: number;
  categories: PortfolioCategory[];
}

export function LoanPortfolioQuality() {
  const [portfolioData, setPortfolioData] = useState<PortfolioQuality>({
    quality_score: "0.0",
    total_active_contracts: 0,
    categories: []
  });
  const [loading, setLoading] = useState(true);
  const [showLegend, setShowLegend] = useState(false);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("authToken") || "" : ""),
    []
  );

  const fetchPortfolioQuality = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const res = await axios.get(`${JWT_HOST_API}/loan/portfolio-quality`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setPortfolioData(res.data || {});
    } catch (error) {
      console.error("Error fetching portfolio quality:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPortfolioQuality();
  }, [token]);

  const getColorClass = (color: string) => {
    switch (color) {
      case "success": return "this:success";
      case "info": return "this:info";
      case "warning": return "this:warning";
      case "error": return "this:error";
      default: return "this:primary";
    }
  };

  const calculateBarWidths = () => {
    const total = portfolioData.categories.reduce((sum, cat) => sum + cat.percentage, 0);
    if (total === 0) return portfolioData.categories.map(() => 0);
    
    return portfolioData.categories.map(cat => 
      Math.max(1, Math.round((cat.percentage / total) * 100)) // Minimum 1% width for visibility
    );
  };

  const barWidths = calculateBarWidths();

  const getCategoryDescription = (name: string) => {
    switch (name) {
      case "Excellent": return "Đúng hạn (0 ngày quá hạn)";
      case "Very Good": return "Quá hạn nhẹ (1-7 ngày)";
      case "Good": return "Quá hạn vừa (8-30 ngày)";
      case "Poor": return "Quá hạn nặng (31-90 ngày)";
      case "Very Poor": return "Nợ xấu (trên 90 ngày)";
      default: return "";
    }
  };

  return (
    <Box className="col-span-12 lg:col-span-4">
      <div className="flex min-w-0 items-center justify-between">
        <div className="flex items-center gap-2">
          <h2 className="min-w-0 font-medium tracking-wide text-gray-800 dark:text-dark-100">
            Chất lượng danh mục cho vay
          </h2>
          <button
            onClick={() => setShowLegend(!showLegend)}
            className="text-gray-400 hover:text-gray-600 dark:text-dark-400 dark:hover:text-dark-200 transition-colors"
            title="Xem giải thích"
          >
            <InformationCircleIcon className="size-4" />
          </button>
        </div>
        <ActionMenu onRefresh={fetchPortfolioQuality} />
      </div>
      <div className="mt-3">
        <p>
          <span className="text-3xl text-gray-800 dark:text-dark-100">
            {loading ? "..." : portfolioData.quality_score}
          </span>
          <span className="this:info text-xs text-this dark:text-this-lighter ml-2">
            /10
          </span>
        </p>
        <p className="text-xs-plus">Điểm chất lượng tổng thể</p>
      </div>
      
      {/* Progress Bar */}
      <div className="mt-4 flex w-full gap-1 h-2">
        {portfolioData.categories.map((category, index) => (
          <div
            key={category.name}
            className={`${getColorClass(category.color)} rounded-full bg-this dark:bg-this-light`}
            style={{ width: `${barWidths[index]}%` }}
          />
        ))}
      </div>
      
      {/* Legend (Expandable) */}
      {showLegend && (
        <div className="mt-4 p-3 bg-gray-50 dark:bg-dark-600 rounded-lg border border-gray-200 dark:border-dark-500">
          <h3 className="text-sm font-medium text-gray-700 dark:text-dark-200 mb-2">
            Giải thích mức đánh giá:
          </h3>
          <div className="space-y-1 text-xs">
            <div className="flex items-center gap-2">
              <div className="this:success size-2 rounded-full bg-this dark:bg-this-light"></div>
              <span className="text-gray-600 dark:text-dark-300">🟢 <strong>Excellent:</strong> Đúng hạn (0 ngày quá hạn)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="this:info size-2 rounded-full bg-this dark:bg-this-light"></div>
              <span className="text-gray-600 dark:text-dark-300">🔵 <strong>Very Good:</strong> Quá hạn nhẹ (1-7 ngày)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="this:warning size-2 rounded-full bg-this dark:bg-this-light"></div>
              <span className="text-gray-600 dark:text-dark-300">🟡 <strong>Good:</strong> Quá hạn vừa (8-30 ngày)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="this:error size-2 rounded-full bg-this dark:bg-this-light"></div>
              <span className="text-gray-600 dark:text-dark-300">🟠 <strong>Poor:</strong> Quá hạn nặng (31-90 ngày)</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="this:error size-2 rounded-full bg-this dark:bg-this-light"></div>
              <span className="text-gray-600 dark:text-dark-300">🔴 <strong>Very Poor:</strong> Nợ xấu (trên 90 ngày)</span>
            </div>
          </div>
        </div>
      )}

      {/* Categories Table */}
      <div className="hide-scrollbar mt-4 min-w-full overflow-x-auto">
        <table className="w-full">
          <tbody>
                   {portfolioData.categories.map((category) => (
                     <tr key={category.name}>
                       <td className="whitespace-nowrap py-2">
                         <div className="flex items-center gap-2">
                           <div className={`${getColorClass(category.color)} size-3.5 rounded-full border-2 border-this dark:border-this-light`}></div>
                           <div className="flex flex-col">
                             <p className="font-medium tracking-wide text-gray-800 dark:text-dark-100">
                               {category.name}
                             </p>
                             <p className="text-xs text-gray-500 dark:text-dark-400">
                               {getCategoryDescription(category.name)}
                             </p>
                           </div>
                         </div>
                       </td>
                <td className="whitespace-nowrap py-2 text-end">
                  <p className="font-medium text-gray-800 dark:text-dark-100">
                    {loading ? "..." : category.count.toLocaleString()}
                  </p>
                </td>
                <td className="whitespace-nowrap py-2 text-end">
                  {loading ? "..." : `${category.percentage}%`}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      
      {/* Summary */}
      <div className="mt-3 text-center">
        <p className="text-xs text-gray-500 dark:text-dark-300">
          Tổng {loading ? "..." : portfolioData.total_active_contracts} hợp đồng đang hoạt động
        </p>
      </div>
    </Box>
  );
}

function ActionMenu({ onRefresh }: { onRefresh: () => void }) {
  return (
    <Menu
      as="div"
      className="relative inline-block text-left ltr:-mr-1 rtl:-ml-1"
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
        <MenuItems className="absolute z-100 mt-1.5 min-w-[10rem] rounded-lg border border-gray-300 bg-white py-1 shadow-lg shadow-gray-200/50 outline-hidden focus-visible:outline-hidden dark:border-dark-500 dark:bg-dark-700 dark:shadow-none ltr:right-0 rtl:left-0">
          <MenuItem>
            {({ focus }) => (
              <button
                onClick={onRefresh}
                className={clsx(
                  "flex h-9 w-full items-center px-3 tracking-wide outline-hidden transition-colors",
                  focus &&
                    "bg-gray-100 text-gray-800 dark:bg-dark-600 dark:text-dark-100",
                )}
              >
                <span>Làm mới dữ liệu</span>
              </button>
            )}
          </MenuItem>
        </MenuItems>
      </Transition>
    </Menu>
  );
}
