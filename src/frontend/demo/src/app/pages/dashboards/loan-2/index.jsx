import { useEffect, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Button, Input, Card } from "components/ui";

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

  /** Fetch customers (để chọn customer_id) */
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
          date_end: data.date_end ? new Date(data.date_end).toISOString() : null,
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
      <main
        className="
          min-h-screen w-full grid gap-6 p-10 bg-gray-50
          grid-cols-1 md:grid-cols-10
        "
      >
        {/* Cột form chiếm 70% trên desktop */}
        <Card className="md:col-span-7 p-8">
          <h2 className="text-2xl font-semibold mb-6">
            🆕 Tạo hợp đồng vay mới
          </h2>
          {!metadata ? (
            <p>Đang tải form...</p>
          ) : (
            <form
              onSubmit={form.handleSubmit(onCreateContract)}
              className="space-y-5"
            >
              {/* Select khách hàng */}
              <label className="block">
                Khách hàng
                <select
                  {...form.register("customer_id", {
                    required: "Vui lòng chọn khách hàng",
                  })}
                  className="border p-2 w-full rounded-md mt-1"
                >
                  <option value="">-- Chọn khách hàng --</option>
                  {customers.map((c) => (
                    <option key={c.id || c.user_id} value={c.id || c.user_id}>
                      {c.email || c.username || c.full_name}
                    </option>
                  ))}
                </select>
                {form.formState.errors?.customer_id && (
                  <p className="text-red-500 text-sm mt-1">
                    {form.formState.errors.customer_id.message}
                  </p>
                )}
              </label>

              {/* Các trường metadata */}
              {metadata.form.fields
                .filter((field) => field.name !== "customer_id")
                .map((field) => (
                  <Input
                    key={field.name}
                    label={field.label}
                    type={
                      field.type === "number"
                        ? "number"
                        : field.type === "date"
                        ? "date"
                        : "text"
                    }
                    placeholder={field.label}
                    {...form.register(field.name, {
                      required: `${field.label} là bắt buộc`,
                      valueAsNumber: field.type === "number",
                    })}
                    error={form.formState.errors?.[field.name]?.message}
                  />
                ))}

              <Button type="submit" size="lg" className="w-full">
                Lưu hợp đồng vay
              </Button>
            </form>
          )}
        </Card>

        {/* Cột lịch sử chiếm 30% trên desktop */}
        <Card className="md:col-span-3 p-8">
          <h2 className="text-xl font-semibold mb-4">📜 Lịch sử chỉnh sửa</h2>
          <p className="text-gray-500">
            Chưa có dữ liệu lịch sử, sẽ hiển thị sau khi có các chỉnh sửa.
          </p>
        </Card>
      </main>
    </Page>
  );
}
