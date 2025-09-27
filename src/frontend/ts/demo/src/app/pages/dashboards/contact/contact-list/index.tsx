// src/app/pages/dashboards/contact/contact-list/index.tsx
import { useMemo, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { Page } from "@/components/shared/Page";
import { Breadcrumbs } from "@/components/shared/Breadcrumbs";
import { Button } from "@/components/ui";
import AgGridView, {
  makeIndexCol,
  makeTextDateCol,
} from "@/components/datagrid/AgGridView";
import type {
  ColDef,
  RowSelectionOptions,
  ICellRendererParams,
} from "ag-grid-community";
import { JWT_HOST_API } from "@/configs/auth";

const breadcrumbs = [
  { title: "Liên hệ", path: "/dashboards/contact/list" },
  { title: "Danh sách" },
];

// Kiểu dữ liệu 1 hàng trong grid — khớp các field mà API /contact/list trả về
export type ContactRow = {
  id: string;
  name?: string | null;
  display_name?: string | null;
  email?: string | null;
  phone?: string | null;
  is_company?: boolean | string | null;
  tags?: string[] | string | null;
  created_at?: string | null;
  updated_at?: string | null;
  parent_id?: string | null;
};

export default function ContactListPage() {
  const navigate = useNavigate();

  // Cột cho AgGrid
  const columns = useMemo<ColDef<ContactRow>[]>(() => {
    return [
      makeIndexCol(), // cột STT
      { field: "display_name", headerName: "Tên hiển thị", flex: 1, minWidth: 180 },
      { field: "name", headerName: "Tên", flex: 1, minWidth: 160 },
      { field: "email", headerName: "Email", flex: 1, minWidth: 160 },
      { field: "phone", headerName: "SĐT", minWidth: 130 },
      {
        field: "is_company",
        headerName: "Công ty",
        width: 110,
        valueFormatter: (p) => {
          const v = p.value;
          if (typeof v === "boolean") return v ? "✔" : "";
          return v ?? "";
        },
      },
      {
        field: "tags",
        headerName: "Tags",
        flex: 1,
        minWidth: 160,
        valueFormatter: (p) => {
          const v = p.value as ContactRow["tags"];
          if (Array.isArray(v)) return v.join(", ");
          return v ?? "";
        },
      },
      makeTextDateCol<ContactRow>("created_at", "Tạo lúc"),
      makeTextDateCol<ContactRow>("updated_at", "Cập nhật"),
      { field: "id", headerName: "ID", minWidth: 120 },

      // Cột "Mở" sinh link — không cần onRowClicked/onRowDoubleClicked
      {
        headerName: "Mở",
        width: 110,
        cellRenderer: (p: ICellRendererParams<ContactRow>) => {
          const id = p.data?.id;
          if (!id) return "";
          return `<a href="/dashboards/contact/contact-create?id=${id}" class="text-primary-600 underline">Chi tiết</a>`;
        },
      },
    ];
  }, []);

  const rowSelection: RowSelectionOptions = { mode: "multiRow", headerCheckbox: false };

  // Header Authorization cho fetch trong AgGridView
  const getHeaders = useCallback(() => {
    const headers: Record<string, string> = {};
    const token = localStorage.getItem("authToken");
    if (token) headers.Authorization = `Bearer ${token}`;
    return headers;
  }, []);

  return (
    <Page title="Danh sách liên hệ">
      <div className="w-full px-(--margin-x) pb-8">
        <div className="flex items-center justify-between py-5 lg:py-6">
          <div className="flex items-center space-x-4">
            <h2 className="text-xl font-medium tracking-wide text-gray-800 dark:text-dark-50 lg:text-2xl">
              Danh sách liên hệ
            </h2>
            <div className="hidden self-stretch py-1 sm:flex">
              <div className="h-full w-px bg-gray-300 dark:bg-dark-600" />
            </div>
            <Breadcrumbs items={breadcrumbs} className="max-sm:hidden" />
          </div>

          <div className="flex items-center gap-2">
            <Button color="primary" onClick={() => navigate("/dashboards/contact/contact-create")}>
              + Tạo liên hệ
            </Button>
          </div>
        </div>

        <AgGridView<ContactRow>
          height={600}
          theme="quartz"
          themeSwitcher
          fetchUrl={`${JWT_HOST_API}/contact/list`}
          getHeaders={getHeaders}
          columnDefs={columns}
          rowSelection={rowSelection}
        />
      </div>
    </Page>
  );
}
