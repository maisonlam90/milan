// src/app/pages/dashboards/contact-list/index.jsx
import { useEffect, useState, useCallback } from "react";
import { Page } from "components/shared/Page";
import { Breadcrumbs } from "components/shared/Breadcrumbs";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import DynamicList from "components/shared/DynamicList";
import { Button } from "components/ui";

const breadcrumbs = [
  { title: "Liên hệ", path: "/dashboards/contact/list" },
  { title: "Danh sách" },
];

const api = axios.create({ baseURL: JWT_HOST_API });

const initialMetadata = (() => {
  try {
    const cached = JSON.parse(localStorage.getItem("contactMetadata"));
    return cached?.list?.columns ? cached : null;
  } catch {
    return null;
  }
})();

export default function ContactListPage() {
  const [rows, setRows] = useState([]);
  const [metadata, setMetadata] = useState(initialMetadata);
  const token = localStorage.getItem("authToken");

  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get("/contact/metadata");
      if (res.data?.list?.columns) {
        localStorage.setItem("contactMetadata", JSON.stringify(res.data));
        setMetadata(res.data);
      }
    } catch (err) {
      console.error("❌ Lỗi load metadata:", err);
    }
  }, []);

  const fetchList = useCallback(async () => {
    try {
      const res = await api.get("/contact/list", {
        headers: { Authorization: `Bearer ${token}` },
      });
      const items = res.data?.items ?? res.data ?? [];
      const normalized = items.map((it) => ({
        ...it,
        tags: Array.isArray(it.tags) ? it.tags.join(", ") : it.tags,
        is_company:
          typeof it.is_company === "boolean" ? (it.is_company ? "✔" : "") : it.is_company,
      }));
      setRows(normalized);
    } catch (err) {
      console.error("❌ Lỗi load danh sách liên hệ:", err);
    }
  }, [token]);

  useEffect(() => {
    fetchMetadata();
    fetchList();
  }, [fetchMetadata, fetchList]);

  // 👉 Click row → trang contact-create (giống loan-2)
  const handleRowClick = (row) => {
    if (!row.id) {
      alert("⚠️ Không tìm thấy ID liên hệ");
      return;
    }
    window.location.href = `/dashboards/contact/contact-create?id=${row.id}`;
  };

  // DynamicList dùng col.key → map từ name → key
  const columnsForList =
    metadata?.list?.columns?.map((c) => ({ ...c, key: c.key ?? c.name })) ?? [];

  return (
    <Page title="📇 Danh sách liên hệ">
      <div className="w-full px-(--margin-x) pb-8">
        <div className="flex items-center justify-between py-5 lg:py-6">
          <div className="flex items-center space-x-4">
            <h2 className="text-xl font-medium tracking-wide text-gray-800 dark:text-dark-50 lg:text-2xl">
              Danh sách liên hệ
            </h2>
            <div className="hidden self-stretch py-1 sm:flex">
              <div className="h-full w-px bg-gray-300 dark:bg-dark-600"></div>
            </div>
            <Breadcrumbs items={breadcrumbs} className="max-sm:hidden" />
          </div>

          <div className="flex items-center gap-2">
            <Button
              color="primary"
              onClick={() => (window.location.href = "/dashboards/contact/contact-create")}
            >
              + Tạo liên hệ
            </Button>
          </div>
        </div>

        {columnsForList.length > 0 && (
          <DynamicList columns={columnsForList} data={rows} onRowClick={handleRowClick} />
        )}
      </div>
    </Page>
  );
}
