// src/app/pages/dashboards/loan/loan-detail/index.tsx
import { useEffect, useState, useCallback, useMemo } from "react";
import { useNavigate, useLocation, useSearchParams } from "react-router-dom";
import { useForm, type UseFormReturn } from "react-hook-form";
import { Page } from "@/components/shared/Page";
import axios, { type AxiosError } from "axios";
import { JWT_HOST_API } from "@/configs/auth";
import { Card, Button } from "@/components/ui";
import DynamicForm from "@/components/shared/DynamicForm";
import Notebook from "@/components/shared/Notebook";

// 🔌 type đích cho DynamicForm
import type { DynamicFieldConfig } from "@/components/shared/DynamicForm";
// (Nếu Notebook.tsx của bạn có export NotebookColumn thì có thể dùng dòng sau.
//  Không có cũng không sao vì phía dưới mình cast an toàn khi truyền prop.)
// import type { NotebookColumn } from "@/components/shared/Notebook";

/* ====================== Types ====================== */

type ID = string;

interface LoanTransaction {
  date?: string | number | null; // ISO string hoặc unix seconds trước khi gửi
  amount?: number | string;
  type?: string;
  note?: string;
  [k: string]: unknown;
}

export interface LoanFormValues {
  id?: ID;
  contract_id?: ID;
  contract_number?: string;
  contact_id?: ID;
  date_start?: string | null; // ISO
  date_end?: string | null;   // ISO
  principal?: number | string;
  collateral_value?: number | string;
  interest_rate?: number | string;
  interest_amount_per_million?: number | string;

  // các số liệu hiển thị bên phải
  current_principal?: number;
  current_interest?: number;
  accumulated_interest?: number;
  total_paid_interest?: number;
  total_paid_principal?: number;
  payoff_due?: number;

  // sổ giao dịch
  transactions?: LoanTransaction[];

  // các field khác từ BE (nếu có)
  [k: string]: unknown;
}

interface ContactLite {
  id: ID;
  display_name?: string | null;
  name?: string | null;
  email?: string | null;
  phone?: string | null;
  [k: string]: unknown;
}

interface CollateralItem {
  asset_id: ID;
  asset_type?: string;
  description?: string;
  value_estimate?: number;
  status?: string;
  [k: string]: unknown;
}

interface FormFieldDef {
  name: string;
  label?: string;
  type?: string;
  width?: number;
  disabled?: boolean;
  options?: Array<{ label?: string; value: string | number }>;
  [k: string]: unknown;
}

interface MetadataDto {
  form?: { fields?: FormFieldDef[] };
  notebook?: { fields?: FormFieldDef[] };
  [k: string]: unknown;
}

/* ====================== Chuẩn hoá metadata -> đúng type ====================== */

// FormFieldDef -> DynamicFieldConfig (label luôn là string)
const normalizeDynamicFields = (fields?: FormFieldDef[]): DynamicFieldConfig[] => {
  if (!fields) return [];
  return fields.map((f) => {
    const hasOptions = Array.isArray(f.options);
    return {
      ...f,
      label: f.label ?? "",
      type: f.type ?? "text",
      ...(hasOptions
        ? {
            options: f.options!.map((o) => ({
              label: o?.label ?? String(o?.value ?? ""),
              value: o?.value,
            })),
          }
        : {}),
    } as DynamicFieldConfig;
  });
};

// FormFieldDef -> NotebookColumn tương thích (label luôn là string)
// Nếu Notebook export type NotebookColumn, thay any bằng NotebookColumn.
const normalizeNotebookColumns = (fields?: FormFieldDef[])/*: NotebookColumn[]*/ => {
  if (!fields) return [] as any;
  return fields.map((f) => {
    const hasOptions = Array.isArray(f.options);
    return {
      name: f.name,
      label: f.label ?? "",
      type: (f.type as any) ?? "text",
      ...(hasOptions
        ? {
            options: f.options!.map((o) => ({
              label: o?.label ?? String(o?.value ?? ""),
              value: o?.value,
            })),
          }
        : {}),
    };
  }) as any;
};

/* ====================== API ====================== */

const api = axios.create({ baseURL: JWT_HOST_API });

/** Lấy message lỗi từ BE (AppError -> {code, message}) */
const extractErrMsg = (err: unknown): string => {
  const e = err as AxiosError<any>;
  const data = e?.response?.data as any;
  if (data?.message) return data.message as string;
  if (typeof data === "string") return data;
  return (e?.message as string) || "Có lỗi xảy ra";
};

/* ====================== Component ====================== */

export default function LoanPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { state } = location as { state?: { preview?: Partial<LoanFormValues> } };
  const [search] = useSearchParams();
  const urlId = search.get("id");

  const [metadata, setMetadata] = useState<MetadataDto | null>(null);
  const [customers, setCustomers] = useState<ContactLite[]>([]);
  const [collaterals, setCollaterals] = useState<CollateralItem[]>([]);
  const [loadingLoan, setLoadingLoan] = useState<boolean>(!state?.preview);
  const [isEditing, setIsEditing] = useState<boolean>(!urlId);
  const [localLoanId, setLocalLoanId] = useState<ID | null>(null);
  const [saving, setSaving] = useState<boolean>(false);

  const form: UseFormReturn<LoanFormValues> = useForm<LoanFormValues>();

  // ✅ giữ ổn định header để tránh loop useEffect
  const token = (typeof window !== "undefined" && localStorage.getItem("authToken")) || "";
  const authHeader = useMemo<undefined | Record<string, string>>(
    () => (token ? { Authorization: `Bearer ${token}` } : undefined),
    [token]
  );

  const loanId = (urlId || localLoanId) as string | null;

  const fetchCollaterals = useCallback(async () => {
    if (!loanId) return;
    try {
      const res = await api.get<CollateralItem[]>(`/loan/${loanId}/collaterals`, {
        headers: authHeader,
      });
      setCollaterals(res.data || []);
    } catch (err) {
      console.error("❌ Lỗi load tài sản thế chấp:", err);
    }
  }, [loanId, authHeader]);

  useEffect(() => {
    fetchCollaterals();
  }, [fetchCollaterals]);

  useEffect(() => {
    if (state?.preview) {
      form.reset(state.preview as LoanFormValues);
      setLoadingLoan(false);
      setIsEditing(false);
      if (state.preview?.id) {
        sessionStorage.setItem(
          `loan_preview_${state.preview.id}`,
          JSON.stringify(state.preview)
        );
      }
    }
  }, [state?.preview, form]);

  // ✅ Tự động tính % năm từ lãi mỗi triệu mỗi ngày
  useEffect(() => {
    const subscription = form.watch((values, { name }) => {
      if (name === "interest_amount_per_million") {
        const perDayRaw = values.interest_amount_per_million;
        const perDay =
          typeof perDayRaw === "string" ? parseFloat(perDayRaw) : (perDayRaw as number);
        if (typeof perDay === "number" && !Number.isNaN(perDay)) {
          const annualRate = (perDay / 1_000_000) * 100 * 365;
          form.setValue("interest_rate", parseFloat(annualRate.toFixed(2)));
        }
      }
    });
    return () => subscription.unsubscribe();
  }, [form]);

  // ✅ Tạo danh sách fields đã chỉnh sửa: (chuẩn hoá -> chèn field)
  const adjustedFields = useMemo<DynamicFieldConfig[]>(() => {
    if (!metadata?.form?.fields) return [];

    // chuẩn hoá trước để label luôn là string
    const base = normalizeDynamicFields(metadata.form.fields)
      .map((f) => (f.name === "contract_number" ? { ...f, disabled: true } : f));

    // luôn chèn contract_id readonly ngay sau contract_number
    const idx = base.findIndex((f) => f.name === "contract_number");
    if (idx !== -1) {
      base.splice(idx + 1, 0, {
        name: "contract_id",
        label: "Mã hợp đồng",
        type: "text",
        width: 6,
        disabled: true,
      } as DynamicFieldConfig);
    }

    // chèn thêm trường nhập lãi theo tiền ngay sau interest_rate
    const irIdx = base.findIndex((f) => f.name === "interest_rate");
    if (irIdx !== -1) {
      base.splice(irIdx + 1, 0, {
        name: "interest_amount_per_million",
        label: "Lãi theo tiền (VNĐ mỗi triệu)",
        type: "number",
        width: 6,
      } as DynamicFieldConfig);
    }

    return base;
  }, [metadata]);

  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get<MetadataDto>("/loan/metadata");
      setMetadata(res.data);
    } catch (err) {
      console.error("❌ Lỗi load metadata:", err);
    }
  }, []);

  const fetchCustomers = useCallback(async () => {
    try {
      const res = await api.get<ContactLite[]>("/contact/list", { headers: authHeader });
      setCustomers(res.data || []);
    } catch (err) {
      console.error("❌ Lỗi load contact:", err);
    }
  }, [authHeader]);

  const fetchLoan = useCallback(
    async (id: string | null = loanId) => {
      if (!id) {
        setIsEditing(true);
        form.reset({});
        setLoadingLoan(false);
        return;
      }

      setLoadingLoan(true);
      try {
        const res = await api.get<LoanFormValues>(`/loan/${id}`, { headers: authHeader });
        form.reset(res.data);
        form.setValue("contract_id", (res.data?.id as string) || "");
        setIsEditing(false);
      } catch (err) {
        const cached = sessionStorage.getItem(`loan_preview_${id}`);
        if (cached) {
          form.reset(JSON.parse(cached) as LoanFormValues);
        } else {
          // eslint-disable-next-line no-alert
          alert("❌ Lỗi load hợp đồng: " + extractErrMsg(err));
        }
      } finally {
        setLoadingLoan(false);
      }
    },
    [loanId, authHeader, form]
  );

  useEffect(() => {
    fetchMetadata();
    fetchCustomers();
    fetchLoan();
  }, [fetchMetadata, fetchCustomers, fetchLoan]);

  // ✅ Submit
  const onSubmit = async (data: LoanFormValues) => {
    const toInt = (v: unknown): number =>
      v === undefined || v === null || v === "" ? 0 : parseInt(String(v), 10);
    const toFloat = (v: unknown): number =>
      v === undefined || v === null || v === "" ? 0 : parseFloat(String(v));

    const payload: any = {
      ...data,
      date_start: data.date_start,
      date_end: data.date_end,
      principal: toInt(data.principal),
      collateral_value: toInt(data.collateral_value),
      interest_rate: toFloat(data.interest_rate),
    };

    if (Array.isArray(data.transactions)) {
      payload.transactions = data.transactions.map((tx) => ({
        ...tx,
        date: tx?.date
          ? Math.floor(new Date(String(tx.date)).getTime() / 1000)
          : null,
      }));
    }

    try {
      setSaving(true);

      if (loanId) {
        await api.post(`/loan/${loanId}/update`, payload, { headers: authHeader });
        await fetchLoan(loanId);
        setIsEditing(false);
      } else {
        const res = await api.post<{ contract_id?: string }>(
          "/loan/create",
          { ...payload, state: "draft" },
          { headers: authHeader }
        );
        const newId = res.data?.contract_id;
        if (newId) {
          setLocalLoanId(newId);
          await fetchLoan(newId);
          setIsEditing(false);
          const params = new URLSearchParams(location.search);
          params.set("id", newId);
          navigate({ search: `?${params.toString()}` }, { replace: true });
        } else {
          // eslint-disable-next-line no-alert
          alert("❌ Không lấy được ID hợp đồng mới");
        }
      }
    } catch (err) {
      const dataRes = (err as AxiosError<any>)?.response?.data as any;
      if (dataRes?.code) {
        setIsEditing(true);
        if (["interest_overpaid", "principal_overpaid"].includes(dataRes.code)) {
          document.querySelector("#loan-transactions")?.scrollIntoView({
            behavior: "smooth",
            block: "start",
          });
        }
      }
      // eslint-disable-next-line no-alert
      alert("❌ " + extractErrMsg(err));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!loanId) return;
    if (!window.confirm("Bạn có chắc muốn xóa hợp đồng này?")) return;
    try {
      await api.delete(`/loan/${loanId}`, { headers: authHeader });
      navigate("/dashboards/loan/loan-1");
    } catch (err) {
      // eslint-disable-next-line no-alert
      alert("❌ Lỗi xóa hợp đồng: " + extractErrMsg(err));
    }
  };

  return (
    <Page title={loanId ? "Chi tiết hợp đồng vay" : "💰 Tạo hợp đồng vay mới"}>
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-1">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              {loanId ? "Chi tiết hợp đồng vay" : "Tạo hợp đồng vay mới"}
            </h2>
            {loadingLoan && (
              <span className="ml-3 text-xs text-gray-400">Đang tải dữ liệu hợp đồng…</span>
            )}
          </div>
          <div className="flex gap-2">
            {loanId && !isEditing && (
              <Button className="min-w-[7rem]" onClick={() => setIsEditing(true)}>
                Chỉnh sửa
              </Button>
            )}
            {isEditing && (
              <>
                <Button
                  className="min-w-[7rem]"
                  variant="outlined"
                  onClick={() => fetchLoan()}
                  disabled={saving}
                >
                  Hủy
                </Button>
                {loanId && (
                  <Button
                    className="min-w-[7rem] text-white"
                    style={{ backgroundColor: "#8B0000" }}
                    onClick={handleDelete}
                    disabled={saving}
                  >
                    Xóa
                  </Button>
                )}
                <Button
                  className="min-w-[7rem]"
                  color="primary"
                  type="submit"
                  form="loan-form"
                  disabled={saving}
                >
                  {saving ? "Đang lưu..." : "Lưu"}
                </Button>
              </>
            )}
          </div>
        </div>

        <form autoComplete="off" onSubmit={form.handleSubmit(onSubmit)} id="loan-form">
          <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
            <div className="col-span-12 lg:col-span-8">
              <Card className="p-4 sm:px-5">
                <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Thông tin hợp đồng
                </h3>
                <div className="mt-5 space-y-5">
                  <DynamicForm
                    form={form}
                    fields={adjustedFields} // ✅ đã normalize về DynamicFieldConfig[]
                    optionsMap={{
                      contact_id: (customers || []).map((c) => ({
                        value: c.id,
                        label: c.display_name || c.name || c.email || c.phone || String(c.id),
                      })),
                    }}
                    disabled={!isEditing}
                  />
                </div>
              </Card>

              {/* ✅ gắn id để scroll khi có lỗi giao dịch */}
              <Card id="loan-transactions" className="p-4 sm:px-5 mb-6 mt-6">
                <Notebook
                  name="transactions"
                  editable={isEditing}
                  form={form}
                  // ✅ normalize để label luôn string; cast any nếu Notebook không export type
                  fields={normalizeNotebookColumns(metadata?.notebook?.fields) as any}
                />
              </Card>

              <Card className="p-4 sm:px-5 mb-6 mt-6">
                <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Tài sản thế chấp
                </h3>
                {collaterals.length === 0 ? (
                  <p className="text-sm text-gray-500 mt-2">Không có tài sản nào được gắn.</p>
                ) : (
                  <ul className="mt-3 space-y-2 text-sm text-gray-700">
                    {collaterals.map((c) => (
                      <li key={c.asset_id} className="border p-2 rounded">
                        <div className="font-semibold">{c.asset_type}</div>
                        <div>Mô tả: {c.description}</div>
                        <div>
                          Giá trị ước tính:{" "}
                          {Number(c.value_estimate || 0).toLocaleString("vi-VN")} VNĐ
                        </div>
                        <div>Trạng thái: {c.status}</div>
                      </li>
                    ))}
                  </ul>
                )}
              </Card>
            </div>

            <div className="col-span-12 lg:col-span-4 space-y-4 sm:space-y-5 lg:space-y-6">
              <Card className="p-4 sm:px-5">
                <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Thông tin tính toán lãi
                </h6>
                <div className="mt-4 space-y-2 text-sm text-gray-600 dark:text-dark-50">
                  <div>
                    Gốc còn lại:{" "}
                    {(form.watch("current_principal") ?? 0).toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div>
                    Lãi hiện tại:{" "}
                    {(form.watch("current_interest") ?? 0).toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div>
                    Lãi tích lũy:{" "}
                    {(form.watch("accumulated_interest") ?? 0).toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div>
                    Tổng lãi đã trả:{" "}
                    {(form.watch("total_paid_interest") ?? 0).toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div>
                    Tổng gốc đã trả:{" "}
                    {(form.watch("total_paid_principal") ?? 0).toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div className="font-semibold">
                    Số tiền còn phải trả:{" "}
                    {(form.watch("payoff_due") ?? 0).toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                </div>
              </Card>
            </div>
          </div>
        </form>
      </div>
    </Page>
  );
}
