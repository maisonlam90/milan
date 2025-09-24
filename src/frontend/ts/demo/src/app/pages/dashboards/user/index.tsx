"use client";

import { useEffect, useState } from "react";
import axios from "axios";
import { AgGridReact } from "ag-grid-react";
import {
  ModuleRegistry,
  AllCommunityModule,
  ColDef,
  themeQuartz,
} from "ag-grid-community";

// Đăng ký community modules
ModuleRegistry.registerModules([AllCommunityModule]);

// Tùy biến theme
const myTheme = themeQuartz.withParams({
  browserColorScheme: "dark",
  fontFamily: {
    googleFont: "IBM Plex Sans",
  },
  headerFontSize: 14,
});

// ==== Types ====
interface User {
  user_id: string;
  name: string;
  email: string;
  tenant_id: string;
  tenant_name: string;
  created_at: string;
}

export default function UserTable() {
  const [rowData, setRowData] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const token = localStorage.getItem("authToken");
        const res = await axios.get<User[]>(
          "http://localhost:3000/user/users",
          {
            headers: { Authorization: `Bearer ${token}` },
          }
        );
        setRowData(res.data || []);
      } catch (err) {
        console.error("❌ Lỗi lấy danh sách user:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchUsers();
  }, []);

  const columnDefs: ColDef<User | any>[] = [
    {
      headerName: "#",
      field: "stt" as any,
      width: 50,
      minWidth: 50,
      maxWidth: 50,
      valueGetter: (params) => (params.node ? params.node.rowIndex! + 1 : ""),
      sortable: false,
      filter: false,
      floatingFilter: false,
      suppressSizeToFit: true,
      flex: 0,
    },
    {
      headerName: "",
      field: "checkbox" as any,
      width: 50,
      minWidth: 50,
      maxWidth: 50,
      checkboxSelection: true,
      headerCheckboxSelection: true,
      sortable: false,
      filter: false,
      floatingFilter: false,
      suppressSizeToFit: true,
      flex: 0,
    },
    { field: "user_id", headerName: "ID", sortable: true, filter: true, floatingFilter: true },
    { field: "name", headerName: "Tên", sortable: true, filter: true, floatingFilter: true },
    { field: "email", headerName: "Email", sortable: true, filter: true, floatingFilter: true },
    { field: "tenant_id", headerName: "Tenant ID", sortable: true, filter: true, floatingFilter: true },
    {
      field: "tenant_name",
      headerName: "Tên tổ chức",
      sortable: true,
      filter: true,
      floatingFilter: true,
    },
    {
      field: "created_at",
      headerName: "Ngày tạo",
      sortable: true,
      filter: true,
      floatingFilter: true,
      valueFormatter: (params) =>
        new Date(params.value as string).toLocaleDateString("vi-VN"),
    },
  ];

  const defaultColDef: ColDef = {
    flex: 1,
    minWidth: 120,
    resizable: true,
    sortable: true,
    filter: true,
  };

  return (
    <div style={{ padding: "20px" }}>
      <h2 className="text-xl font-semibold mb-4">📊 Danh sách User</h2>

      {loading ? (
        <p>⏳ Đang tải dữ liệu...</p>
      ) : (
        <div
          style={{
            height: 500,
            width: "100%",
            border: "1px solid #ddd",
            borderRadius: 6,
            overflow: "hidden",
          }}
        >
          <AgGridReact<User>
            theme={myTheme}
            rowData={rowData}
            columnDefs={columnDefs}
            defaultColDef={defaultColDef}
            animateRows={true}
            pagination={true}
            paginationPageSize={10}
            rowSelection="multiple"
          />
        </div>
      )}
    </div>
  );
}
