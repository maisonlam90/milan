import { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Page } from "@/components/shared/Page";
import { Button } from "@/components/ui";
import AgGridView, {
  makeTextDateCol,
  makeIndexCol,
} from "@/components/datagrid/AgGridView";
import type {
  ColDef,
  RowSelectionOptions,
  RowDoubleClickedEvent,
  ICellRendererParams,
} from "ag-grid-community";
import { JWT_HOST_API } from "@/configs/auth";

export type LoanRow = {
  id: string;
  [key: string]: unknown;
};

const formatCurrency = (v?: number | null) =>
  typeof v === "number" ? new Intl.NumberFormat("vi-VN").format(v) : "";

function CurrencyCell(p: ICellRendererParams<LoanRow, number | null>) {
  return <span>{formatCurrency(p.value ?? null)}</span>;
}



export default function LoanListPage() {
  const navigate = useNavigate();
  const { i18n } = useTranslation(); // Get i18n instance to listen to language changes
  const [columnDefs, setColumnDefs] = useState<ColDef<LoanRow>[]>([]);

  const rowSelection: RowSelectionOptions = {
    mode: "multiRow",
    headerCheckbox: false,
  };

  const onRowDoubleClicked = useCallback(
    (e: RowDoubleClickedEvent<LoanRow>) => {
      if (!e.data?.id) return;
      navigate(`/dashboards/loan/loan-create?id=${e.data.id}`, {
        state: { preview: e.data },
      });
    },
    [navigate]
  );

  const getHeaders = useCallback(() => {
    const headers: Record<string, string> = {};
    const token = localStorage.getItem("authToken");
    if (token) headers.Authorization = `Bearer ${token}`;
    return headers;
  }, []);

  // 🧠 Tạo columnDefs từ metadata API
  const loadMetadata = useCallback(() => {
    const getHeaders = (): Record<string, string> => {
      const headers: Record<string, string> = {};
      const token = localStorage.getItem("authToken");
      if (token) headers.Authorization = `Bearer ${token}`;
      // Add Accept-Language header
      const urlParams = new URLSearchParams(window.location.search);
      const langParam = urlParams.get("lang");
      headers["Accept-Language"] = langParam || i18n.language || "vi";
      return headers;
    };

    fetch(`${JWT_HOST_API}/loan/metadata`, { headers: getHeaders() })
      .then((res) => res.json())
      .then((data) => {
        const cols = data?.list?.columns?.map((col: any): ColDef<LoanRow> => {
          if (col.key === "current_principal") {
            return {
              field: col.key,
              headerName: col.label,
              minWidth: 150,
              cellRenderer: CurrencyCell,
            };
          }
          if (col.key === "date_start" || col.key === "date_end") {
            return makeTextDateCol<LoanRow>(col.key, col.label);
          }
          
          return {
            field: col.key,
            headerName: col.label,
            minWidth: 120,
            flex: 1,
          };
        }) ?? [];

        setColumnDefs([
          makeIndexCol(),
          ...cols,
        ]);
      })
      .catch((err) => {
        console.error("❌ Lỗi load metadata:", err);
      });
  }, [i18n.language]);

  useEffect(() => {
    loadMetadata();
  }, [loadMetadata]);

  return (
    <Page title="Danh sách hợp đồng vay">
      <div className="w-full px-(--margin-x) pb-8">
        <div className="flex items-center justify-between py-5 lg:py-6">
          <h2 className="text-xl font-medium tracking-wide text-gray-800 dark:text-dark-50 lg:text-2xl">
            Danh sách hợp đồng vay
          </h2>
          <div className="flex items-center gap-2">
            <Button
              color="primary"
              onClick={() => navigate("/dashboards/loan/loan-create")}
            >
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
