// loanlist.jsx
import { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { Page } from "components/shared/Page";
import { Breadcrumbs } from "components/shared/Breadcrumbs";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import DynamicList from "components/shared/DynamicList";

const breadcrumbs = [
  { title: "Hợp đồng vay", path: "/dashboards/loan/loan-1" },
  { title: "Danh sách" },
];

const api = axios.create({ baseURL: JWT_HOST_API });

const initialMetadata = (() => {
  try {
    const cached = JSON.parse(localStorage.getItem("loanMetadata"));
    return cached?.list?.columns ? cached : null;
  } catch {
    return null;
  }
})();

// 👉 Format tiền tệ kiểu VN: 10000000 -> 10.000.000
const formatCurrency = (value) =>
  typeof value === "number"
    ? new Intl.NumberFormat("vi-VN").format(value)
    : value;

// 👉 Convert ISO string to dd-mm-yyyy UTC
const toUTCDateString = (iso) => {
  if (!iso) return "";
  const d = new Date(iso);
  return `${d.getUTCDate().toString().padStart(2, "0")}-${(d.getUTCMonth() + 1)
    .toString()
    .padStart(2, "0")}-${d.getUTCFullYear()}`;
};

export default function LoanListPage() {
  const navigate = useNavigate();
  const [contracts, setContracts] = useState(() => {
    try {
      const cached = sessionStorage.getItem("loanListCache");
      return cached ? JSON.parse(cached) : [];
    } catch {
      return [];
    }
  });
  const [metadata, setMetadata] = useState(initialMetadata);
  const token = localStorage.getItem("authToken");

  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get("/loan/metadata");
      if (res.data?.list?.columns) {
        localStorage.setItem("loanMetadata", JSON.stringify(res.data));
        setMetadata(res.data);
      }
    } catch (err) {
      console.error("❌ Lỗi load metadata:", err);
    }
  }, []);

  const fetchContracts = useCallback(async () => {
    try {
      const res = await api.get("/loan/list", {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });
      setContracts(res.data);
      sessionStorage.setItem("loanListCache", JSON.stringify(res.data));
    } catch (err) {
      console.error("❌ Lỗi load danh sách hợp đồng:", err);
    }
  }, [token]);

  useEffect(() => {
    fetchMetadata();
    fetchContracts();
  }, [fetchMetadata, fetchContracts]);

  const handleRowClick = (row) => {
    if (!row?.id) {
      alert("⚠️ Không tìm thấy ID hợp đồng trong dòng dữ liệu");
      return;
    }
    navigate(`/dashboards/loan/loan-create?id=${row.id}`, {
      state: { preview: row },
    });
  };

  return (
    <Page title="📋 Danh sách hợp đồng vay">
      <div className="w-full px-(--margin-x) pb-8">
        <div className="flex items-center space-x-4 py-5 lg:py-6">
          <h2 className="text-xl font-medium tracking-wide text-gray-800 dark:text-dark-50 lg:text-2xl">
            Danh sách hợp đồng vay
          </h2>
          <div className="hidden self-stretch py-1 sm:flex">
            <div className="h-full w-px bg-gray-300 dark:bg-dark-600"></div>
          </div>
          <Breadcrumbs items={breadcrumbs} className="max-sm:hidden" />
        </div>

        {!metadata?.list?.columns && (
          <div className="animate-pulse rounded border p-4">
            Đang tải cấu hình danh sách…
          </div>
        )}

        {metadata?.list?.columns && (
          <DynamicList
            columns={metadata.list.columns}
            data={contracts.map((c) => ({
              ...c,
              current_principal: formatCurrency(c.current_principal),
              date_start: toUTCDateString(c.date_start),
              date_end: toUTCDateString(c.date_end),
            }))}
            onRowClick={handleRowClick}
          />
        )}
      </div>
    </Page>
  );
}
