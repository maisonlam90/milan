import { useEffect, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Card, Button } from "components/ui";
import DynamicForm from "components/shared/DynamicForm";

const api = axios.create({ baseURL: JWT_HOST_API });

function useQuery() {
  return new URLSearchParams(window.location.search);
}

export default function LoanPage() {
  const [metadata, setMetadata] = useState(null);
  const [customers, setCustomers] = useState([]);
  const [loadingLoan, setLoadingLoan] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [localLoanId, setLocalLoanId] = useState(null);
  const form = useForm();
  const token = localStorage.getItem("authToken");
  const query = useQuery();
  const loanId = query.get("id") || localLoanId;

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
      const res = await api.get("/user/users", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setCustomers(res.data);
    } catch (err) {
      console.error("❌ Lỗi load customers:", err);
    }
  }, [token]);

  const fetchLoan = useCallback(async (id = loanId) => {
    if (!id) {
      setIsEditing(true);
      return;
    }
    setLoadingLoan(true);
    try {
      const res = await api.get(`/loan/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      form.reset(res.data);
      setIsEditing(false);
    } catch (err) {
      alert("❌ Lỗi load hợp đồng: " + (err.response?.data || err.message));
    } finally {
      setLoadingLoan(false);
    }
  }, [loanId, token, form]);

  useEffect(() => {
    fetchMetadata();
    fetchCustomers();
    fetchLoan();
  }, [fetchMetadata, fetchCustomers, fetchLoan]);

  const onSubmit = async (data) => {
    const payload = {
      ...data,
      date_start: new Date(data.date_start).toISOString(),
      date_end: data.date_end ? new Date(data.date_end).toISOString() : null,
      principal: parseInt(data.principal, 10),
      collateral_value: data.collateral_value
        ? parseInt(data.collateral_value, 10)
        : 0,
      interest_rate: parseFloat(data.interest_rate),
    };

    try {
      if (loanId) {
        await api.post(`/loan/${loanId}/update`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
        setIsEditing(false);
      } else {
        const res = await api.post("/loan/create", { ...payload, state: "draft" }, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const newId = res.data?.contract_id;
        if (newId) {
          setLocalLoanId(newId);
          await fetchLoan(newId);
        } else {
          alert("❌ Không lấy được ID hợp đồng mới");
        }
      }
    } catch (err) {
      alert("❌ Lỗi lưu hợp đồng: " + (err.response?.data || err.message));
    }
  };

  const handleDelete = async () => {
    if (!loanId) return;
    const confirmDelete = window.confirm("Bạn có chắc muốn xóa hợp đồng này?");
    if (!confirmDelete) return;

    try {
      await api.delete(`/loan/${loanId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      window.location.href = "/dashboards/loan/loan-list"; // cập nhật nếu cần
    } catch (err) {
      alert("❌ Lỗi xóa hợp đồng: " + (err.response?.data || err.message));
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
                >
                  Hủy
                </Button>
                {loanId && (
                  <Button
                    className="min-w-[7rem] text-white"
                    style={{ backgroundColor: "#8B0000", hover: { backgroundColor: "#a30000" } }}
                    onClick={handleDelete}
                  >
                    Xóa
                  </Button>
                )}
                <Button
                  className="min-w-[7rem]"
                  color="primary"
                  type="submit"
                  form="loan-form"
                >
                  Lưu
                </Button>
              </>
            )}
          </div>
        </div>

        {!metadata || loadingLoan ? (
          <p>Đang tải form...</p>
        ) : (
          <form
            autoComplete="off"
            onSubmit={form.handleSubmit(onSubmit)}
            id="loan-form"
          >
            <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
              <div className="col-span-12 lg:col-span-8">
                <Card className="p-4 sm:px-5">
                  <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
                    Thông tin hợp đồng
                  </h3>
                  <div className="mt-5 space-y-5">
                    <DynamicForm
                      form={form}
                      fields={metadata.form.fields}
                      optionsMap={{
                        customer_id: customers.map((c) => ({
                          value: c.id || c.user_id,
                          label: c.email || c.username || c.full_name,
                        })),
                      }}
                      disabled={!isEditing}
                    />
                  </div>
                </Card>
              </div>

              <div className="col-span-12 lg:col-span-4 space-y-4 sm:space-y-5 lg:space-y-6">
                <Card className="p-4 sm:px-5">
                  <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                    Lịch sử chỉnh sửa
                  </h6>
                  <p className="mt-3 text-gray-500">
                    {loanId
                      ? "Hiển thị sau khi có các chỉnh sửa"
                      : "Chưa có dữ liệu lịch sử"}
                  </p>
                </Card>
              </div>
            </div>
          </form>
        )}
      </div>
    </Page>
  );
}
