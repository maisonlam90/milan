// Import Dependencies
import { useEffect, useState, useCallback, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import AgGridView, { makeIndexCol } from "@/components/datagrid/AgGridView";
import type { ColDef, RowSelectionOptions, RowDoubleClickedEvent, ICellRendererParams } from "ag-grid-community";
import { Badge, Button } from "@/components/ui";
import { Page } from "@/components/shared/Page";
import { Breadcrumbs } from "@/components/shared/Breadcrumbs";
import { JWT_HOST_API } from "@/configs/auth";

// ----------------------------------------------------------------------

// Types
export type InvoiceRow = {
  id: string;
  [key: string]: unknown;
};

// Helper function to join URL
function joinUrl(base: string, path: string) {
  return `${base.replace(/\/$/, "")}/${path.replace(/^\//, "")}`;
}

// Amount Formatter
const formatAmount = (v?: number | null) => {
  if (v == null || v === undefined) return "";
  return new Intl.NumberFormat("vi-VN").format(Number(v));
};

function AmountCell(params: ICellRendererParams<InvoiceRow, number>) {
  return <span>{formatAmount(params.value ?? null)}</span>;
}

// State Badge Cell Renderer
function StateBadgeRenderer(params: ICellRendererParams<InvoiceRow>) {
  const state = params.value;
  if (!state) return null;

  const stateConfig: Record<string, { label: string; color: "primary" | "success" | "warning" | "error" | "neutral" }> = {
    draft: { label: "Draft", color: "neutral" },
    posted: { label: "Posted", color: "success" },
    cancel: { label: "Cancelled", color: "error" },
  };

  const config = stateConfig[String(state).toLowerCase()] || { label: String(state), color: "neutral" as const };

  return (
    <Badge variant="soft" color={config.color}>
      {config.label}
    </Badge>
  );
}

// Payment State Badge Cell Renderer
function PaymentStateBadgeRenderer(params: ICellRendererParams<InvoiceRow>) {
  const paymentState = params.value;
  if (!paymentState) return null;

  const stateConfig: Record<string, { label: string; color: "primary" | "success" | "warning" | "error" | "neutral" }> = {
    not_paid: { label: "Not Paid", color: "error" },
    in_payment: { label: "In Payment", color: "warning" },
    paid: { label: "Paid", color: "success" },
    partial: { label: "Partial", color: "warning" },
    reversed: { label: "Reversed", color: "neutral" },
    invoicing_legacy: { label: "Legacy", color: "neutral" },
  };

  const config = stateConfig[String(paymentState).toLowerCase()] || { label: String(paymentState), color: "neutral" as const };

  return (
    <Badge variant="soft" color={config.color}>
      {config.label}
    </Badge>
  );
}

// ----------------------------------------------------------------------

export default function InvoiceListPage() {
  const navigate = useNavigate();
  const { i18n } = useTranslation(); // Get i18n instance to listen to language changes
  const [columnDefs, setColumnDefs] = useState<ColDef<InvoiceRow>[]>([]);

  const rowSelection: RowSelectionOptions = {
    mode: "multiRow",
    headerCheckbox: false,
  };

  const handleRowDoubleClick = useCallback((e: RowDoubleClickedEvent<InvoiceRow>) => {
    const id = e.data?.id;
    if (id) {
      navigate(`/dashboards/invoice/invoice-create?id=${id}`);
    }
  }, [navigate]);

  const getHeaders = useCallback((): Record<string, string> => {
    const headers: Record<string, string> = {};
    const token = localStorage.getItem("authToken");
    if (token) headers.Authorization = `Bearer ${token}`;
    return headers;
  }, []);

  const handleCreateInvoice = () => {
    navigate("/dashboards/invoice/invoice-create");
  };

  const breadcrumbs = useMemo(() => [
    { title: "Invoice", path: "/dashboards/invoice/invoice-list" },
    { title: "Danh sách" },
  ], []);

  // 🧠 Load columns from metadata API
  const loadMetadata = useCallback(() => {
    const getMetadataHeaders = (): Record<string, string> => {
      const headers: Record<string, string> = {};
      const token = localStorage.getItem("authToken");
      if (token) headers.Authorization = `Bearer ${token}`;
      // Add Accept-Language header
      const urlParams = new URLSearchParams(window.location.search);
      const langParam = urlParams.get("lang");
      headers["Accept-Language"] = langParam || i18n.language || "vi";
      return headers;
    };

    fetch(joinUrl(JWT_HOST_API, "/invoice/metadata"), { headers: getMetadataHeaders() })
      .then((res) => res.json())
      .then((data) => {
        const cols = data?.list?.columns?.map((col: any): ColDef<InvoiceRow> => {
          const key = col.key;
          
          // Special handling for date fields
          if (key === "invoice_date" || key === "invoice_date_due" || key === "date") {
            return {
              field: key,
              headerName: col.label,
              minWidth: 120,
              valueFormatter: (params) => {
                const value = params.value;
                if (!value) return "-";
                try {
                  const date = new Date(String(value));
                  return date.toLocaleDateString("vi-VN");
                } catch {
                  return String(value);
                }
              },
              filter: "agDateColumnFilter",
            };
          }
          
          // Special handling for amount fields
          if (key === "amount_total" || key === "amount_residual" || key === "amount_untaxed" || key === "amount_tax") {
            return {
              field: key,
              headerName: col.label,
              minWidth: 120,
              cellRenderer: AmountCell,
              cellStyle: { textAlign: "right" },
              headerClass: "ag-right-aligned-header",
              comparator: (valueA, valueB) => {
                return Number(valueA || 0) - Number(valueB || 0);
              },
            };
          }
          
          // Special handling for state field
          if (key === "state") {
            return {
              field: key,
              headerName: col.label,
              minWidth: 120,
              cellRenderer: StateBadgeRenderer,
              filter: "agSetColumnFilter",
              filterParams: {
                values: ["draft", "posted", "cancel"],
              },
            };
          }
          
          // Special handling for payment_state field
          if (key === "payment_state") {
            return {
              field: key,
              headerName: col.label,
              minWidth: 140,
              cellRenderer: PaymentStateBadgeRenderer,
              filter: "agSetColumnFilter",
              filterParams: {
                values: ["not_paid", "in_payment", "paid", "partial"],
              },
            };
          }
          
          // Default column
          return {
            field: key,
            headerName: col.label,
            minWidth: 150,
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
        // Fallback to basic columns if metadata fails
        setColumnDefs([
          makeIndexCol(),
          { field: "name", headerName: "Number", minWidth: 150 },
          { field: "partner_display_name", headerName: "Customer", minWidth: 200 },
          { field: "invoice_date", headerName: "Invoice Date", minWidth: 120 },
          { field: "amount_total", headerName: "Total", minWidth: 120, cellRenderer: AmountCell },
          { field: "state", headerName: "Status", minWidth: 120, cellRenderer: StateBadgeRenderer },
        ]);
      });
  }, [i18n.language]);

  useEffect(() => {
    loadMetadata();
  }, [loadMetadata]);

  const fetchUrl = joinUrl(JWT_HOST_API, "/invoice/list");

  return (
    <Page title="Danh sách hóa đơn">
      <div className="w-full px-(--margin-x) pb-8">
        <div className="flex items-center justify-between py-5 lg:py-6">
          <div className="flex items-center space-x-4">
            <h2 className="text-xl font-medium tracking-wide text-gray-800 dark:text-dark-50 lg:text-2xl">
              Danh sách hóa đơn
            </h2>
            <div className="hidden self-stretch py-1 sm:flex">
              <div className="h-full w-px bg-gray-300 dark:bg-dark-600" />
            </div>
            <Breadcrumbs items={[...breadcrumbs]} />
          </div>
          <div className="flex items-center gap-2">
            <Button color="primary" onClick={handleCreateInvoice}>
              + Tạo hóa đơn
            </Button>
          </div>
        </div>

        <AgGridView<InvoiceRow>
          title=""
          height={700}
          theme="quartz"
          themeSwitcher
          fetchUrl={fetchUrl}
          getHeaders={getHeaders}
          columnDefs={columnDefs}
          rowSelection={rowSelection}
          onRowDoubleClicked={handleRowDoubleClick}
        />
      </div>
    </Page>
  );
}

