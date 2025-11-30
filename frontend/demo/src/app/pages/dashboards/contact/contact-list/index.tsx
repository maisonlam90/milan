// src/app/pages/dashboards/contact/contact-list/index.tsx
import { useEffect, useMemo, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import axios from "axios";
import { Page } from "@/components/shared/Page";
import { Breadcrumbs } from "@/components/shared/Breadcrumbs";
import { Button } from "@/components/ui";
import AgGridView, { makeIndexCol } from "@/components/datagrid/AgGridView";
import type { ColDef, RowSelectionOptions, RowDoubleClickedEvent, ValueFormatterParams } from "ag-grid-community";
import { JWT_HOST_API } from "@/configs/auth";

export type ContactRow = { id: string; [k: string]: any };

type MetaColumn = { name: string; label?: string; headerName?: string; flex?: number; width?: number; minWidth?: number; type?: string; visible?: boolean };
type ContactMetadata = { list?: { columns?: MetaColumn[] } };

const api = axios.create({ baseURL: JWT_HOST_API });

const headerize = (s: string) => s.replace(/_/g, " ").replace(/\b\w/g, (m) => m.toUpperCase());
const fmtDate = (p: ValueFormatterParams) => {
  const v = p.value;
  if (!v) return "";
  const s = String(v).trim().replace(" ", "T");
  const d = new Date(s);
  return isNaN(d.getTime())
    ? String(v)
    : new Intl.DateTimeFormat("vi-VN", { year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit" }).format(d);
};

export default function ContactListPage() {
  const navigate = useNavigate();
  const { i18n } = useTranslation(); // Get i18n instance to listen to language changes
  const [cols, setCols] = useState<ColDef<ContactRow>[] | null>(null);

  const rowSelection: RowSelectionOptions = { mode: "multiRow", headerCheckbox: false };
  const getHeaders = useCallback((): Record<string, string> => {
    const headers: Record<string, string> = {};
    const token = localStorage.getItem("authToken");
    if (token) headers.Authorization = `Bearer ${token}`;
    return headers;
  }, []);

  // load metadata tối giản
  const loadMetadata = useCallback(() => {
    let stop = false;
    (async () => {
      try {
        // Add Accept-Language header
        const headers = getHeaders();
        const urlParams = new URLSearchParams(window.location.search);
        const langParam = urlParams.get("lang");
        headers["Accept-Language"] = langParam || i18n.language || "vi";
        
        const res = await api.get<ContactMetadata>("/contact/metadata", { headers });
        const mcols = res.data?.list?.columns ?? [];
        const mapped: ColDef<ContactRow>[] = [
          makeIndexCol(),
          ...mcols
            .filter((c) => c.visible !== false)
            .map<ColDef<ContactRow>>((c) => {
              const base: ColDef<ContactRow> = {
                field: c.name as any, // metadata -> field
                headerName: c.label || c.headerName || headerize(c.name),
              };
              if (typeof c.flex === "number") base.flex = c.flex;
              if (typeof c.width === "number") base.width = c.width;
              if (typeof c.minWidth === "number") base.minWidth = c.minWidth;
              // hiển thị ngày đơn giản nếu là created_at/updated_at
              if (c.name === "created_at" || c.name === "updated_at" || c.type === "date") {
                base.valueFormatter = fmtDate;
                base.minWidth ??= 150;
              }
              return base;
            }),
        ];
        if (!mcols.some((c) => c.name === "id")) mapped.push({ field: "id" as any, headerName: "ID", minWidth: 120 });
        if (!stop) setCols(mapped);
      } catch (e) {
        console.error("metadata error:", e);
        if (!stop) setCols(null);
      }
    })();
    return () => { stop = true; };
  }, [getHeaders, i18n.language]);

  useEffect(() => {
    loadMetadata();
  }, [loadMetadata]);

  const handleRowDoubleClick = (e: RowDoubleClickedEvent<ContactRow>) => {
    const id = e.data?.id;
    if (id) navigate(`/dashboards/contact/contact-create?id=${encodeURIComponent(id)}`);
  };

  const breadcrumbs = useMemo(() => [
    { title: "Liên hệ", path: "/dashboards/contact/contact-list" },
    { title: "Danh sách" },
  ], []);

  return (
    <Page title="Danh sách liên hệ">
      <div className="w-full px-(--margin-x) pb-8">
        <div className="flex items-center justify-between py-5 lg:py-6">
          <div className="flex items-center space-x-4">
            <h2 className="text-xl font-medium tracking-wide text-gray-800 dark:text-dark-50 lg:text-2xl">Danh sách liên hệ</h2>
            <div className="hidden self-stretch py-1 sm:flex"><div className="h-full w-px bg-gray-300 dark:bg-dark-600" /></div>
            <Breadcrumbs items={[...breadcrumbs]} />
          </div>
          <div className="flex items-center gap-2">
            <Button color="primary" onClick={() => navigate("/dashboards/contact/contact-create")}>+ Tạo liên hệ</Button>
          </div>
        </div>

        <AgGridView<ContactRow>
          height={600}
          theme="quartz"
          themeSwitcher
          fetchUrl={`${JWT_HOST_API.replace(/\/$/, "")}/contact/list`}
          getHeaders={getHeaders}
          columnDefs={cols ?? [makeIndexCol(), { field: "name" as any, headerName: "Tên", flex: 1 }]} // fallback rất gọn
          rowSelection={rowSelection}
          onRowDoubleClicked={handleRowDoubleClick}
          domLayout="normal"
        />
      </div>
    </Page>
  );
}
