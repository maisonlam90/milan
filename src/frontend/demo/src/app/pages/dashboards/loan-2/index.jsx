import { useEffect, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Card, Button } from "components/ui";
import DynamicForm from "components/shared/DynamicForm";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function LoanPage() {
  const [metadata, setMetadata] = useState(null);
  const [customers, setCustomers] = useState([]);
  const form = useForm();
  const token = localStorage.getItem("authToken");

  /** Fetch metadata */
  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get("/loan/metadata");
      setMetadata(res.data);
    } catch (err) {
      console.error("❌ Lỗi load metadata:", err);
    }
  }, []);

  /** Fetch customers */
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

  useEffect(() => {
    fetchMetadata();
    fetchCustomers();
  }, [fetchMetadata, fetchCustomers]);

  /** Submit tạo hợp đồng */
  const onCreateContract = async (data) => {
    try {
      await api.post(
        "/loan/create",
        {
          ...data,
          date_start: new Date(data.date_start).toISOString(),
          date_end: data.date_end
            ? new Date(data.date_end).toISOString()
            : null,
          principal: parseInt(data.principal, 10),
          collateral_value: data.collateral_value
            ? parseInt(data.collateral_value, 10)
            : 0,
          interest_rate: parseFloat(data.interest_rate),
          state: "draft",
        },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      form.reset();
      alert("✅ Đã tạo hợp đồng vay thành công");
    } catch (err) {
      alert(
        "❌ Lỗi tạo hợp đồng vay: " + (err.response?.data || err.message)
      );
    }
  };

  return (
    <Page title="💰 Tạo hợp đồng vay">
      <div className="transition-content px-(--margin-x) pb-6">
        {/* Header giống theme */}
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-1">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              Tạo hợp đồng vay mới
            </h2>
          </div>
          <div className="flex gap-2">
            <Button className="min-w-[7rem]" variant="outlined">
              Hủy
            </Button>
            <Button
              className="min-w-[7rem]"
              color="primary"
              type="submit"
              form="loan-form"
            >
              Lưu
            </Button>
          </div>
        </div>

        {!metadata ? (
          <p>Đang tải form...</p>
        ) : (
          <form
            autoComplete="off"
            onSubmit={form.handleSubmit(onCreateContract)}
            id="loan-form"
          >
            <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
              {/* Form chính bên trái */}
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
                          label:
                            c.email || c.username || c.full_name,
                        })),
                      }}
                    />
                  </div>
                </Card>
              </div>

              {/* Lịch sử bên phải */}
              <div className="col-span-12 lg:col-span-4 space-y-4 sm:space-y-5 lg:space-y-6">
                <Card className="p-4 sm:px-5">
                  <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                    Lịch sử chỉnh sửa
                  </h6>
                  <p className="mt-3 text-gray-500">
                    Chưa có dữ liệu lịch sử, sẽ hiển thị sau khi có các chỉnh sửa.
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
