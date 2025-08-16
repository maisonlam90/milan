import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import { Button, Card, Input } from "components/ui";
import { useState, useEffect } from "react";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function TenantPage() {
  const createForm = useForm();

  const [createSuccess, setCreateSuccess] = useState(null);
  const [createError, setCreateError] = useState(null);
  const [tenantList, setTenantList] = useState([]);
  const [searchText, setSearchText] = useState("");

  const fetchTenantList = async () => {
    try {
      const res = await api.get("/tenants-with-modules");
      setTenantList(res.data);
    } catch {
      console.error("❌ Lỗi lấy danh sách tenants");
    }
  };

  useEffect(() => {
    fetchTenantList();
  }, []);

  const onCreateSubmit = async (data) => {
  try {
    const res = await api.post("/tenant", data);
    setCreateSuccess(res.data);
    setCreateError(null);
    createForm.reset();
    fetchTenantList();
  } catch (err) {
    console.error("❌ Lỗi tạo tenant:", err);
    console.log("📦 Phản hồi lỗi:", err.response?.data); // 👈 thêm dòng này
    setCreateError(err.response?.data?.message || err.message);
    setCreateSuccess(null);
  }
};

  const filteredList = tenantList.filter((t) =>
    t.name.toLowerCase().includes(searchText.toLowerCase()) ||
    t.tenant_id.toLowerCase().includes(searchText.toLowerCase()) ||
    t.modules.join(", ").toLowerCase().includes(searchText.toLowerCase())
  );

  return (
    <Page title="Quản lý Tenant">
      <main className="min-h-100vh grid grid-cols-1 lg:grid-cols-2 gap-8 p-6">
        <Card className="rounded-lg p-6">
          <h3 className="text-lg font-semibold mb-4">📝 Tạo tổ chức mới</h3>
          <form onSubmit={createForm.handleSubmit(onCreateSubmit)} className="space-y-5">
            <Input
              label="Enterprise ID"
              placeholder="UUID enterprise"
              {...createForm.register("enterprise_id", { required: "Bắt buộc" })}
              error={createForm.formState.errors?.enterprise_id?.message}
            />
            <Input
              label="Company ID (tuỳ chọn)"
              placeholder="UUID company hoặc để trống"
              {...createForm.register("company_id")}
              error={createForm.formState.errors?.company_id?.message}
            />
            <Input
              label="Tên tổ chức"
              placeholder="Công ty ABC"
              {...createForm.register("name", { required: "Bắt buộc" })}
              error={createForm.formState.errors?.name?.message}
            />
            <Input
              label="Slug"
              placeholder="tencongty.mailan.net"
              {...createForm.register("slug", { required: "Bắt buộc" })}
              error={createForm.formState.errors?.slug?.message}
            />
            <Input
              label="Shard / Cluster"
              placeholder="cluster1"
              {...createForm.register("shard_id", { required: "Bắt buộc" })}
              error={createForm.formState.errors?.shard_id?.message}
            />
            <Button type="submit" className="w-full">Tạo tổ chức</Button>
            {createSuccess && <p className="text-green-600 text-sm text-center">✅ Đã tạo: {createSuccess.tenant_id}</p>}
            {createError && <p className="text-red-500 text-sm text-center">❌ {createError}</p>}
          </form>
        </Card>

        <Card className="col-span-2 p-6">
          <h3 className="text-lg font-semibold mb-4">📊 Danh sách tất cả tổ chức và module</h3>
          <div className="mb-4">
            <input
              type="text"
              placeholder="🔍 Tìm kiếm theo tên, ID, module..."
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              className="w-full p-2 border border-gray-300 rounded"
            />
          </div>
          <table className="w-full text-sm border border-gray-300">
            <thead className="bg-gray-100">
              <tr>
                <th className="p-2 border">Tên tổ chức</th>
                <th className="p-2 border">Slug</th>
                <th className="p-2 border">Tenant ID</th>
                <th className="p-2 border">Enterprise</th>
                <th className="p-2 border">Company</th>
                <th className="p-2 border">Cluster</th>
                <th className="p-2 border">Module</th>
              </tr>
            </thead>
            <tbody>
              {filteredList.map((t) => (
                <tr key={t.tenant_id}>
                  <td className="p-2 border">{t.name}</td>
                  <td className="p-2 border">{t.slug}</td>
                  <td className="p-2 border">{t.tenant_id}</td>
                  <td className="p-2 border">{t.enterprise_id}</td>
                  <td className="p-2 border">{t.company_id || "-"}</td>
                  <td className="p-2 border">{t.shard_id}</td>
                  <td className="p-2 border">{t.modules.join(", ")}</td>
                </tr>
              ))}
              {filteredList.length === 0 && (
                <tr>
                  <td colSpan="7" className="text-center text-gray-500 p-4">
                    Không tìm thấy kết quả phù hợp.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </Card>
      </main>
    </Page>
  );
}
