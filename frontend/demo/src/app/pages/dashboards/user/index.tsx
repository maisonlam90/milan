import { useMemo } from "react";
import AgGridView, { makeIndexCol, makeTextDateCol } from "@/components/datagrid/AgGridView";
import type { ColDef, RowSelectionOptions } from "ag-grid-community";
import { JWT_HOST_API } from "@/configs/auth";

type User = {
  user_id: string;
  name: string;
  email: string;
  tenant_id: string;
  tenant_name: string;
  created_at: string;
};

// Ghép URL an toàn, tránh thừa/thiếu dấu '/'
function joinUrl(base: string, path: string) {
  return `${base.replace(/\/$/, "")}/${path.replace(/^\//, "")}`;
}

export default function UserGrid() {
  const columns = useMemo<ColDef<User>[]>(() => [
    makeIndexCol(),
    { field: "name", headerName: "Tên", rowDrag: true },
    { field: "email", headerName: "Email" },
    { field: "tenant_id", headerName: "Tenant ID" },
    { field: "tenant_name", headerName: "Tên tổ chức" },
    makeTextDateCol<User>("created_at", "Ngày tạo"),
    { field: "user_id", headerName: "ID" },
  ], []);

  const rowSelection: RowSelectionOptions = { mode: "multiRow", headerCheckbox: false };

  const fetchUrl = joinUrl(JWT_HOST_API, "/user/users"); // ✅ dùng base từ env/config

  return (
    <AgGridView<User>
      title="Danh sách User"
      height={700}
      theme="quartz"
      themeSwitcher
      fetchUrl={fetchUrl}
      getHeaders={() => {
        const headers: Record<string, string> = {
          "Accept": "application/json",
        };
        const token = localStorage.getItem("authToken");
        if (token) headers.Authorization = `Bearer ${token}`;
        return headers;
      }}
      columnDefs={columns}
      rowSelection={rowSelection}
    />
  );
}
