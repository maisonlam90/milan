import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import { Button, Card, Input, Textarea } from "components/ui";
import { useState, useEffect } from "react";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function TenantPage() {
  // Forms
  const enterpriseForm = useForm();
  const companyForm = useForm();
  const enableEntForm = useForm(); // bật module cho enterprise
  const createForm = useForm();
  const moduleForm = useForm(); // gán module cho tenant
  const removeForm = useForm();
  const userForm = useForm();

  // States
  const [enterpriseSuccess, setEnterpriseSuccess] = useState(null);
  const [enterpriseError, setEnterpriseError] = useState(null);
  const [companySuccess, setCompanySuccess] = useState(null);
  const [companyError, setCompanyError] = useState(null);
  const [enableEntSuccess, setEnableEntSuccess] = useState(null);
  const [enableEntError, setEnableEntError] = useState(null);
  const [createSuccess, setCreateSuccess] = useState(null);
  const [createError, setCreateError] = useState(null);
  const [assignSuccess, setAssignSuccess] = useState(null);
  const [assignError, setAssignError] = useState(null);
  const [removeSuccess, setRemoveSuccess] = useState(null);
  const [removeError, setRemoveError] = useState(null);
  const [userSuccess, setUserSuccess] = useState(null);
  const [userError, setUserError] = useState(null);
  const [tenantList, setTenantList] = useState([]);
  const [availableModules, setAvailableModules] = useState([]); // <- sẽ là [{key,label,description}]
  const [modsLoading, setModsLoading] = useState(false);
  const [searchText, setSearchText] = useState("");

  // Chuẩn hoá data: hỗ trợ cả 2 shape {key,label} hoặc {module_name,display_name}
  const normalizeMods = (rows = []) =>
    (rows || []).map((r) => ({
      key: r.key ?? r.module_name,
      label: r.label ?? r.display_name ?? r.module_name,
      description: r.description ?? "",
    })).filter(m => !!m.key);

  // ===== API Fetchers =====
  const fetchTenantList = async () => {
    try {
      const res = await api.get("/tenants-with-modules");
      setTenantList(res.data || []);
    } catch {
      console.error("❌ Lỗi lấy danh sách tenants");
    }
  };

  const fetchAvailableModules = async () => {
    try {
      setModsLoading(true);
      // LẤY ĐÚNG TỪ /acl/available-modules
      const res = await api.get("/acl/available-modules");
      setAvailableModules(normalizeMods(res.data));
    } catch {
      console.error("❌ Lỗi lấy available modules");
      setAvailableModules([]);
    } finally {
      setModsLoading(false);
    }
  };

  useEffect(() => {
    // IIFE để không bị eslint warning deps
    (async () => {
      await fetchTenantList();
      await fetchAvailableModules();
    })();
  }, []);

  // ===== Handlers =====
  const onEnterpriseSubmit = async (data) => {
    try {
      const res = await api.post("/enterprise", data);
      setEnterpriseSuccess(res.data);
      setEnterpriseError(null);
      enterpriseForm.reset();
    } catch (error) {
      setEnterpriseError(error.response?.data?.message || error.message);
      setEnterpriseSuccess(null);
    }
  };

  const onEnableEntSubmit = async (data) => {
    try {
      const { enterprise_id, module_name, config_json } = data;
      let cfg = {};
      if (config_json?.trim()) {
        try { cfg = JSON.parse(config_json); }
        catch { setEnableEntError("Config JSON không hợp lệ"); setEnableEntSuccess(null); return; }
      }
      const res = await api.post(`/enterprise/${enterprise_id}/modules`, { module_name, config_json: cfg });
      setEnableEntSuccess(res.data);
      setEnableEntError(null);
      enableEntForm.reset();
    } catch (error) {
      setEnableEntError(error.response?.data?.error || error.response?.data?.message || error.message);
      setEnableEntSuccess(null);
    }
  };

  const onCompanySubmit = async (data) => {
    try {
      const payload = {
        enterprise_id: data.enterprise_id,
        name: data.name,
        slug: data.slug || null,
        parent_company_id: data.parent_company_id || null,
      };
      const res = await api.post("/company", payload);
      setCompanySuccess(res.data);
      setCompanyError(null);
      companyForm.reset();
    } catch (error) {
      setCompanyError(error.response?.data?.message || error.message);
      setCompanySuccess(null);
    }
  };

  const onCreateSubmit = async (data) => {
    try {
      const res = await api.post("/tenant", data);
      setCreateSuccess(res.data);
      setCreateError(null);
      createForm.reset();
      fetchTenantList();
    } catch (error) {
      setCreateError(error.response?.data?.message || error.message);
      setCreateSuccess(null);
    }
  };

  const onAssignSubmit = async (data) => {
    try {
      const { tenant_id, module_name, config_json } = data;
      let cfg = {};
      if (config_json?.trim()) {
        try { cfg = JSON.parse(config_json); }
        catch { setAssignError("Config JSON không hợp lệ"); setAssignSuccess(null); return; }
      }
      const res = await api.post(`/tenant/${tenant_id}/modules`, { module_name, config_json: cfg });
      setAssignSuccess(res.data);
      setAssignError(null);
      moduleForm.reset();
      fetchTenantList();
    } catch (error) {
      setAssignError(error.response?.data?.error || error.response?.data?.message || error.message);
      setAssignSuccess(null);
    }
  };

  const onRemoveSubmit = async (data) => {
    try {
      await api.delete(`/tenant/${data.tenant_id}/modules/${data.module_name}`);
      setRemoveSuccess({ module: data.module_name });
      setRemoveError(null);
      removeForm.reset();
      fetchTenantList();
    } catch (error) {
      setRemoveError(error.response?.data?.message || error.message);
      setRemoveSuccess(null);
    }
  };

  const onUserSubmit = async (data) => {
    try {
      const res = await api.post("/user/register", data);
      setUserSuccess(res.data);
      setUserError(null);
      userForm.reset();
    } catch (error) {
      setUserError(error.response?.data?.message || error.message);
      setUserSuccess(null);
    }
  };

  const filteredList = tenantList.filter((t) =>
    (t.name || "").toLowerCase().includes(searchText.toLowerCase()) ||
    (t.tenant_id || "").toLowerCase().includes(searchText.toLowerCase()) ||
    (t.modules || []).join(", ").toLowerCase().includes(searchText.toLowerCase())
  );

  return (
    <Page title="Quản lý Tenant">
      <main className="min-h-100vh grid grid-cols-1 lg:grid-cols-2 gap-8 p-6">
        {/* ====== Create Enterprise ====== */}
        <Card className="rounded-lg p-6">
          <h3 className="text-lg font-semibold mb-4">🏢 Tạo Enterprise</h3>
          <form onSubmit={enterpriseForm.handleSubmit(onEnterpriseSubmit)} className="space-y-5">
            <Input
              label="Tên enterprise"
              placeholder="Tập đoàn ABC"
              {...enterpriseForm.register("name", { required: "Bắt buộc" })}
              error={enterpriseForm.formState.errors?.name?.message}
            />
            <Input
              label="Slug (tuỳ chọn)"
              placeholder="abc"
              {...enterpriseForm.register("slug")}
              error={enterpriseForm.formState.errors?.slug?.message}
            />
            <Button type="submit" className="w-full">Tạo Enterprise</Button>
            {enterpriseSuccess && <p className="text-green-600 text-sm text-center">✅ Đã tạo: {enterpriseSuccess.enterprise_id}</p>}
            {enterpriseError && <p className="text-red-500 text-sm text-center">❌ {enterpriseError}</p>}
          </form>
        </Card>

        {/* ====== Enable Module for Enterprise ====== */}
        <Card className="rounded-lg p-6">
          <h3 className="text-lg font-semibold mb-4">🧩 Bật module cho Enterprise</h3>
          <form onSubmit={enableEntForm.handleSubmit(onEnableEntSubmit)} className="space-y-5">
            <Input
              label="Enterprise ID"
              placeholder="UUID enterprise"
              {...enableEntForm.register("enterprise_id", { required: "Bắt buộc" })}
              error={enableEntForm.formState.errors?.enterprise_id?.message}
            />
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tên module</label>
              <select
                {...enableEntForm.register("module_name", { required: "Bắt buộc" })}
                className="w-full p-2 border border-gray-300 rounded"
                disabled={modsLoading}
                defaultValue=""
              >
                <option value="" disabled>
                  {modsLoading ? "Đang tải..." : "— Chọn module —"}
                </option>
                {availableModules.map((m) => (
                  <option key={m.key} value={m.key}>
                    {m.label} ({m.key})
                  </option>
                ))}
              </select>
            </div>
            <Textarea
              label="Config JSON (tuỳ chọn)"
              placeholder='{"some": "config"}'
              {...enableEntForm.register("config_json")}
            />
            <Button type="submit" className="w-full">Bật module</Button>
            {enableEntSuccess && (
              <p className="text-green-600 text-sm text-center">
                ✅ Đã bật: {enableEntSuccess.module_name} @ enterprise {enableEntSuccess.enterprise_id}
              </p>
            )}
            {enableEntError && <p className="text-red-500 text-sm text-center">❌ {enableEntError}</p>}
          </form>
        </Card>

        {/* ====== Create Company ====== */}
        <Card className="rounded-lg p-6">
          <h3 className="text-lg font-semibold mb-4">🏭 Tạo Company</h3>
          <form onSubmit={companyForm.handleSubmit(onCompanySubmit)} className="space-y-5">
            <Input
              label="Enterprise ID"
              placeholder="UUID enterprise"
              {...companyForm.register("enterprise_id", { required: "Bắt buộc" })}
              error={companyForm.formState.errors?.enterprise_id?.message}
            />
            <Input
              label="Tên company"
              placeholder="Chi nhánh Hà Nội"
              {...companyForm.register("name", { required: "Bắt buộc" })}
              error={companyForm.formState.errors?.name?.message}
            />
            <Input
              label="Slug (tuỳ chọn)"
              placeholder="hn-branch"
              {...companyForm.register("slug")}
              error={companyForm.formState.errors?.slug?.message}
            />
            <Input
              label="Parent Company ID (tuỳ chọn)"
              placeholder="UUID parent"
              {...companyForm.register("parent_company_id")}
              error={companyForm.formState.errors?.parent_company_id?.message}
            />
            <Button type="submit" className="w-full">Tạo Company</Button>
            {companySuccess && <p className="text-green-600 text-sm text-center">✅ Đã tạo: {companySuccess.company_id}</p>}
            {companyError && <p className="text-red-500 text-sm text-center">❌ {companyError}</p>}
          </form>
        </Card>

        {/* ====== Create Tenant ====== */}
        <Card className="rounded-lg p-6">
          <h3 className="text-lg font-semibold mb-4">📝 Tạo tổ chức (Tenant)</h3>
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
            <Button type="submit" className="w-full">Tạo Tenant</Button>
            {createSuccess && <p className="text-green-600 text-sm text-center">✅ Đã tạo: {createSuccess.tenant_id}</p>}
            {createError && <p className="text-red-500 text-sm text-center">❌ {createError}</p>}
          </form>
        </Card>

        {/* ====== Assign / Remove Module & Create User ====== */}
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
                disabled={modsLoading}
                defaultValue=""
              >
                <option value="" disabled>
                  {modsLoading ? "Đang tải..." : "— Chọn module —"}
                </option>
                {availableModules.map((m) => (
                  <option key={m.key} value={m.key}>
                    {m.label} ({m.key})
                  </option>
                ))}
              </select>
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

        <Card className="rounded-lg p-6">
          <h3 className="text-lg font-semibold mb-4">👤 Tạo user cho tổ chức</h3>
          <form onSubmit={userForm.handleSubmit(onUserSubmit)} className="space-y-5">
            <Input
              label="Tenant ID"
              placeholder="UUID tenant"
              {...userForm.register("tenant_id", { required: "Bắt buộc" })}
              error={userForm.formState.errors?.tenant_id?.message}
            />
            <Input
              label="Email"
              placeholder="email@example.com"
              {...userForm.register("email", { required: "Bắt buộc" })}
              error={userForm.formState.errors?.email?.message}
            />
            <Input
              label="Tên người dùng"
              placeholder="Nguyễn Văn A"
              {...userForm.register("name", { required: "Bắt buộc" })}
              error={userForm.formState.errors?.name?.message}
            />
            <Input
              label="Mật khẩu"
              type="password"
              {...userForm.register("password", { required: "Bắt buộc" })}
              error={userForm.formState.errors?.password?.message}
            />
            <Button type="submit" className="w-full">Tạo User</Button>
            {userSuccess && <p className="text-green-600 text-sm text-center">✅ {userSuccess.email || "Đã tạo user"}</p>}
            {userError && <p className="text-red-500 text-sm text-center">❌ {userError}</p>}
          </form>
        </Card>

        {/* ====== List tenants ====== */}
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
                  <td className="p-2 border">{(t.modules || []).join(", ")}</td>
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
