// Danh sách Trường Học - Load metadata từ API /school/metadata
import { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { Page } from "@/components/shared/Page";
import { Breadcrumbs } from "@/components/shared/Breadcrumbs";
import { Button } from "@/components/ui";
import AgGridView, { makeIndexCol } from "@/components/datagrid/AgGridView";
import type { ColDef, RowSelectionOptions, RowDoubleClickedEvent } from "ag-grid-community";
import { JWT_HOST_API } from "@/configs/auth";

export type SchoolRow = { id: string; [k: string]: any };

type MetaColumn = { name: string; label?: string; flex?: number; width?: number; minWidth?: number };
type SchoolMetadata = { list?: { columns?: MetaColumn[] } };

const api = axios.create({ baseURL: JWT_HOST_API });

const headerize = (s: string) => s.replace(/_/g, " ").replace(/\b\w/g, (m) => m.toUpperCase());

export default function SchoolListPage() {
  const navigate = useNavigate();
  const [cols, setCols] = useState<ColDef<SchoolRow>[] | null>(null);

  const rowSelection: RowSelectionOptions = { mode: "multiRow", headerCheckbox: false };
  const getHeaders = useCallback((): Record<string, string> => {
    const headers: Record<string, string> = {};
    const token = localStorage.getItem("authToken");
    if (token) headers.Authorization = `Bearer ${token}`;
    return headers;
  }, []);

  // 1️⃣ Load metadata từ API /school/metadata (load từ manifest.json ngoài binary)
  useEffect(() => {
    let stop = false;
    (async () => {
      try {
        const res = await api.get<SchoolMetadata>("/school/metadata", { headers: getHeaders() });
        const mcols = res.data?.list?.columns ?? [];
        
        // Map metadata columns → AG Grid columns
        const mapped: ColDef<SchoolRow>[] = [
          makeIndexCol(),
          ...mcols.map<ColDef<SchoolRow>>((c) => {
            const base: ColDef<SchoolRow> = {
              field: c.name as any,
              headerName: c.label || headerize(c.name),
            };
            if (typeof c.flex === "number") base.flex = c.flex;
            if (typeof c.width === "number") base.width = c.width;
            if (typeof c.minWidth === "number") base.minWidth = c.minWidth;
            return base;
          }),
        ];
        
        if (!mcols.some((c) => c.name === "id")) {
          mapped.push({ field: "id" as any, headerName: "ID", minWidth: 120 });
        }
        
        if (!stop) setCols(mapped);
      } catch (e) {
        console.error("❌ Lỗi load metadata:", e);
        if (!stop) setCols(null);
      }
    })();
    return () => { stop = true; };
  }, [getHeaders]);

  const handleRowDoubleClick = (e: RowDoubleClickedEvent<SchoolRow>) => {
    const id = e.data?.id;
    if (id) navigate(`/dashboards/school/school-create?id=${encodeURIComponent(id)}`);
  };

  const breadcrumbs = [
    { title: "Trường Học", path: "/dashboards/school/school-list" },
    { title: "Danh sách" },
  ];

  return (
    <Page title="Danh sách Trường Học">
      <div className="w-full px-(--margin-x) pb-8">
        <div className="flex items-center justify-between py-5 lg:py-6">
          <div className="flex items-center space-x-4">
            <h2 className="text-xl font-medium tracking-wide text-gray-800 dark:text-dark-50 lg:text-2xl">
              🏫 Danh sách Trường Học
            </h2>
            <div className="hidden self-stretch py-1 sm:flex">
              <div className="h-full w-px bg-gray-300 dark:bg-dark-600" />
            </div>
            <Breadcrumbs items={breadcrumbs} />
          </div>
          <div className="flex items-center gap-2">
            <Button color="primary" onClick={() => navigate("/dashboards/school/school-create")}>
              + Tạo Mới
            </Button>
          </div>
        </div>

        {/* 2️⃣ Hiển thị danh sách - Load từ API /school/list */}
        <AgGridView<SchoolRow>
          height={600}
          theme="quartz"
          themeSwitcher
          fetchUrl={`${JWT_HOST_API.replace(/\/$/, "")}/school/list`}
          getHeaders={getHeaders}
          columnDefs={cols ?? [makeIndexCol(), { field: "name" as any, headerName: "Tên trường", flex: 1 }]}
          rowSelection={rowSelection}
          onRowDoubleClicked={handleRowDoubleClick}
          domLayout="normal"
        />
      </div>
    </Page>
  );
}

