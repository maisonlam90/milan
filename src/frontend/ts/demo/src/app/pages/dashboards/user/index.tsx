"use client";

import { useEffect, useMemo, useState, type CSSProperties } from "react";
import axios from "axios";
import { AgGridReact } from "ag-grid-react";
import {
  ModuleRegistry,
  ClientSideRowModelModule,
  TextFilterModule,
  NumberFilterModule,
  RowDragModule,
  RowSelectionModule,
  ValidationModule,
  ColDef,
  RowSelectionOptions,
  // Themes
  themeAlpine,
  themeBalham,
  themeMaterial,
  themeQuartz,
} from "ag-grid-community";

// Nếu bạn đã COPY CSS theme về cùng thư mục, có thể import tương đối:
// import "./ag-grid.css";
// import "./ag-theme-quartz.css";

ModuleRegistry.registerModules([
  TextFilterModule,
  NumberFilterModule,
  RowDragModule,
  RowSelectionModule,
  ClientSideRowModelModule,
  ...(process.env.NODE_ENV !== "production" ? [ValidationModule] : []),
]);

interface User {
  user_id: string;
  name: string;
  email: string;
  tenant_id: string;
  tenant_name: string;
  created_at: string;
}

const themes = [
  { id: "themeQuartz", theme: themeQuartz },
  { id: "themeBalham", theme: themeBalham },
  { id: "themeMaterial", theme: themeMaterial },
  { id: "themeAlpine", theme: themeAlpine },
];

type PartSelectorProps<T extends { id: string } | null> = {
  options: T[];
  value: T;
  setValue: (value: T) => void;
};
const PartSelector = <T extends { id: string; variant?: string } | null>({
  options,
  value,
  setValue,
}: PartSelectorProps<T>) => (
  <select
    onChange={(e) =>
      setValue(options.find((t) => t?.id === e.currentTarget.value)! || null)
    }
    style={{ marginRight: 16 }}
    value={value?.id}
  >
    {options.map((option, i) => (
      <option key={i} value={option?.id}>
        {option?.variant || option?.id || "(unchanged)"}
      </option>
    ))}
  </select>
);

export default function UserTable() {
  const [rowData, setRowData] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTheme, setActiveTheme] = useState(themes[0]);

  const themed = useMemo(
    () =>
      activeTheme.theme.withParams({
        browserColorScheme: "dark",
        fontFamily: { googleFont: "IBM Plex Sans" },
        headerFontSize: 14,
      }),
    [activeTheme]
  );

  const containerStyle = useMemo<CSSProperties>(
    () => ({ width: "100%", height: "100%", display: "flex", flexDirection: "column" }),
    []
  );
  const gridStyle = useMemo<CSSProperties>(() => ({ height: 500, width: "100%" }), []);

  useEffect(() => {
    (async () => {
      try {
        const token = localStorage.getItem("authToken");
        const res = await axios.get<User[]>("http://localhost:3000/user/users", {
          headers: { Authorization: `Bearer ${token}` },
        });
        setRowData(res.data || []);
      } catch (err) {
        console.error("❌ Lỗi lấy danh sách user:", err);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const columnDefs = useMemo<ColDef<User | any>[]>(() => [
    {
      headerName: "#",
      field: "stt" as any,
      width: 60,
      minWidth: 60,
      valueGetter: (p) => (p.node ? p.node.rowIndex! + 1 : ""),
      sortable: false,
      filter: false,
      suppressMenu: true,
      resizable: false,
      pinned: "left",
    },
    // ✅ Cột "Tên": CHỈ drag + filter, KHÔNG checkbox
    {
      field: "name",
      headerName: "Tên",
      rowDrag: true,
      filter: true,
      floatingFilter: true,
      // ❌ bỏ checkboxSelection và headerCheckboxSelection
    },
    { field: "email", headerName: "Email", filter: true, floatingFilter: true },
    { field: "tenant_id", headerName: "Tenant ID", filter: true, floatingFilter: true },
    { field: "tenant_name", headerName: "Tên tổ chức", filter: true, floatingFilter: true },
    {
      field: "created_at",
      headerName: "Ngày tạo",
      filter: true,
      floatingFilter: true,
      valueFormatter: (p) =>
        p.value ? new Date(p.value as string).toLocaleDateString("vi-VN") : "",
    },
    { field: "user_id", headerName: "ID", filter: true, floatingFilter: true },
  ], []);

  const defaultColDef = useMemo<ColDef>(() => ({
    editable: false,
    flex: 1,
    minWidth: 120,
    filter: true,
    sortable: true,
    resizable: true,
  }), []);

  // vẫn cho phép chọn nhiều dòng bằng click (không cần checkbox)
  const rowSelection = useMemo<RowSelectionOptions | "single" | "multiple">(
    () => ({ mode: "multiRow", headerCheckbox: false }),
    []
  );

  return (
    <div style={{ padding: 20 }}>
      <h2 className="text-xl font-semibold mb-3">Danh sách User</h2>

      <div style={{ marginBottom: 8 }}>
        Theme:{" "}
        <PartSelector options={themes} value={activeTheme} setValue={setActiveTheme} />
      </div>

      <div style={containerStyle}>
        <div style={gridStyle}>
          <AgGridReact<User>
            theme={themed}
            rowData={rowData}
            loading={loading}
            columnDefs={columnDefs}
            defaultColDef={defaultColDef}
            rowSelection={rowSelection}
            rowDragManaged={true}
            rowDragMultiRow={true}
            onRowDragEnd={(event) => {
              const ordered: User[] = [];
              for (let i = 0; i < event.api.getDisplayedRowCount(); i++) {
                const r = event.api.getDisplayedRowAtIndex(i);
                if (r?.data) ordered.push(r.data);
              }
              console.log("New order:", ordered.map(x => x.user_id));
            }}
          />
        </div>
      </div>
    </div>
  );
}
