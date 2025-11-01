// Import Dependencies
import { ArrowUpIcon } from "@heroicons/react/24/outline";
import { useEffect, useState, useMemo } from "react";
import axios from "axios";

// Local Imports
import { Avatar } from "@/components/ui";
import { Seller, ContractCard } from "./ContractCard";
import { JWT_HOST_API } from "@/configs/auth";

// ----------------------------------------------------------------------

interface TopContractsResponse {
  top_contracts: any[];
  total_profit: number;
  summary: {
    title: string;
    description: string;
    growth_label: string;
    growth_value: number;
  };
}

export function TopContracts() {
  const [data, setData] = useState<TopContractsResponse>({
    top_contracts: [],
    total_profit: 0,
    summary: {
      title: "Top Hợp đồng",
      description: "Đang tải dữ liệu...",
      growth_label: "Tổng lợi nhuận",
      growth_value: 0,
    },
  });
  const [loading, setLoading] = useState(true);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("authToken") || "" : ""),
    []
  );

  const fetchTopContracts = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const res = await axios.get(`${JWT_HOST_API}/loan/top-contracts`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setData(res.data || {});
    } catch (error) {
      console.error("Error fetching top contracts:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTopContracts();
  }, [token]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
    }).format(amount);
  };

  // Function để format số tiền ngắn gọn
  const formatCompactCurrency = (amount: number) => {
    if (amount >= 1000000000) {
      return `${(amount / 1000000000).toFixed(1)} tỷ VND`;
    } else if (amount >= 1000000) {
      return `${(amount / 1000000).toFixed(1)} tr VND`;
    } else if (amount >= 1000) {
      return `${(amount / 1000).toFixed(1)}k VND`;
    }
    return formatCurrency(amount);
  };

  // Chuyển đổi dữ liệu từ API thành format Seller
  const sellers: Seller[] = data.top_contracts.map((contract) => ({
    uid: contract.uid,
    name: contract.name, // contract_number
    avatar: contract.avatar,
    contact_name: contract.contact_name,
    messages: null,
    mails: null,
    sells: contract.interest_collected, // Lợi nhuận đã thu
    target: contract.principal, // Số tiền gốc
    clients: Math.round(contract.completion_rate), // Tỷ lệ hoàn thành (%)
    relations: {
      calls: contract.relations.profit_rate, // Tỷ lệ lợi nhuận
      chatMessages: contract.relations.completion, // Tỷ lệ hoàn thành
      emails: contract.relations.efficiency, // Hiệu suất
    },
    awards: [
      // Tạo awards dựa trên performance
      ...(contract.relations.profit_rate > 0.1 ? [{
        uid: "1",
        label: "Lợi nhuận cao",
        image: "/images/awards/award-19.svg",
      }] : []),
      ...(contract.relations.completion > 0.5 ? [{
        uid: "2",
        label: "Hoàn thành tốt",
        image: "/images/awards/award-2.svg",
      }] : []),
      ...(contract.relations.efficiency > 0.5 ? [{
        uid: "3",
        label: "Hiệu suất cao",
        image: "/images/awards/award-5.svg",
      }] : []),
    ],
    // Thêm thông tin bổ sung
    contract_id: contract.contract_id,
    daily_profit: contract.daily_profit,
    days_active: contract.days_active,
    created_at: contract.created_at,
  }));

  return (
    <div className="bg-gray-150 dark:bg-dark-800 mt-4 grid grid-cols-12 gap-4 py-5 sm:mt-5 sm:gap-5 lg:mt-6 lg:gap-6">
      <div className="transition-content col-span-12 flex flex-col px-(--margin-x) lg:col-span-3 lg:ltr:pr-0 lg:rtl:pl-0">
        <h2 className="dark:text-dark-100 truncate text-base font-medium tracking-wide text-gray-800 lg:text-xl">
          {data.summary.title}
        </h2>

        <p className="mt-3 grow">
          {data.summary.description}
        </p>

        <div className="mt-4">
          <p>{data.summary.growth_label}</p>
          <div className="mt-1.5 flex items-center gap-2">
            <Avatar size={7} initialColor="success" initialVariant="soft">
              <ArrowUpIcon className="size-4" />
            </Avatar>
            <p className="dark:text-dark-100 text-base font-medium text-gray-800">
              {loading ? "..." : formatCompactCurrency(data.summary.growth_value)}
            </p>
          </div>
        </div>
      </div>

      <div className="hide-scrollbar transition-content col-span-12 flex gap-4 overflow-x-auto px-(--margin-x) lg:col-span-9 lg:ltr:pl-0 lg:rtl:pr-0">
        {loading ? (
          // Loading skeleton
          Array.from({ length: 4 }).map((_, index) => (
            <div key={index} className="w-72 shrink-0 animate-pulse">
              <div className="h-64 bg-gray-200 dark:bg-dark-600 rounded-lg"></div>
            </div>
          ))
        ) : (
          sellers.map((seller) => (
            <ContractCard key={seller.uid} {...seller} />
          ))
        )}
      </div>
    </div>
  );
}
