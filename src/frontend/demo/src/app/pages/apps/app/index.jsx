// Import Dependencies
import { Page } from "components/shared/Page";
import { Toolbar } from "./Toolbar";
import { PostCard } from "./PostCard";
import { useEffect, useState } from "react";
import { JWT_HOST_API } from "configs/auth.config";
import axios from "axios";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function BlogCard6() {
  const [modules, setModules] = useState([]);
  const token = localStorage.getItem("authToken");

  useEffect(() => {
    api
      .get("/app/modules", {
        headers: { Authorization: `Bearer ${token}` },
      })
      .then((res) => setModules(res.data))
      .catch((err) => {
        console.error("❌ Lỗi fetch modules:", err);
      });
  }, [token]);

  return (
    <Page title="App Store">
      <div className="transition-content w-full px-(--margin-x) pb-8">
        <Toolbar setQuery={() => {}} query="" />
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
      </div>
    </Page>
  );
}
