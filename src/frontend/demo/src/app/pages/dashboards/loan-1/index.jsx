import { useEffect, useState, useCallback } from "react";
import { Page } from "components/shared/Page";
import { Breadcrumbs } from "components/shared/Breadcrumbs";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import DynamicList from "components/shared/DynamicList";

// 👉 Breadcrumbs định nghĩa đường dẫn header
const breadcrumbs = [
  { title: "Hợp đồng vay", path: "/dashboards/loan/loan-1" },
  { title: "Danh sách" },
];

// 👉 Tạo instance axios có sẵn baseURL từ config
const api = axios.create({ baseURL: JWT_HOST_API });

// ⚙️ Load metadata từ cache nếu có (tránh nháy trắng)
const initialMetadata = (() => {
  try {
    const cached = JSON.parse(localStorage.getItem("loanMetadata"));
    return cached?.list?.columns ? cached : null;
  } catch {
    return null;
  }
})();

export default function LoanListPage() {
  const [contracts, setContracts] = useState([]);

  // 👉 Khởi tạo metadata từ localStorage nếu có
  const [metadata, setMetadata] = useState(initialMetadata);

  // 👉 Token auth từ localStorage
  const token = localStorage.getItem("authToken");

  // 📥 Gọi API lấy metadata nếu cache chưa có hoặc lỗi
  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get("/loan/metadata");
      if (res.data?.list?.columns) {
        localStorage.setItem("loanMetadata", JSON.stringify(res.data)); // cache lại
        setMetadata(res.data);
      }
    } catch (err) {
      console.error("❌ Lỗi load metadata:", err);
    }
  }, []);

  // 📥 Gọi API lấy danh sách hợp đồng
  const fetchContracts = useCallback(async () => {
    try {
      const res = await api.get("/loan/list", {
        headers: { Authorization: `Bearer ${token}` },
      });
      console.log("📄 Dữ liệu hợp đồng:", res.data);
      setContracts(res.data);
    } catch (err) {
      console.error("❌ Lỗi load danh sách hợp đồng:", err);
    }
  }, [token]);

  // 🚀 Gọi fetch metadata + danh sách khi trang load
  useEffect(() => {
    fetchMetadata();
    fetchContracts();
  }, [fetchMetadata, fetchContracts]);

  // 📍 Click vào dòng dữ liệu sẽ chuyển sang trang chi tiết
  const handleRowClick = (row) => {
    if (!row.id) {
      alert("⚠️ Không tìm thấy ID hợp đồng trong dòng dữ liệu");
      return;
    }
    window.location.href = `/dashboards/loan/loan-2?id=${row.id}`;
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

        {/* ⚠️ Chỉ render DynamicList nếu metadata đã sẵn sàng */}
        {metadata?.list?.columns && (
          <DynamicList
            columns={metadata.list.columns}
            data={contracts}
            onRowClick={handleRowClick}
          />
        )}
      </div>
    </Page>
  );
}
