// src/app/pages/dashboards/loan/collateral/CollateralPanel.tsx
import { useEffect, useMemo, useState, useCallback } from "react";
import { useForm, type UseFormReturn } from "react-hook-form";
import axios from "axios";
import { JWT_HOST_API } from "@/configs/auth";
import { Page } from "@/components/shared/Page";
import { Card, Button, Input } from "@/components/ui";
import AgGridView from "@/components/datagrid/AgGridView";
import type { ColDef, ValueFormatterParams } from "ag-grid-community";
import DynamicForm from "@/components/shared/DynamicForm";
import type { DynamicFieldConfig } from "@/components/shared/DynamicForm";

/* ====================== Types ====================== */

type ID = string;

export interface CollateralFormValues {
  asset_type: "vehicle" | "real_estate" | "jewelry" | "other";
  description: string;
  value_estimate: number | string | "";
  status: "available" | "in_use" | "released" | "liquidated";
}

interface CollateralItem {
  asset_id: ID;
  contract_id?: ID | null;
  contract_number?: string | null;
  asset_type: string;
  description?: string | null;
  value_estimate?: number | null;
  status?: string | null;
  created_at?: string | number | Date | null;
  [k: string]: unknown;
}

interface CollateralPanelProps {
  token?: string;
  readOnly?: boolean;
  contractId?: string;
}

/* ====================== API ====================== */

const api = axios.create({ baseURL: JWT_HOST_API });

/* ====================== Static field config ====================== */

const collateralFields: DynamicFieldConfig[] = [
  {
    name: "asset_type",
    label: "Loại tài sản",
    type: "select",
    width: 6,
    options: [
      { value: "vehicle", label: "Xe cộ" },
      { value: "real_estate", label: "Bất động sản" },
      { value: "jewelry", label: "Vàng/Trang sức" },
      { value: "other", label: "Khác" },
    ],
  },
  { name: "description", label: "Mô tả", type: "text", width: 12 },
  { name: "value_estimate", label: "Giá trị ước tính", type: "number", width: 6 },
  {
    name: "status",
    label: "Trạng thái",
    type: "select",
    width: 6,
    options: [
      { value: "available", label: "available" },
      { value: "in_use", label: "in_use" },
      { value: "released", label: "released" },
      { value: "liquidated", label: "liquidated" },
    ],
  },
];

/* ====================== Component ====================== */

export default function CollateralPanel({
  token,
  readOnly,
  contractId: propContractId,
}: CollateralPanelProps) {
  const [items, setItems] = useState<CollateralItem[]>([]);
  const [saving, setSaving] = useState(false);
  const [contractRef, setContractRef] = useState<string>(propContractId || "");
  const [loading, setLoading] = useState(false);
  const [selectedAssetId, setSelectedAssetId] = useState<string | null>(null);

  const form: UseFormReturn<CollateralFormValues> = useForm<CollateralFormValues>({
    defaultValues: {
      asset_type: "vehicle",
      description: "",
      value_estimate: "",
      status: "available",
    },
  });

  // fallback token từ localStorage nếu prop không được truyền
  const tokenValue = useMemo<string>(
    () => token || localStorage.getItem("authToken") || "",
    [token]
  );
  const authHeader = useMemo<Record<string, string>>(() => {
        const h: Record<string, string> = {};
        if (tokenValue) h.Authorization = `Bearer ${tokenValue}`;
        return h;
    }, [tokenValue]
  );

  const optionsMap = useMemo<Record<string, Array<{ value: string | number; label: string }>>>(
    () => ({}),
    []
  );

  // Load tất cả collateral (KHÔNG lọc theo contract_id)
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get<CollateralItem[]>("/loan/collateral", {
        headers: { ...authHeader },
      });
      setItems(res.data || []);
    } catch (e) {
      console.error("Load collateral failed:", e);
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, [authHeader]);

  useEffect(() => {
    load();
  }, [load]);

  const handleLoadClick = () => {
    load();
  };

  const handleSave = async () => {
    const isUpdate = !!selectedAssetId;
    const cid = propContractId || (contractRef || "").trim();
    if (!isUpdate && !cid) {
      alert("Vui lòng nhập Contract ID khi tạo tài sản mới.");
      return;
    }

    try {
      setSaving(true);
      const data = form.getValues();
      const payload = {
        asset_type: data.asset_type,
        description: data.description || undefined,
        value_estimate:
          data.value_estimate === "" || data.value_estimate == null
            ? undefined
            : Number(data.value_estimate),
        status: data.status,
      };

      if (selectedAssetId) {
        // update
        await api.post(`/loan/collateral/${selectedAssetId}`, payload, { headers: { ...authHeader } });
      } else {
        // create (kèm liên kết hợp đồng)
        await api.post("/loan/collateral", { ...payload, contract_id: cid }, { headers: { ...authHeader } });
      }

      // reset UI và reload
      setSelectedAssetId(null);
      form.reset({ asset_type: "vehicle", description: "", value_estimate: "", status: "available" });
      await load();
    } catch (e) {
      alert("❌ Lưu tài sản thất bại");
      console.error(e);
    } finally {
      setSaving(false);
    }
  };

  const handleCancelEdit = () => {
    setSelectedAssetId(null);
    form.reset({ asset_type: "vehicle", description: "", value_estimate: "", status: "available" });
  };

  const fmtNumber = (v: unknown): string => {
    if (v == null || v === "") return "-";
    const n = typeof v === "number" ? v : parseFloat(String(v));
    return Number.isFinite(n) ? n.toLocaleString("vi-VN") : String(v);
  };

  const fmtDateTime = (v: CollateralItem["created_at"]): string => {
    if (!v) return "-";
    const d = v instanceof Date ? v : new Date(v as any);
    return Number.isNaN(d.getTime()) ? "-" : d.toLocaleString();
    };

  // Cấu hình cột Ag Grid (cho phép sửa trực tiếp)
  const nf = useMemo(() => new Intl.NumberFormat("vi-VN"), []);
  const columnDefs = useMemo<ColDef<CollateralItem>[]>(() => {
    const moneyFmt = (p: ValueFormatterParams<CollateralItem, unknown>) =>
      typeof p.value === "number" ? nf.format(p.value as number) : fmtNumber(p.value);

    return [
      { field: "contract_number", headerName: "Số HĐ", minWidth: 200 },
      { field: "contract_id", headerName: "Contract ID", minWidth: 280 },
      { field: "asset_id", headerName: "Asset ID", minWidth: 280 },
      { field: "asset_type", headerName: "Loại", minWidth: 140 },
      { field: "description", headerName: "Mô tả", minWidth: 240, flex: 1 },
      {
        field: "value_estimate",
        headerName: "Giá trị (ước tính)",
        minWidth: 160,
        valueFormatter: moneyFmt,
      },
      { field: "status", headerName: "Trạng thái", minWidth: 140 },
      {
        field: "created_at",
        headerName: "Tạo lúc",
        minWidth: 180,
        valueFormatter: (p) => fmtDateTime(p.value as any),
      },
    ];
  }, [nf]);

  const handleRowClick = useCallback(
    (e: any) => {
      const row = e.data as CollateralItem;
      setSelectedAssetId(String(row.asset_id));
      form.setValue("asset_type", (row.asset_type as any) || "vehicle");
      form.setValue("description", (row.description as any) || "");
      form.setValue(
        "value_estimate",
        row.value_estimate == null ? "" : Number(row.value_estimate as any)
      );
      form.setValue("status", ((row.status as any) || "available") as any);
    },
    [form]
  );

  return (
    <Page title="Quản lý tài sản thế chấp">
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-1">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              Quản lý tài sản thế chấp
            </h2>
            {loading && (
              <span className="ml-3 text-xs text-gray-400">Đang tải dữ liệu…</span>
            )}
          </div>
        </div>

        <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
          <div className="col-span-12 lg:col-span-8">
            <Card className="p-4 sm:px-5">
              <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
                Thêm tài sản thế chấp
              </h3>
              <div className="mt-4 grid grid-cols-12 gap-3 items-end">
                <div className="col-span-9">
                  <label className="text-sm text-gray-600 block mb-1">
                    Số hợp đồng (Contract ID)
                  </label>
                  <Input
                    value={contractRef}
                    onChange={(e) => setContractRef(e.target.value)}
                    placeholder="d16c1890-dbad-46a0-8d12-3dca24860119"
                    disabled={!!propContractId}
                  />
                </div>
                <div className="col-span-3">
                  <Button onClick={handleLoadClick} className="w-full">
                    Làm mới danh sách
                  </Button>
                </div>
              </div>
              <div className="mt-4 space-y-4">
                <DynamicForm
                  form={form}
                  fields={collateralFields}
                  optionsMap={optionsMap}
                  disabled={!!readOnly}
                />
                {!readOnly && (
                  <div className="flex items-center justify-end gap-3">
                    {selectedAssetId && (
                      <Button variant="flat" onClick={handleCancelEdit} disabled={saving}>
                        Hủy
                      </Button>
                    )}
                    <Button onClick={handleSave} disabled={saving}>
                      {saving ? "Đang lưu..." : selectedAssetId ? "Lưu thay đổi" : "Thêm tài sản"}
                    </Button>
                  </div>
                )}
              </div>
            </Card>
          </div>
          <div className="col-span-12 lg:col-span-4"></div>
        </div>

        <div className="mt-6">
          <Card className="p-2">
            <AgGridView<CollateralItem>
              key={items.length + (loading ? 1 : 0)}
              title="Danh sách tài sản thế chấp"
              height={600}
              theme="quartz"
              themeSwitcher
              // dùng data local đã load để giữ logic filter/sort local
              rowData={items}
              columnDefs={columnDefs}
              onRowClicked={handleRowClick}
            />
          </Card>
        </div>
      </div>
    </Page>
  );
}
