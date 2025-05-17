import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import { Button, Card, Input, Textarea } from "components/ui";
import { useState, useEffect } from "react";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function TenantPage() {
  const createForm = useForm();
  const moduleForm = useForm();
  const removeForm = useForm();

  const [createSuccess, setCreateSuccess] = useState(null);
  const [createError, setCreateError] = useState(null);
  const [assignSuccess, setAssignSuccess] = useState(null);
  const [assignError, setAssignError] = useState(null);
  const [removeSuccess, setRemoveSuccess] = useState(null);
  const [removeError, setRemoveError] = useState(null);
  const [tenantList, setTenantList] = useState([]);
  const [availableModules, setAvailableModules] = useState([]);
  const [searchText, setSearchText] = useState("");

  const fetchAvailableModules = async () => {
    try {
      const res = await api.get("/available-modules");
      setAvailableModules(res.data);
    } catch {
      console.error("❌ Lỗi lấy module khả dụng");
    }
  };

  const onCreateSubmit = async (data) => {
    try {
      const res = await api.post("/tenant", data);
      setCreateSuccess(res.data);
      setCreateError(null);
      createForm.reset();
      fetchTenantList();
    } catch (err) {
      console.error("❌ Lỗi tạo tenant:", err);
      setCreateError(err.response?.data?.message || err.message);
      setCreateSuccess(null);
    }
  };

  const onAssignSubmit = async (data) => {
    try {
      const { tenant_id, module_name, config_json } = data;
      const payload = {
        module_name,
        config_json: config_json ? JSON.parse(config_json) : {},
      };
      const res = await api.post(`/tenant/${tenant_id}/modules`, payload);
      setAssignSuccess(res.data);
      setAssignError(null);
      moduleForm.reset();
      fetchTenantList();
    } catch (err) {
      console.error("❌ Lỗi gán module:", err);
      setAssignError(err.response?.data?.message || err.message);
      setAssignSuccess(null);
    }
  };

  const onRemoveSubmit = async (data) => {
    try {
      console.log("👀 Gửi xoá module với:", data);
      await api.delete(`/tenant/${data.tenant_id}/modules/${data.module_name}`);
      setRemoveSuccess({ module: data.module_name });
      setRemoveError(null);
      removeForm.reset();
      fetchTenantList();
    } catch (err) {
      console.error("❌ Lỗi xoá module:", err);
      setRemoveError(err.response?.data?.message || err.message);
      setRemoveSuccess(null);
    }
  };

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
    fetchAvailableModules();
  }, []);

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
              label="Tên tổ chức"
              placeholder="Công ty ABC"
              {...createForm.register("name", { required: "Bắt buộc" })}
              error={createForm.formState.errors?.name?.message}
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

        <Card className="rounded-lg p-6">
          <h3 className="text-lg font-semibold mb-4">🧩 Gán module cho tổ chức</h3>
          <form onSubmit={moduleForm.handleSubmit(onAssignSubmit)} className="space-y-5">
            <Input
              label="Tenant ID"
              placeholder="UUID tenant"
              {...moduleForm.register("tenant_id", { required: "Bắt buộc" })}
              error={moduleForm.formState.errors?.tenant_id?.message}
            />
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tên module</label>
              <select
                {...moduleForm.register("module_name", { required: "Bắt buộc" })}
                className="w-full p-2 border border-gray-300 rounded"
              >
                <option value="">-- Chọn module --</option>
                {availableModules.map((mod) => (
                  <option key={mod.module_name} value={mod.module_name}>
                    {mod.module_name} – {mod.display_name}
                  </option>
                ))}
              </select>
              {moduleForm.formState.errors?.module_name?.message && (
                <p className="text-red-500 text-sm mt-1">
                  {moduleForm.formState.errors.module_name.message}
                </p>
              )}
            </div>
            <Textarea
              label="Config JSON (tuỳ chọn)"
              placeholder='{"lang": "vi"}'
              {...moduleForm.register("config_json")}
            />
            <Button type="submit" className="w-full">Gán module</Button>
            {assignSuccess && <p className="text-green-600 text-sm text-center">✅ Gán thành công: {assignSuccess.module_name}</p>}
            {assignError && <p className="text-red-500 text-sm text-center">❌ {assignError}</p>}
          </form>
        </Card>

        <Card className="rounded-lg p-6">
          <h3 className="text-lg font-semibold mb-4">📤 Gỡ module khỏi tổ chức</h3>
          <form onSubmit={removeForm.handleSubmit(onRemoveSubmit)} className="space-y-5">
            <Input
              label="Tenant ID"
              placeholder="UUID tenant"
              {...removeForm.register("tenant_id", { required: "Bắt buộc" })}
              error={removeForm.formState.errors?.tenant_id?.message}
            />
            <Input
              label="Tên module"
              placeholder="user"
              {...removeForm.register("module_name", { required: "Bắt buộc" })}
              error={removeForm.formState.errors?.module_name?.message}
            />
            <Button type="submit" className="w-full">Gỡ module</Button>
            {removeSuccess && <p className="text-green-600 text-sm text-center">✅ Đã gỡ: {removeSuccess.module}</p>}
            {removeError && <p className="text-red-500 text-sm text-center">❌ {removeError}</p>}
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
                <th className="p-2 border">Tenant ID</th>
                <th className="p-2 border">Cluster</th>
                <th className="p-2 border">Module</th>
              </tr>
            </thead>
            <tbody>
              {filteredList.map((t) => (
                <tr key={t.tenant_id}>
                  <td className="p-2 border">{t.name}</td>
                  <td className="p-2 border">{t.tenant_id}</td>
                  <td className="p-2 border">{t.shard_id}</td>
                  <td className="p-2 border">{t.modules.join(", ")}</td>
                </tr>
              ))}
              {filteredList.length === 0 && (
                <tr>
                  <td colSpan="4" className="text-center text-gray-500 p-4">
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
