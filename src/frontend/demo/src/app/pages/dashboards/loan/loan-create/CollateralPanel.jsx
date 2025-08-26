import { useEffect, useMemo, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Card, Button } from "components/ui";
import DynamicForm from "components/shared/DynamicForm";

const api = axios.create({ baseURL: JWT_HOST_API });

const collateralFields = [
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
  { name: "owner_contact_id", label: "Chủ sở hữu (contact)", type: "select", width: 6 },
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

export default function CollateralPanel({ token, customers, readOnly }) {
  const [items, setItems] = useState([]);
  const [saving, setSaving] = useState(false);

  const form = useForm({
    defaultValues: {
      asset_type: "vehicle",
      description: "",
      value_estimate: "",
      owner_contact_id: "",
      status: "available",
    },
  });

  const authHeader = useMemo(
    () => (token ? { Authorization: `Bearer ${token}` } : undefined),
    [token]
  );

  const optionsMap = useMemo(
    () => ({
      owner_contact_id: (customers || []).map((c) => ({
        value: c.id,
        label: c.display_name || c.name || c.email || c.phone,
      })),
    }),
    [customers]
  );

  const load = useCallback(async () => {
    try {
      const res = await api.get("/loan/collateral", { headers: authHeader });
      setItems(res.data || []);
    } catch (e) {
      console.error("Load collateral failed:", e);
    }
  }, [authHeader]);

  useEffect(() => {
    load();
  }, [load]);

  const handleCreate = async () => {
    try {
      setSaving(true);
      const data = form.getValues();
      const payload = {
        ...data,
        // DynamicForm trả "number" cho field type:number; vẫn bảo vệ nếu rỗng
        value_estimate:
          data.value_estimate === "" || data.value_estimate == null
            ? undefined
            : Number(data.value_estimate),
        owner_contact_id: data.owner_contact_id || undefined,
      };
      await api.post("/loan/collateral", payload, { headers: authHeader });
      form.reset({
        asset_type: "vehicle",
        description: "",
        value_estimate: "",
        owner_contact_id: "",
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

  const fmtNumber = (v) => {
    if (v == null || v === "") return "-";
    const n = typeof v === "number" ? v : parseFloat(v);
    return Number.isFinite(n) ? n.toLocaleString("vi-VN") : String(v);
  };

  return (
    <Card className="p-4 sm:px-5">
      <div className="flex items-center justify-between">
        <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
          Tài sản thế chấp
        </h3>
      </div>

      <div className="mt-4 space-y-4">
        <DynamicForm
          form={form}
          fields={collateralFields}
          optionsMap={optionsMap}
          disabled={!!readOnly}
        />

        {!readOnly && (
          <Button onClick={handleCreate} disabled={saving}>
            {saving ? "Đang lưu..." : "Thêm tài sản"}
          </Button>
        )}
      </div>

      <div className="mt-6 overflow-x-auto">
        <table className="min-w-full text-sm">
          <thead>
            <tr className="text-left text-gray-500">
              <th className="py-2 pr-4">Loại</th>
              <th className="py-2 pr-4">Mô tả</th>
              <th className="py-2 pr-4">Giá trị (ước tính)</th>
              <th className="py-2 pr-4">Chủ sở hữu</th>
              <th className="py-2 pr-4">Trạng thái</th>
              <th className="py-2">Tạo lúc</th>
            </tr>
          </thead>
          <tbody>
            {items.map((it) => (
              <tr key={it.asset_id} className="border-t border-gray-100">
                <td className="py-2 pr-4">{it.asset_type}</td>
                <td className="py-2 pr-4">{it.description || "-"}</td>
                <td className="py-2 pr-4">{fmtNumber(it.value_estimate)}</td>
                <td className="py-2 pr-4">{it.owner_contact_id || "-"}</td>
                <td className="py-2 pr-4">{it.status}</td>
                <td className="py-2">
                  {it.created_at ? new Date(it.created_at).toLocaleString() : "-"}
                </td>
              </tr>
            ))}
            {!items.length && (
              <tr>
                <td className="py-3 text-gray-400" colSpan={6}>
                  Chưa có tài sản.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </Card>
  );
}
