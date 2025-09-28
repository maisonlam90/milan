import { useMemo } from "react";
import AgGridView, { makeIndexCol, makeTextDateCol } from "@/components/datagrid/AgGridView";
import type { ColDef, RowSelectionOptions } from "ag-grid-community";

type User = {
  user_id: string;
  name: string;
  email: string;
  tenant_id: string;
  tenant_name: string;
  created_at: string;
};

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

  return (
    <AgGridView<User>
      title="Danh sách User"
      height={700}
      theme="quartz"
      themeSwitcher   // ✅ bật dropdown chọn theme
      fetchUrl="http://localhost:3000/user/users"
      getHeaders={() => {
        const headers: Record<string, string> = {};
        const token = localStorage.getItem("authToken");
        if (token) headers.Authorization = `Bearer ${token}`;
        return headers;
      }}
      columnDefs={columns}
      rowSelection={rowSelection}
    />
  );
}
