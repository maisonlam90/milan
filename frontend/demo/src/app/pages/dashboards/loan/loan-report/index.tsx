// src/app/pages/dashboards/loan/loan-report/index.tsx
import { useMemo, useCallback, useState } from "react";
import { Page } from "@/components/shared/Page";
import { Card, Button } from "@/components/ui";
import AgGridView from "@/components/datagrid/AgGridView";
import axios from "axios";
import { JWT_HOST_API } from "@/configs/auth";
import type { ColDef, ValueFormatterParams } from "ag-grid-community";

/* =============== Types =============== */

type ID = string;

export interface PivotRow {
  contract_id: ID;
  contract_number?: string;
  contact_name?: string;
  date: string; // ISO yyyy-mm-dd hoặc datetime
  current_principal?: number | null;
  current_interest?: number | null;
  accumulated_interest?: number | null;
  total_paid_interest?: number | null;
  total_paid_principal?: number | null;
  payoff_due?: number | null;
  state?: string | null;
  [k: string]: unknown;
}

/* =============== API client =============== */
const api = axios.create({ baseURL: JWT_HOST_API });

export default function LoanReportPage() {
  const [loading, setLoading] = useState(false);
  // thay đổi để remount AgGridView => fetch lại dữ liệu
  const [reloadSeq, setReloadSeq] = useState(0);

  // token + header ổn định
  const tokenValue = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("authToken") || "" : ""),
    []
  );
  const getHeaders = useCallback((): Record<string, string> => {
    const h: Record<string, string> = {};
    if (tokenValue) h.Authorization = `Bearer ${tokenValue}`;
    return h;
  }, [tokenValue]);

  // format số VN
  const nf = useMemo(() => new Intl.NumberFormat("vi-VN"), []);

  // Cột cho AgGrid — không dùng filter/rightAligned để tránh cần modules
  const columnDefs = useMemo<ColDef<PivotRow>[]>(() => {
    const moneyFmt = (p: ValueFormatterParams<PivotRow, unknown>) =>
      typeof p.value === "number" ? nf.format(p.value as number) : "-";

    return [
      {
        field: "contract_number",
        headerName: "Số HĐ",
        minWidth: 160,
        sort: "desc",
        cellRenderer: (p: any) => {
          const id = p?.data?.contract_id as string | undefined;
          const label = p?.value as string | undefined;
          if (!id) return label ?? "-";
          return (
            <a
              href={`/dashboards/loan/loan-create?id=${id}`}
              target="_blank"
              rel="noopener noreferrer"
              className="font-semibold"
            >
              {label ?? id}
            </a>
          );
        },
      },
      { field: "contact_name", headerName: "Khách hàng", minWidth: 200, flex: 1 },
      { field: "contract_id", headerName: "Contract ID", minWidth: 300 },
      {
        field: "date",
        headerName: "Date",
        minWidth: 130,
        filter: "agTextColumnFilter", // Sử dụng text filter thay vì date filter
        floatingFilter: true,
        // KHÔNG set filter để tránh cần DateFilterModule
        valueFormatter: (p) => {
          const v = p.value as string | null | undefined;
          if (typeof v === "string" && /^\d{4}-\d{2}-\d{2}/.test(v)) {
            const y = v.slice(0, 4);
            const m = v.slice(5, 7);
            const d = v.slice(8, 10);
            return `${d}/${m}/${y}`;
          }
          return v ?? "-";
        },
      },
      // Các cột số: chỉ format, không rightAligned/cellClass/cellStyle
      { field: "current_principal", headerName: "Principal", minWidth: 130, valueFormatter: moneyFmt },
      { field: "current_interest", headerName: "Interest", minWidth: 120, valueFormatter: moneyFmt },
      { field: "accumulated_interest", headerName: "Accumulated", minWidth: 140, valueFormatter: moneyFmt },
      { field: "total_paid_interest", headerName: "Paid Interest", minWidth: 140, valueFormatter: moneyFmt },
      { field: "total_paid_principal", headerName: "Paid Principal", minWidth: 150, valueFormatter: moneyFmt },
      { field: "payoff_due", headerName: "Payoff Due", minWidth: 130, valueFormatter: moneyFmt },
      { field: "state", headerName: "State", minWidth: 110 },
    ];
  }, [nf]);

  const handlePivotNow = useCallback(async () => {
    setLoading(true);
    try {
      await api.post("/loan/report/pivot-now", null, {
        headers: getHeaders(),
      });
      // Re-mount AgGridView để fetch lại
      setReloadSeq((s) => s + 1);
    } catch {
      alert("❌ Lỗi khi tính toán lãi và tạo báo cáo.");
    } finally {
      setLoading(false);
    }
  }, [getHeaders]);

  return (
    <Page title="Báo cáo Pivot">
      <div className="px-4 py-6 space-y-6">
        <Button onClick={handlePivotNow} disabled={loading}>
          🔄 Tính lãi & tạo báo cáo
        </Button>

        <Card className="p-2">
          <AgGridView<PivotRow>
            key={reloadSeq}
            title="Pivot báo cáo hợp đồng vay"
            height={700}
            theme="quartz"
            themeSwitcher
            fetchUrl={`${JWT_HOST_API}/loan/report`}
            getHeaders={getHeaders}
            columnDefs={columnDefs}
            // Nếu AgGridView áp defaultColDef có floatingFilter mặc định,
            // bạn có thể truyền xuống để tắt hoàn toàn:
            // defaultColDef={{ floatingFilter: false, filter: false }}
          />
        </Card>
      </div>
    </Page>
  );
}
