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

// prune tree theo allowed Set(['acl','user',...])
const prune = (nodes, allowed) =>
  nodes
    .map((n) => {
      const node = { ...n };
      if (Array.isArray(node.childs)) node.childs = prune(node.childs, allowed);
      const hasChildren = Array.isArray(node.childs) && node.childs.length > 0;
      if (node.type === NAV_TYPE_DIVIDER) return node; // giữ divider
      const key = node.moduleKey ?? moduleKeyFromPath(node.path); // 👈 ưu tiên moduleKey
      const visible = (key ? allowed.has(key) : node.public === true) || hasChildren;
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

  // chuẩn hoá: ["module.acl","user"] -> Set(['acl','user'])
  const allowed = useMemo(() => {
    const arr = Array.isArray(mods) ? mods : [];
    return new Set(arr.map((m) => (m.startsWith("module.") ? m.slice(7) : m)));
  }, [mods]);

  // lọc menu
  const filteredNav = useMemo(() => prune(navigation, allowed), [allowed]);

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
    <SimpleBar scrollableNodeProps={{ ref: scrollRef }} className="h-full overflow-x-hidden pb-6">
      {loading && <div className="p-3 text-xs text-gray-500">Đang tải menu…</div>}

      <Accordion value={expanded} onChange={setExpanded} className="space-y-1">
        {items.map((nav) => (
          <Group key={nav.id} data={nav} />
        ))}
        {items.length === 0 && !loading && (
          <div className="p-3 text-xs text-gray-500">Không có mục nào được cấp quyền</div>
        )}
      </Accordion>
    </SimpleBar>
  );
}
