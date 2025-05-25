import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { Page } from "components/shared/Page";
import { Button, Card, Input } from "components/ui";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function AclManagementPage() {
  const [roles, setRoles] = useState([]);
  const [permissions, setPermissions] = useState([]);
  const [selectedPerms, setSelectedPerms] = useState([]);
  const roleForm = useForm();

  const fetchPermissions = async () => {
    try {
      const token = localStorage.getItem("authToken");
      const res = await api.get("/acl/permissions", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      setPermissions(res.data);
    } catch (err) {
      console.error("❌ Lỗi lấy danh sách permissions:", err);
    }
  };

  const fetchRoles = async () => {
    try {
      const token = localStorage.getItem("authToken");
      const res = await api.get("/acl/roles", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      setRoles(res.data);
    } catch (err) {
      console.error("❌ Lỗi lấy danh sách roles:", err);
    }
  };

  useEffect(() => {
    fetchPermissions();
    fetchRoles();
  }, []);

  const onCreateRole = async (data) => {
    try {
      const token = localStorage.getItem("authToken");
      const res = await api.post("/acl/roles", data, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      const role_id = res.data.role_id;
      if (selectedPerms.length > 0) {
        await api.post(
          "/acl/role-permissions",
          { role_id, permission_ids: selectedPerms },
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );
      }
      fetchRoles();
      roleForm.reset();
      setSelectedPerms([]);
      alert("✅ Tạo role thành công");
    } catch (err) {
      alert("❌ Lỗi tạo role: " + (err.response?.data || err.message));
    }
  };

  const togglePermission = (id) => {
    setSelectedPerms((prev) =>
      prev.includes(id) ? prev.filter((p) => p !== id) : [...prev, id]
    );
  };

  return (
    <Page title="🔐 Quản lý Role & Permission">
      <main className="grid grid-cols-1 md:grid-cols-2 gap-6 p-6">
        <Card className="p-6">
          <h2 className="text-lg font-semibold mb-4">🆕 Tạo role mới</h2>
          <form onSubmit={roleForm.handleSubmit(onCreateRole)} className="space-y-4">
            <Input
              label="Tên role"
              placeholder="admin, editor, ..."
              {...roleForm.register("name", { required: "Bắt buộc" })}
              error={roleForm.formState.errors?.name?.message}
            />
            <Input
              label="Module (tuỳ chọn)"
              placeholder="user, payment..."
              {...roleForm.register("module")}
            />
            <div>
              <label className="block text-sm font-medium mb-1">Quyền:</label>
              <div className="grid grid-cols-1 gap-2 max-h-[200px] overflow-y-auto">
                {permissions.map((p) => (
                  <label key={p.id} className="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      checked={selectedPerms.includes(p.id)}
                      onChange={() => togglePermission(p.id)}
                    />
                    <span className="text-sm">{p.resource}.{p.action} – {p.label}</span>
                  </label>
                ))}
              </div>
            </div>
            <Button type="submit" className="w-full">Tạo Role</Button>
          </form>
        </Card>

        <Card className="p-6">
          <h2 className="text-lg font-semibold mb-4">📋 Danh sách vai trò (Roles)</h2>
          <table className="w-full text-sm border border-gray-300">
            <thead className="bg-gray-100">
              <tr>
                <th className="p-2 border">Tên role</th>
                <th className="p-2 border">Module</th>
              </tr>
            </thead>
            <tbody>
              {roles.map((role) => (
                <tr key={role.id}>
                  <td className="p-2 border">{role.name}</td>
                  <td className="p-2 border">{role.module || "(chung)"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      </main>
    </Page>
  );
}