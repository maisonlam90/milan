// src/app/pages/dashboards/loan/loan-list/index.tsx
import { useMemo, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { Page } from "@/components/shared/Page";
import { Button } from "@/components/ui";
import AgGridView, {
  makeIndexCol,
  makeTextDateCol,
} from "@/components/datagrid/AgGridView";
import type {
  ColDef,
  RowSelectionOptions,
  RowDoubleClickedEvent,
  ICellRendererParams,
} from "ag-grid-community";
import { JWT_HOST_API } from "@/configs/auth";

/** Kiểu dữ liệu 1 hàng (khớp với API /loan/list) */
export type LoanRow = {
  id: string;
  code?: string | null;
  customer_name?: string | null;
  current_principal?: number | null;
  date_start?: string | null; // ISO
  date_end?: string | null;   // ISO
  status?: string | null;
};

/** Format tiền tệ kiểu VN */
const formatCurrency = (v?: number | null) =>
  typeof v === "number" ? new Intl.NumberFormat("vi-VN").format(v) : "";

/** Ô tiền tệ */
function CurrencyCell(p: ICellRendererParams<LoanRow, number | null>) {
  return <span>{formatCurrency(p.value ?? null)}</span>;
}

/** Ô link mở chi tiết */
function ViewCell(p: ICellRendererParams<LoanRow, unknown>) {
  const navigate = useNavigate();
  const onOpen = useCallback(() => {
    if (!p.data?.id) return;
    navigate(`/dashboards/loan/loan-create?id=${p.data.id}`, {
      state: { preview: p.data },
    });
  }, [navigate, p.data]);
  return (
    <button
      type="button"
      onClick={onOpen}
      className="text-primary-600 hover:underline"
    >
      Mở
    </button>
  );
}

export default function LoanListPage() {
  const navigate = useNavigate();

  /** Cột */
  const columnDefs = useMemo<ColDef<LoanRow>[]>(() => {
    return [
      makeIndexCol(),
      { field: "code", headerName: "Mã HĐ", minWidth: 120 , rowDrag: true,},
      { field: "customer_name", headerName: "Khách hàng", flex: 1, minWidth: 180 },
      {
        field: "current_principal",
        headerName: "Dư nợ hiện tại",
        minWidth: 160,
        cellRenderer: CurrencyCell,
      },
      makeTextDateCol<LoanRow>("date_start", "Ngày bắt đầu"),
      makeTextDateCol<LoanRow>("date_end", "Ngày kết thúc"),
      { field: "status", headerName: "Trạng thái", minWidth: 120 },
      {
        field: "id",
        headerName: "Thao tác",
        minWidth: 100,
        pinned: "right",
        cellRenderer: ViewCell,
      },
    ];
  }, []);

  /** Chọn nhiều dòng (nếu cần) */
  const rowSelection: RowSelectionOptions = {
    mode: "multiRow",
    headerCheckbox: false,
  };

  /** Double click mở chi tiết */
  const onRowDoubleClicked = useCallback(
    (e: RowDoubleClickedEvent<LoanRow>) => {
      if (!e.data?.id) return;
      navigate(`/dashboards/loan/loan-create?id=${e.data.id}`, {
        state: { preview: e.data },
      });
    },
    [navigate]
  );

  /** Header Authorization */
  const getHeaders = useCallback(() => {
    const headers: Record<string, string> = {};
    const token = localStorage.getItem("authToken");
    if (token) headers.Authorization = `Bearer ${token}`;
    return headers;
  }, []);

  return (
    <Page title="📋 Danh sách hợp đồng vay">
      <div className="w-full px-(--margin-x) pb-8">
        <div className="flex items-center justify-between py-5 lg:py-6">
          <h2 className="text-xl font-medium tracking-wide text-gray-800 dark:text-dark-50 lg:text-2xl">
            Danh sách hợp đồng vay
          </h2>
          <div className="flex items-center gap-2">
            <Button color="primary" onClick={() => navigate("/dashboards/loan/loan-create")}>
              + Tạo hợp đồng
            </Button>
          </div>
        </div>

        <AgGridView<LoanRow>

          height={600}
          theme="quartz"
          themeSwitcher
          fetchUrl={`${JWT_HOST_API}/loan/list`}
          getHeaders={getHeaders}
          columnDefs={columnDefs}
          rowSelection={rowSelection}
          onRowDoubleClicked={onRowDoubleClicked}
        />
      </div>
    </Page>
  );
}
