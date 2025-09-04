import { useEffect, useMemo, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Page } from "components/shared/Page";
import { Card, Button, Input } from "components/ui";
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

export default function CollateralPanel({ token, readOnly, contractId: propContractId }) {
  const [items, setItems] = useState([]);
  const [saving, setSaving] = useState(false);
  const [contractRef, setContractRef] = useState(propContractId || "");
  const [loading, setLoading] = useState(false);

  const form = useForm({
    defaultValues: {
      asset_type: "vehicle",
      description: "",
      value_estimate: "",
      status: "available",
    },
  });

  // fallback token từ localStorage nếu prop không được truyền
  const tokenValue = useMemo(() => token || localStorage.getItem("authToken") || "", [token]);
  const authHeader = useMemo(
    () => (tokenValue ? { Authorization: `Bearer ${tokenValue}` } : {}),
    [tokenValue]
  );

  const optionsMap = useMemo(() => ({}), []);

  // Load tất cả collateral (KHÔNG lọc theo contract_id)
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get("/loan/collateral", {
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

  const fmtNumber = (v) => {
    if (v == null || v === "") return "-";
    const n = typeof v === "number" ? v : parseFloat(v);
    return Number.isFinite(n) ? n.toLocaleString("vi-VN") : String(v);
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
                  <label className="text-sm text-gray-600 block mb-1">Số hợp đồng (Contract ID)</label>
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
                <DynamicForm form={form} fields={collateralFields} optionsMap={optionsMap} disabled={!!readOnly} />
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
                  <tr key={it.asset_id} className="border-t border-gray-100">
                    <td className="py-2 pr-4">{it.asset_type}</td>
                    <td className="py-2 pr-4">{it.description || "-"}</td>
                    <td className="py-2 pr-4">{fmtNumber(it.value_estimate)}</td>
                    <td className="py-2 pr-4">{it.status}</td>
                    <td className="py-2">{it.created_at ? new Date(it.created_at).toLocaleString() : "-"}</td>
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