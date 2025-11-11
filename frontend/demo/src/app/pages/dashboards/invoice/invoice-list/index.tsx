// Import Dependencies
import { useMemo, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import AgGridView, { makeIndexCol } from "@/components/datagrid/AgGridView";
import type { ColDef, RowSelectionOptions, RowDoubleClickedEvent, ValueFormatterParams, ICellRendererParams } from "ag-grid-community";
import { Badge, Button } from "@/components/ui";
import { Page } from "@/components/shared/Page";
import { Breadcrumbs } from "@/components/shared/Breadcrumbs";
import { JWT_HOST_API } from "@/configs/auth";

// ----------------------------------------------------------------------

// Types
interface Invoice {
  id: string;
  tenant_id: string;
  name: string | null;
  ref_field: string | null;
  date: string;
  journal_id: string;
  currency_id: string;
  move_type: string;
  state: string;
  partner_id: string | null;
  partner_display_name: string | null;
  commercial_partner_id: string | null;
  invoice_date: string | null;
  invoice_date_due: string | null;
  invoice_origin: string | null;
  invoice_payment_term_id: string | null;
  invoice_user_id: string | null;
  fiscal_position_id: string | null;
  payment_state: string | null;
  payment_reference: string | null;
  amount_untaxed: number;
  amount_tax: number;
  amount_total: number;
  amount_residual: number;
  narration: string | null;
  created_at: string;
  updated_at: string;
  created_by: string;
  assignee_id: string | null;
}

// ----------------------------------------------------------------------

// Helper function to join URL
function joinUrl(base: string, path: string) {
  return `${base.replace(/\/$/, "")}/${path.replace(/^\//, "")}`;
}

// State Badge Cell Renderer
function StateBadgeRenderer(params: ICellRendererParams<Invoice>) {
  const state = params.value;
  if (!state) return null;

  const stateConfig: Record<string, { label: string; color: "primary" | "success" | "warning" | "error" | "neutral" }> = {
    draft: { label: "Draft", color: "neutral" },
    posted: { label: "Posted", color: "success" },
    cancel: { label: "Cancelled", color: "error" },
  };

  const config = stateConfig[state.toLowerCase()] || { label: state, color: "neutral" as const };

  return (
    <Badge variant="soft" color={config.color}>
      {config.label}
    </Badge>
  );
}

// Payment State Badge Cell Renderer
function PaymentStateBadgeRenderer(params: ICellRendererParams<Invoice>) {
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

  const config = stateConfig[paymentState.toLowerCase()] || { label: paymentState, color: "neutral" as const };

  return (
    <Badge variant="soft" color={config.color}>
      {config.label}
    </Badge>
  );
}

// Amount Formatter - format như loan-list
const formatAmount = (v?: number | null) => {
  if (v == null || v === undefined) return "";
  return new Intl.NumberFormat("vi-VN").format(Number(v));
};

function AmountCell(params: ICellRendererParams<Invoice, number>) {
  return <span>{formatAmount(params.value ?? null)}</span>;
}

// Move Type Formatter
function moveTypeFormatter(params: ValueFormatterParams<Invoice>) {
  const moveType = params.value;
  if (!moveType) return "";

  const typeMap: Record<string, string> = {
    out_invoice: "Customer Invoice",
    in_invoice: "Vendor Bill",
    out_refund: "Customer Credit Note",
    in_refund: "Vendor Credit Note",
    entry: "Journal Entry",
    out_receipt: "Sales Receipt",
    in_receipt: "Purchase Receipt",
  };

  return typeMap[moveType] || moveType;
}

// ----------------------------------------------------------------------

export default function InvoiceListPage() {
  const navigate = useNavigate();

  const columns = useMemo<ColDef<Invoice>[]>(() => [
    makeIndexCol(),
    {
      field: "name",
      headerName: "Number",
      minWidth: 150,
      flex: 1,
      valueGetter: (params) => params.data?.name || "-",
    },
    {
      field: "partner_display_name",
      headerName: "Customer",
      minWidth: 200,
      flex: 2,
      valueGetter: (params) => params.data?.partner_display_name || "-",
    },
    {
      field: "date",
      headerName: "Date",
      minWidth: 120,
      valueFormatter: (params) => {
        const value = params.value;
        if (!value) return "";
        try {
          const date = new Date(value);
          return date.toLocaleDateString("vi-VN");
        } catch {
          return String(value);
        }
      },
      filter: "agDateColumnFilter",
    },
    {
      field: "invoice_date",
      headerName: "Invoice Date",
      minWidth: 120,
      valueFormatter: (params) => {
        const value = params.value;
        if (!value) return "-";
        try {
          const date = new Date(value);
          return date.toLocaleDateString("vi-VN");
        } catch {
          return String(value);
        }
      },
      filter: "agDateColumnFilter",
    },
    {
      field: "invoice_date_due",
      headerName: "Due Date",
      minWidth: 120,
      valueFormatter: (params) => {
        const value = params.value;
        if (!value) return "-";
        try {
          const date = new Date(value);
          return date.toLocaleDateString("vi-VN");
        } catch {
          return String(value);
        }
      },
      filter: "agDateColumnFilter",
    },
    {
      field: "state",
      headerName: "Status",
      minWidth: 120,
      cellRenderer: StateBadgeRenderer,
      filter: "agSetColumnFilter",
      filterParams: {
        values: ["draft", "posted", "cancel"],
      },
    },
    {
      field: "payment_state",
      headerName: "Payment Status",
      minWidth: 140,
      cellRenderer: PaymentStateBadgeRenderer,
      filter: "agSetColumnFilter",
      filterParams: {
        values: ["not_paid", "in_payment", "paid", "partial"],
      },
    },
    {
      field: "amount_total",
      headerName: "Total",
      minWidth: 120,
      cellRenderer: AmountCell,
      cellStyle: { textAlign: "right" },
      headerClass: "ag-right-aligned-header",
      comparator: (valueA, valueB) => {
        return Number(valueA) - Number(valueB);
      },
    },
    {
      field: "amount_residual",
      headerName: "Amount Due",
      minWidth: 120,
      cellRenderer: AmountCell,
      cellStyle: { textAlign: "right" },
      headerClass: "ag-right-aligned-header",
      comparator: (valueA, valueB) => {
        return Number(valueA) - Number(valueB);
      },
    },
    {
      field: "move_type",
      headerName: "Type",
      minWidth: 150,
      valueFormatter: moveTypeFormatter,
      filter: "agSetColumnFilter",
    },
    {
      field: "invoice_origin",
      headerName: "Origin",
      minWidth: 150,
      valueGetter: (params) => params.data?.invoice_origin || "-",
    },
  ], []);

  const rowSelection: RowSelectionOptions = { mode: "multiRow", headerCheckbox: false };

  const getHeaders = useCallback((): Record<string, string> => {
    const headers: Record<string, string> = {
      "Accept": "application/json",
    };
    const token = localStorage.getItem("authToken");
    if (token) headers.Authorization = `Bearer ${token}`;
    return headers;
  }, []);

  const fetchUrl = joinUrl(JWT_HOST_API, "/invoice/list");

  const handleRowDoubleClick = useCallback((e: RowDoubleClickedEvent<Invoice>) => {
    const id = e.data?.id;
    if (id) {
      navigate(`/dashboards/invoice/invoice-create?id=${id}`);
    }
  }, [navigate]);

  const handleCreateInvoice = () => {
    navigate("/dashboards/invoice/invoice-create");
  };

  const breadcrumbs = useMemo(() => [
    { title: "Invoice", path: "/dashboards/invoice/invoice-list" },
    { title: "Danh sách" },
  ], []);

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

        <AgGridView<Invoice>
          title=""
          height={700}
          theme="quartz"
          themeSwitcher={false}
          schemeSwitcher={false}
          fetchUrl={fetchUrl}
          getHeaders={getHeaders}
          columnDefs={columns}
          rowSelection={rowSelection}
          onRowDoubleClicked={handleRowDoubleClick}
          domLayout="normal"
          defaultColDef={{
            resizable: true,
            sortable: true,
            filter: true,
            floatingFilter: true,
          }}
        />
      </div>
    </Page>
  );
}

