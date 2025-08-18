import { useLocation } from "react-router-dom";
import { useEffect, useMemo, useRef, useState } from "react";
import { useDidUpdate, useIsomorphicEffect } from "hooks";
import SimpleBar from "simplebar-react";
import axios from "axios";

import { navigation } from "app/navigation";
import { Group } from "./Group";
import { Accordion } from "components/ui";
import { isRouteActive } from "utils/isRouteActive";
import { NAV_TYPE_DIVIDER } from "constants/app.constant";
import { JWT_HOST_API } from "configs/auth.config";

// '/dashboards/<key>/...' -> '<key>'
const moduleKeyFromPath = (p) => {
  const m = p?.match(/^\/dashboards\/([^/]+)/);
  return m ? m[1] : null;
};

// prune cây theo allowed permission + allowedKeys
const prune = (nodes, allowed, allowedKeys) =>
  nodes
    .map((n) => {
      const node = { ...n };
      if (Array.isArray(node.childs)) {
        node.childs = prune(node.childs, allowed, allowedKeys);
      }
      const hasChildren = Array.isArray(node.childs) && node.childs.length > 0;

      if (node.type === NAV_TYPE_DIVIDER) return node; // giữ divider

      // Lấy key module từ path hoặc moduleKey gán sẵn
      const key = node.moduleKey ?? moduleKeyFromPath(node.path);

      // Quyền cụ thể cho node (nếu config menu có `permission`, dùng trực tiếp)
      // nếu không, mặc định "<key>.access"
      const perm = node.permission ?? (key ? `${key}.access` : null);

      // Cho hiển thị nếu:
      // - public
      // - hoặc có con
      // - hoặc khớp quyền cụ thể (loan.access)
      // - hoặc khớp theo key (tương thích dữ liệu cũ chỉ truyền 'loan')
      const visible =
        node.public === true ||
        hasChildren ||
        (perm ? allowed.has(perm) : false) ||
        (key ? allowedKeys.has(key) : false);

      return visible ? node : null;
    })
    .filter(Boolean);

export function Menu() {
  const { pathname } = useLocation();
  const scrollRef = useRef(null);

  // tải quyền module (không tạo hook riêng)
  const [mods, setMods] = useState(null); // null=loading
  useEffect(() => {
    const token = localStorage.getItem("authToken");
    if (!token) return setMods([]);
    axios
      .get(`${JWT_HOST_API}acl/me/modules`, {
        headers: { Authorization: `Bearer ${token}` },
      })
      .then((r) => setMods(Array.isArray(r.data) ? r.data : []))
      .catch(() => setMods([]));
  }, []);

  // chuẩn hoá:
  // - "module.loan.access" -> "loan.access"
  // - giữ nguyên "loan.access" nếu đã đúng
  // - vẫn giữ tương thích nếu API trả về chỉ "loan"
  const allowed = useMemo(() => {
    const arr = Array.isArray(mods) ? mods : [];
    return new Set(arr.map((m) => (m.startsWith("module.") ? m.slice(7) : m)));
  }, [mods]);

  // Tập các module key rút ra từ permission để so khớp theo key:
  // - "loan.access" -> "loan"
  // - "user" -> "user"
  const allowedKeys = useMemo(() => {
    const s = new Set();
    allowed.forEach((p) => {
      if (typeof p !== "string") return;
      const k = p.includes(".") ? p.split(".")[0] : p;
      if (k) s.add(k);
    });
    return s;
  }, [allowed]);

  // lọc menu
  const filteredNav = useMemo(
    () => prune(navigation, allowed, allowedKeys),
    [allowed, allowedKeys]
  );

  // điều khiển accordion như cũ, nhưng dựa trên nav đã lọc
  const [expanded, setExpanded] = useState(null);
  useDidUpdate(() => {
    const g = filteredNav.find((x) => x.path && isRouteActive(x.path, pathname));
    const c =
      g?.childs?.find((x) => x.path && isRouteActive(x.path, pathname)) || null;
    const next = c?.path || null;
    if (next !== expanded) setExpanded(next);
  }, [pathname, filteredNav, expanded]);

  useIsomorphicEffect(() => {
    const el = scrollRef.current?.querySelector("[data-menu-active='true']");
    el?.scrollIntoView({ block: "center" });
  }, []);

  const loading = mods === null;
  const items = filteredNav;

  return (
    <SimpleBar
      scrollableNodeProps={{ ref: scrollRef }}
      className="h-full overflow-x-hidden pb-6"
    >
      {loading && <div className="p-3 text-xs text-gray-500">Đang tải menu…</div>}

      <Accordion value={expanded} onChange={setExpanded} className="space-y-1">
        {items.map((nav) => (
          <Group key={nav.id} data={nav} />
        ))}
        {items.length === 0 && !loading && (
          <div className="p-3 text-xs text-gray-500">
            Không có mục nào được cấp quyền
          </div>
        )}
      </Accordion>
    </SimpleBar>
  );
}
