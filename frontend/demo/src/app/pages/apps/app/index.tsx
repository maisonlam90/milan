// src/app/pages/dashboards/app-store/BlogCard6.tsx
import { useEffect, useMemo, useState, useCallback } from "react";
import axios from "axios";
import { Page } from "@/components/shared/Page";
import { Toolbar } from "./Toolbar";
import { PostCard } from "./PostCard";
import { JWT_HOST_API } from "@/configs/auth";

type ModuleItem = {
  module_name: string;
  display_name: string;
  enabled: boolean;
  can_enable?: boolean;
  // ... nếu BE có thêm trường khác thì bổ sung tại đây
};

const api = axios.create({ baseURL: JWT_HOST_API });

export default function BlogCard6() {
  const [modules, setModules] = useState<ModuleItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [scanning, setScanning] = useState(false);
  const [toggling, setToggling] = useState<Record<string, boolean>>({});
  const [query, setQuery] = useState("");

  const getHeaders = useCallback((): Record<string, string> => {
    const token = localStorage.getItem("authToken");
    return token ? { Authorization: `Bearer ${token}` } : {};
  }, []);

  const fetchModules = useCallback(async () => {
    try {
      setLoading(true);
      const res = await api.get<ModuleItem[]>("/app/modules", { headers: getHeaders() });
      setModules(Array.isArray(res.data) ? res.data : []);
    } catch (err) {
      console.error("❌ Lỗi fetch modules:", err);
      setModules([]);
    } finally {
      setLoading(false);
    }
  }, [getHeaders]);

  useEffect(() => {
    fetchModules();
  }, [fetchModules]);

  const handleScan = async () => {
    try {
      setScanning(true);
      await api.post("/app/scan", {}, { headers: getHeaders() });
      await fetchModules();
    } catch (err) {
      console.error("❌ Lỗi scan modules:", err);
    } finally {
      setScanning(false);
    }
  };

  // (Tuỳ BE) Toggle qua PATCH /app/modules/:module_name { enabled }
  const toggleModule = async (m: ModuleItem, next: boolean) => {
    try {
      setToggling((s) => ({ ...s, [m.module_name]: true }));
      await api.patch(
        `/app/modules/${encodeURIComponent(m.module_name)}`,
        { enabled: next },
        { headers: getHeaders() }
      );
      await fetchModules();
    } catch (err) {
      console.error("❌ Lỗi bật/tắt module:", err);
    } finally {
      setToggling((s) => ({ ...s, [m.module_name]: false }));
    }
  };

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return modules;
    return modules.filter(
      (m) =>
        m.display_name?.toLowerCase().includes(q) ||
        m.module_name?.toLowerCase().includes(q)
    );
  }, [modules, query]);

  return (
    <Page title="App Store">
      <div className="transition-content w-full px-(--margin-x) pb-8">
        {/* Thanh công cụ + nút Scan */}
        <div className="flex items-center justify-between mb-4">
          <Toolbar setQuery={setQuery} query={query} />
          <button
            onClick={handleScan}
            disabled={scanning}
            className="rounded-md px-3 py-2 text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 disabled:opacity-60"
          >
            {scanning ? "Đang quét..." : "Scan modules"}
          </button>
        </div>

        {/* Danh sách modules */}
        {loading ? (
          <p className="text-center py-10">Đang tải danh sách module...</p>
        ) : (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 sm:gap-5 lg:gap-6">
            {filtered.map((m) => {
              const readTime = m.enabled
                ? "✅ Đã bật"
                : m.can_enable
                ? "🟢 Có thể bật"
                : "⛔ Không thể bật";

              return (
                <div key={m.module_name} className="flex flex-col">
                  <PostCard
                    uid={m.module_name}
                    cover="/images/800x600.png"
                    title={m.display_name}
                    readTime={readTime}
                    author={{ name: m.module_name, avatar: "/images/200x200.png" }}
                    query={query}
                  />
                  <div className="mt-2">
                    <button
                      onClick={() => toggleModule(m, !m.enabled)}
                      disabled={toggling[m.module_name] || !m.can_enable}
                      className="w-full rounded-md px-3 py-2 text-sm font-medium text-white disabled:opacity-60
                                 bg-primary-600 hover:bg-primary-700"
                      title={!m.can_enable ? "Module không thể bật/tắt" : ""}
                    >
                      {toggling[m.module_name]
                        ? "Đang cập nhật…"
                        : m.enabled
                        ? "Tắt module"
                        : "Bật module"}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </Page>
  );
}
