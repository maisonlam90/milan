// src/app/pages/dashboards/loan/collateral/CollateralPanel.tsx
import { useEffect, useMemo, useState, useCallback } from "react";
import { useForm, type UseFormReturn } from "react-hook-form";
import axios from "axios";
import { JWT_HOST_API } from "@/configs/auth";
import { Page } from "@/components/shared/Page";
import { Card, Button, Input } from "@/components/ui";
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
  contract_id?: ID;
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

  const handleCreate = async () => {
    const cid = propContractId || (contractRef || "").trim();
    if (!cid) {
      alert("Vui lòng nhập số hợp đồng (Contract ID) trước khi thêm tài sản.");
      return;
    }

    try {
      setSaving(true);
      const data = form.getValues();
      const payload = {
        ...data,
        value_estimate:
          data.value_estimate === "" || data.value_estimate == null
            ? undefined
            : Number(data.value_estimate),
        contract_id: cid, // liên kết khi tạo
      };
      await api.post("/loan/collateral", payload, { headers: { ...authHeader } });
      form.reset({
        asset_type: "vehicle",
        description: "",
        value_estimate: "",
        status: "available",
      });
      load();
    } catch (e) {
      alert("❌ Tạo tài sản thất bại");
      console.error(e);
    } finally {
      setSaving(false);
    }
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
                  <div className="flex justify-end">
                    <Button onClick={handleCreate} disabled={saving}>
                      {saving ? "Đang lưu..." : "Thêm tài sản"}
                    </Button>
                  </div>
                )}
              </div>
            </Card>
          </div>
          <div className="col-span-12 lg:col-span-4"></div>
        </div>

        <div className="mt-6 overflow-x-auto">
          <Card className="p-4 sm:px-5">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500">
                  <th className="py-2 pr-4">Loại</th>
                  <th className="py-2 pr-4">Mô tả</th>
                  <th className="py-2 pr-4">Giá trị (ước tính)</th>
                  <th className="py-2 pr-4">Trạng thái</th>
                  <th className="py-2">Tạo lúc</th>
                </tr>
              </thead>
              <tbody>
                {items.map((it) => (
                  <tr key={String(it.asset_id)} className="border-t border-gray-100">
                    <td className="py-2 pr-4">{it.asset_type}</td>
                    <td className="py-2 pr-4">{it.description || "-"}</td>
                    <td className="py-2 pr-4">{fmtNumber(it.value_estimate)}</td>
                    <td className="py-2 pr-4">{it.status || "-"}</td>
                    <td className="py-2">{fmtDateTime(it.created_at)}</td>
                  </tr>
                ))}
                {!items.length && !loading && (
                  <tr>
                    <td className="py-3 text-gray-400" colSpan={5}>
                      Chưa có tài sản.
                    </td>
                  </tr>
                )}
                {loading && (
                  <tr>
                    <td className="py-3 text-gray-500" colSpan={5}>
                      Đang tải...
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </Card>
        </div>
      </div>
    </Page>
  );
}
