import { useEffect, useState, useCallback, useMemo } from "react";
import { useNavigate, useLocation, useSearchParams } from "react-router-dom";
import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Card, Button } from "components/ui";
import DynamicForm from "components/shared/DynamicForm";
import Notebook from "components/shared/Notebook";


const api = axios.create({ baseURL: JWT_HOST_API });

// ✅ helper lấy message lỗi từ BE (AppError -> {code, message})
const extractErrMsg = (err) => {
  const data = err?.response?.data;
  if (data?.message) return data.message;
  if (typeof data === "string") return data;
  return err?.message || "Có lỗi xảy ra";
};

export default function LoanPage() {
  const navigate = useNavigate();
  const { state } = useLocation();
  const [search] = useSearchParams();
  const urlId = search.get("id");

  const [metadata, setMetadata] = useState(null);
  const [customers, setCustomers] = useState([]);
  const [collaterals, setCollaterals] = useState([]);
  const [loadingLoan, setLoadingLoan] = useState(!state?.preview);
  const [isEditing, setIsEditing] = useState(!urlId);
  const [localLoanId, setLocalLoanId] = useState(null);
  const [saving, setSaving] = useState(false);

  const form = useForm();

  // ✅ giữ ổn định header để tránh loop useEffect
  const token = localStorage.getItem("authToken") || "";
  const authHeader = useMemo(
    () => (token ? { Authorization: `Bearer ${token}` } : undefined),
    [token]
  );

  const loanId = urlId || localLoanId;

  const fetchCollaterals = useCallback(async () => {
    if (!loanId) return;
    try {
      const res = await api.get(`/loan/${loanId}/collaterals`, { headers: authHeader });
      setCollaterals(res.data || []);
    } catch (err) {
      console.error("❌ Lỗi load tài sản thế chấp:", err);
    }
  }, [loanId, token]);

  useEffect(() => {
    fetchCollaterals();
  }, [fetchCollaterals]);

  useEffect(() => {
    if (state?.preview) {
      form.reset(state.preview);
      setLoadingLoan(false);
      setIsEditing(false);
      if (state.preview?.id) {
        sessionStorage.setItem(`loan_preview_${state.preview.id}`, JSON.stringify(state.preview));
      }
    }
  }, [state?.preview, form]);

  // ✅ Tự động tính % năm từ lãi mỗi triệu mỗi ngày
  useEffect(() => {
    const subscription = form.watch((values, { name }) => {
      if (name === "interest_amount_per_million") {
        const perDay = values.interest_amount_per_million;
        if (typeof perDay === "number" && !isNaN(perDay)) {
          const annualRate = (perDay / 1_000_000) * 100 * 365;
          form.setValue("interest_rate", parseFloat(annualRate.toFixed(2)));
        }
      }
    });
    return () => subscription.unsubscribe();
  }, [form]);


  // ✅ Tạo danh sách fields đã chỉnh sửa:
  // - Luôn khóa không cho sửa `contract_number`
  // - Nếu có `loanId`, chèn thêm `contract_id` readonly vào ngay sau
  const adjustedFields = useMemo(() => {
  if (!metadata?.form?.fields) return [];

  // 👉 clone fields & luôn khoá trường contract_number
  const base = metadata.form.fields.map((f) =>
    f.name === "contract_number" ? { ...f, disabled: true } : f
  );

  // 👉 luôn chèn contract_id readonly ngay sau contract_number
  const idx = base.findIndex((f) => f.name === "contract_number");
    if (idx !== -1) {
      base.splice(idx + 1, 0, {
        name: "contract_id",
        label: "Mã hợp đồng",
        type: "text",
        width: 6,
        disabled: true,
      });
    }

    // 👉 chèn thêm trường nhập lãi theo tiền ngay sau interest_rate
    const irIdx = base.findIndex((f) => f.name === "interest_rate");
    if (irIdx !== -1) {
      base.splice(irIdx + 1, 0, {
        name: "interest_amount_per_million",
        label: "Lãi theo tiền (VNĐ mỗi triệu)",
        type: "number",
        width: 6,
      });
    }

    return base;
  }, [metadata]);
  

  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get("/loan/metadata");
      setMetadata(res.data);
    } catch (err) {
      console.error("❌ Lỗi load metadata:", err);
    }
  }, []);

  const fetchCustomers = useCallback(async () => {
    try {
      const res = await api.get("/contact/list", { headers: authHeader });
      setCustomers(res.data || []);
    } catch (err) {
      console.error("❌ Lỗi load contact:", err);
    }
  }, [token]); // phụ thuộc token (string) để ổn định

  const fetchLoan = useCallback(
    async (id = loanId) => {
      if (!id) {
        setIsEditing(true);
        form.reset({});
        setLoadingLoan(false);
        return;
      }

      setLoadingLoan(true);
      try {
        const res = await api.get(`/loan/${id}`, { headers: authHeader });
        form.reset(res.data);
        form.setValue("contract_id", res.data?.id || "");
        setIsEditing(false);
      } catch (err) {
        const cached = sessionStorage.getItem(`loan_preview_${id}`);
        if (cached) {
          form.reset(JSON.parse(cached));
        } else {
          alert("❌ Lỗi load hợp đồng: " + extractErrMsg(err));
        }
      } finally {
        setLoadingLoan(false);
      }
    },
    [loanId, token, form] // KHÔNG phụ thuộc object authHeader để tránh thay đổi ref liên tục
  );

  useEffect(() => {
    fetchMetadata();
    fetchCustomers();
    fetchLoan();
  }, [fetchMetadata, fetchCustomers, fetchLoan]);

  // ✅ Helper chuyển ngày về 00:00 UTC
  const onSubmit = async (data) => {
    const payload = {
      ...data,
      date_start: data.date_start,
      date_end: data.date_end,
      principal: data.principal !== undefined ? parseInt(data.principal, 10) : 0,
      collateral_value:
        data.collateral_value !== undefined ? parseInt(data.collateral_value, 10) : 0,
      interest_rate:
        data.interest_rate !== undefined && data.interest_rate !== ""
          ? parseFloat(data.interest_rate)
          : 0,
    };

    if (Array.isArray(data.transactions)) {
      payload.transactions = data.transactions.map((tx) => ({
        ...tx,
        date: tx.date ? Math.floor(new Date(tx.date).getTime() / 1000) : null,
      }));
    }

    try {
      setSaving(true);

      if (loanId) {
        await api.post(`/loan/${loanId}/update`, payload, { headers: authHeader });
        await fetchLoan(loanId);
        setIsEditing(false);
      } else {
        const res = await api.post("/loan/create", { ...payload, state: "draft" }, { headers: authHeader });
        const newId = res.data?.contract_id;
        if (newId) {
          setLocalLoanId(newId);
          await fetchLoan(newId);
          setIsEditing(false);
          const params = new URLSearchParams(location.search);
          params.set("id", newId);
          navigate({ search: `?${params.toString()}` }, { replace: true });
        } else {
          alert("❌ Không lấy được ID hợp đồng mới");
        }
      }
    } catch (err) {
      const dataRes = err?.response?.data;
      if (dataRes?.code) {
        setIsEditing(true);
        if (["interest_overpaid", "principal_overpaid"].includes(dataRes.code)) {
          document.querySelector("#loan-transactions")?.scrollIntoView({
            behavior: "smooth",
            block: "start",
          });
        }
      }
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
      alert("❌ Lỗi xóa hợp đồng: " + extractErrMsg(err));
    }
  };

  return (
    <Page title={loanId ? "✏️ Chi tiết hợp đồng vay" : "💰 Tạo hợp đồng vay mới"}>
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
                    fields={adjustedFields} // ✅ dùng danh sách field đã chỉnh sửa

                    optionsMap={{
                      contact_id: (customers || []).map((c) => ({
                        value: c.id,
                        label: c.display_name || c.name || c.email || c.phone,
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
                  fields={metadata?.notebook?.fields || []}
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
                        <div>Giá trị ước tính: {Number(c.value_estimate || 0).toLocaleString("vi-VN")} VNĐ</div>
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
                    Gốc còn lại: {form.watch("current_principal")?.toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div>
                    Lãi hiện tại: {form.watch("current_interest")?.toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div>
                    Lãi tích lũy: {form.watch("accumulated_interest")?.toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div>
                    Tổng lãi đã trả: {form.watch("total_paid_interest")?.toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div>
                    Tổng gốc đã trả: {form.watch("total_paid_principal")?.toLocaleString?.("vi-VN") || 0} VNĐ
                  </div>
                  <div className="font-semibold">
                    Số tiền còn phải trả: {form.watch("payoff_due")?.toLocaleString?.("vi-VN") || 0} VNĐ
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
