import { useEffect, useState, useCallback, useMemo } from "react";
import { useNavigate, useLocation, useSearchParams } from "react-router-dom";
import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Card, Button } from "components/ui";
import DynamicForm from "components/shared/DynamicForm";
import Notebook from "components/shared/Notebook";
import CollateralPanel from "./CollateralPanel";

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

  const onSubmit = async (data) => {
    const payload = {
      ...data,
      date_start: data.date_start ? new Date(data.date_start).toISOString() : null,
      date_end: data.date_end ? new Date(data.date_end).toISOString() : null,
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
      // ✅ Hiển thị lỗi từ BE (Validation: 400 -> {code, message})
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
                    fields={metadata?.form?.fields || []}
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
              <CollateralPanel token={token} customers={customers} readOnly={!isEditing} />
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
