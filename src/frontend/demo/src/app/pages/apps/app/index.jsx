// Import Dependencies
import { Page } from "components/shared/Page";
import { Toolbar } from "./Toolbar";
import { PostCard } from "./PostCard";
import { useEffect, useState, useCallback } from "react";
import { JWT_HOST_API } from "configs/auth.config";
import axios from "axios";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function BlogCard6() {
  const [modules, setModules] = useState([]);
  const [loading, setLoading] = useState(false);
  const [scanning, setScanning] = useState(false);
  const token = localStorage.getItem("authToken");

  const fetchModules = useCallback(async () => {
    try {
      setLoading(true);
      const res = await api.get("/app/modules", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setModules(Array.isArray(res.data) ? res.data : []);
    } catch (err) {
      console.error("❌ Lỗi fetch modules:", err);
      setModules([]);
    } finally {
      setLoading(false);
    }
  }, [token]);

  useEffect(() => {
    fetchModules();
  }, [fetchModules]);

  const handleScan = async () => {
    try {
      setScanning(true);
      await api.post(
        "/app/scan",
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      );
      await fetchModules(); // refetch sau khi seed
    } catch (err) {
      console.error("❌ Lỗi scan & seed modules:", err);
      // tuỳ bạn: alert hoặc toast
    } finally {
      setScanning(false);
    }
  };

  return (
    <Page title="App Store">
      <div className="transition-content w-full px-(--margin-x) pb-8">
        {/* Thanh công cụ + nút Scan */}
        <div className="flex items-center justify-between mb-4">
          <Toolbar setQuery={() => {}} query="" />
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
            {modules.map((module, index) => (
              <PostCard
                key={index}
                cover="/images/800x600.png"
                title={module.display_name}
                readTime={
                  module.enabled
                    ? "✅ Đã bật"
                    : module.can_enable
                    ? "🟢 Có thể bật"
                    : "⛔ Không thể bật"
                }
                author_name={module.module_name}
                author_avatar="/images/200x200.png"
              />
            ))}
          </div>
        )}
      </div>
    </Page>
  );
}
