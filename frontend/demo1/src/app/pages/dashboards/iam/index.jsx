import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import { Button, Card, Input } from "components/ui";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";

const api = axios.create({ baseURL: JWT_HOST_API });

function parseJwt(token) { try { return token ? JSON.parse(atob(token.split(".")[1])) : null; } catch { return null; } }

export default function IamManagementPage() {
  const [roles, setRoles] = useState([]);
  const [permissions, setPermissions] = useState([]);
  const [selectedPerms, setSelectedPerms] = useState([]);
  const [availableModules, setAvailableModules] = useState([]);   // 👈
  const roleForm = useForm();   // { name, module }
  const permForm = useForm();   // { resource, action, label }
  const [assignForm, setAssignForm] = useState({ user_id: "", role_id: "" });
  const [moduleKey, setModuleKey] = useState("");

  const authHeader = () => {
    const token = localStorage.getItem("authToken");
    return token ? { Authorization: `Bearer ${token}` } : {};
  };

  const fetchPermissions = async () => {
    try { const res = await api.get("/iam/permissions", { headers: authHeader() }); setPermissions(res.data || []); }
    catch (err) { console.error("❌ Lỗi lấy permissions:", err); }
  };
  const fetchRoles = async () => {
    try { const res = await api.get("/iam/roles", { headers: authHeader() }); setRoles(res.data || []); }
    catch (err) { console.error("❌ Lỗi lấy roles:", err); }
  };
  const fetchAvailableModules = async () => {                        // 👈
    try { const res = await api.get("/iam/available-modules"); setAvailableModules(res.data || []); }
    catch (err) { console.error("❌ Lỗi lấy available modules:", err); }
  };

  useEffect(() => {
    fetchPermissions();
    fetchRoles();
    fetchAvailableModules();                                         // 👈
  }, []);

  const onCreateRole = async (data) => {
    try {
      if (!data?.module) { alert("⚠️ Module là bắt buộc."); return; }
      const res = await api.post("/iam/roles", data, { headers: authHeader() });
      const role_id = res.data.role_id;
      if (selectedPerms.length > 0) {
        await api.post("/iam/role-permissions", { role_id, permission_ids: selectedPerms }, { headers: authHeader() });
      }
      await fetchRoles();
      roleForm.reset();
      setSelectedPerms([]);
      alert("✅ Tạo role thành công");
    } catch (err) { alert("❌ Lỗi tạo role: " + (err.response?.data || err.message)); }
  };

  const togglePermission = (id) => {
    setSelectedPerms((prev) => prev.includes(id) ? prev.filter((p) => p !== id) : [...prev, id]);
  };

  const assignRoleToUser = async (e) => {
    e.preventDefault();
    try {
      const payload = parseJwt(localStorage.getItem("authToken"));
      if (!payload?.tenant_id) { alert("❌ Không thấy tenant_id trong JWT"); return; }
      await api.post("/iam/assign-role", { ...assignForm, tenant_id: payload.tenant_id }, { headers: authHeader() });
      alert("✅ Gán role thành công");
      setAssignForm({ user_id: "", role_id: "" });
    } catch (err) { alert("❌ Lỗi gán role: " + (err.response?.data || err.message)); }
  };

  const onCreatePermission = async (data) => {
    try {
      if (!data.resource || !data.action || !data.label) { alert("⚠️ Điền đủ resource, action, label"); return; }
      await api.post("/iam/permissions", data, { headers: authHeader() });
      await fetchPermissions();
      permForm.reset();
      alert("✅ Tạo permission thành công");
    } catch (err) { alert("❌ Lỗi tạo permission: " + (err.response?.data || err.message)); }
  };

  const createModuleAccess = async () => {
    const key = moduleKey.trim();
    if (!key) { alert("⚠️ Chọn module"); return; }
    const body = { resource: `module.${key}`, action: "access", label: `Truy cập module ${key}` };
    try {
      await api.post("/iam/permissions", body, { headers: authHeader() });
      await fetchPermissions();
      setModuleKey("");
      alert("✅ Tạo permission module.access thành công");
    } catch (err) { alert("❌ Lỗi tạo permission module: " + (err.response?.data || err.message)); }
  };

  return (
    <Page title="🔐 Quản lý Role, Permission & Gán Role">
      <main className="grid grid-cols-1 md:grid-cols-3 gap-6 p-6">
        {/* 1) Tạo role & gán permission */}
        <Card className="p-6">
          <h2 className="text-lg font-semibold mb-4">🆕 Tạo role mới</h2>
          <form onSubmit={roleForm.handleSubmit(onCreateRole)} className="space-y-4">
            <Input
              label="Tên role"
              placeholder="admin, editor..."
              {...roleForm.register("name", { required: "Bắt buộc" })}
              error={roleForm.formState.errors?.name?.message}
            />
            {/* Dropdown module từ bảng available_modules */}
            <div>
              <label className="block text-sm font-medium mb-1">Module</label>
              <select
                className="w-full border rounded px-3 py-2"
                defaultValue=""
                {...roleForm.register("module", { required: "Bắt buộc" })}
              >
                <option value="" disabled>— Chọn module —</option>
                {availableModules.map(m => (
                  <option key={m.key} value={m.key}>{m.label} ({m.key})</option>
                ))}
              </select>
              {roleForm.formState.errors?.module?.message && (
                <div className="text-red-600 text-xs mt-1">{roleForm.formState.errors.module.message}</div>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium mb-1">Tick quyền để gán cho role:</label>
              <div className="grid grid-cols-1 gap-2 max-h-[220px] overflow-y-auto">
                {permissions.map((p) => (
                  <label key={p.id} className="flex items-center space-x-2">
                    <input type="checkbox" checked={selectedPerms.includes(p.id)} onChange={() => togglePermission(p.id)} />
                    <span className="text-sm">{p.resource}.{p.action} – {p.label}</span>
                  </label>
                ))}
              </div>
            </div>
            <Button type="submit" className="w-full">Tạo Role</Button>
          </form>
        </Card>

        {/* 2) Danh sách role */}
        <Card className="p-6">
          <h2 className="text-lg font-semibold mb-4">📋 Danh sách vai trò</h2>
          <table className="w-full text-sm border border-gray-300">
            <thead className="bg-gray-100">
              <tr>
                <th className="p-2 border">Tên role</th>
                <th className="p-2 border">Module</th>
                <th className="p-2 border">Role ID</th>
              </tr>
            </thead>
            <tbody>
              {roles.map((role) => (
                <tr key={role.id}>
                  <td className="p-2 border">{role.name}</td>
                  <td className="p-2 border">{role.module}</td>
                  <td className="p-2 border font-mono text-xs">{role.id}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>

        {/* 3) Gán role cho user */}
        <Card className="p-6">
          <h2 className="text-lg font-semibold mb-4">👤 Gán role cho User</h2>
          <form onSubmit={assignRoleToUser} className="space-y-4">
            <Input label="User ID (UUID)" placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
              value={assignForm.user_id}
              onChange={(e) => setAssignForm((s) => ({ ...s, user_id: e.target.value }))}
            />
            <Input label="Role ID" placeholder="Dán từ bảng vai trò"
              value={assignForm.role_id}
              onChange={(e) => setAssignForm((s) => ({ ...s, role_id: e.target.value }))}
            />
            <Button type="submit" className="w-full">Gán Role</Button>
          </form>
          <p className="text-xs text-gray-500 mt-2">* Sau có thể đổi sang tìm user theo email.</p>
        </Card>

        {/* 4) Tạo permission (thường + module.access) */}
        <Card className="p-6">
          <h2 className="text-lg font-semibold mb-4">🧩 Tạo Permission</h2>

          {/* Tạo permission thường */}
          <form onSubmit={permForm.handleSubmit(onCreatePermission)} className="space-y-3 mb-4">
            <Input label="Resource" placeholder="vd: user, report, module.payment"
              {...permForm.register("resource", { required: "Bắt buộc" })}
              error={permForm.formState.errors?.resource?.message}
            />
            <Input label="Action" placeholder="vd: read | create | update | delete | access"
              {...permForm.register("action", { required: "Bắt buộc" })}
              error={permForm.formState.errors?.action?.message}
            />
            <Input label="Label" placeholder="Tên hiển thị"
              {...permForm.register("label", { required: "Bắt buộc" })}
              error={permForm.formState.errors?.label?.message}
            />
            <Button type="submit" className="w-full">Tạo Permission</Button>
          </form>

          <div className="border-t my-4" />

          {/* Shortcut: tạo module.<key>.access bằng dropdown */}
          <div className="space-y-3">
            <h3 className="text-base font-semibold">⚡ Tạo Permission Module Access</h3>
            <label className="block text-sm font-medium mb-1">Module</label>
            <select
              className="w-full border rounded px-3 py-2"
              value={moduleKey}
              onChange={(e) => setModuleKey(e.target.value)}
            >
              <option value="">— Chọn module —</option>
              {availableModules.map(m => (
                <option key={m.key} value={m.key}>{m.label} ({m.key})</option>
              ))}
            </select>
            <Button onClick={createModuleAccess} className="w-full">Tạo module.&lt;key&gt;.access</Button>
            <p className="text-xs text-gray-500">* Ví dụ chọn <b>payment</b> sẽ tạo <code>module.payment.access</code></p>
          </div>
        </Card>
      </main>
    </Page>
  );
}
