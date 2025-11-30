// src/app/pages/dashboards/iam/index.tsx
"use client";

import type React from "react";
import { useEffect, useState, type ChangeEvent, type FormEvent } from "react";
import { useForm, type SubmitHandler } from "react-hook-form";
import { Page } from "@/components/shared/Page";
import { Button, Card, Input } from "@/components/ui";
import axios, { type AxiosResponse } from "axios";
import { JWT_HOST_API } from "@/configs/auth";

const api = axios.create({ baseURL: JWT_HOST_API });

/** ==== TYPES ==== */
type ID = string;

interface JwtPayloadLike {
  tenant_id?: string;
  [k: string]: unknown;
}

interface Role {
  id: ID;
  name: string;
  module: string;
}

interface Permission {
  id: ID;
  resource: string;
  action: string;
  label: string;
}

interface AvailableModule {
  key: string;
  label: string;
}

/** Form types */
interface RoleFormValues {
  name: string;
  module: string;
}

interface AssignFormState {
  user_id: string;
  role_id: string;
}

/** Parse JWT (best effort) */
function parseJwt(token: string | null): JwtPayloadLike | null {
  try {
    if (!token) return null;
    const payload = token.split(".")[1];
    if (!payload) return null;
    return JSON.parse(atob(payload));
  } catch {
    return null;
  }
}

/** Always return string headers for fetch/axios */
function authHeader(): Record<string, string> {
  const token = (typeof window !== "undefined" && localStorage.getItem("authToken")) || "";
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export default function IamManagementPage(): React.ReactElement {
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const [selectedPerms, setSelectedPerms] = useState<ID[]>([]);
  const [availableModules, setAvailableModules] = useState<AvailableModule[]>([]);
  const roleForm = useForm<RoleFormValues>(); // { name, module }
  const [assignForm, setAssignForm] = useState<AssignFormState>({ user_id: "", role_id: "" });

  /** ===== API calls ===== */
  const fetchPermissions = async (): Promise<void> => {
    try {
      const res: AxiosResponse<Permission[]> = await api.get("/iam/permissions", { headers: authHeader() });
      setPermissions(res.data || []);
    } catch (err) {
      console.error("❌ Lỗi lấy permissions:", err);
    }
  };

  const fetchRoles = async (): Promise<void> => {
    try {
      const res: AxiosResponse<Role[]> = await api.get("/iam/roles", { headers: authHeader() });
      setRoles(res.data || []);
    } catch (err) {
      console.error("❌ Lỗi lấy roles:", err);
    }
  };

  const fetchAvailableModules = async (): Promise<void> => {
    try {
      const res: AxiosResponse<AvailableModule[]> = await api.get("/iam/available-modules");
      setAvailableModules(res.data || []);
    } catch (err) {
      console.error("❌ Lỗi lấy available modules:", err);
    }
  };

  useEffect(() => {
    void fetchPermissions();
    void fetchRoles();
    void fetchAvailableModules();
  }, []);

  /** ===== Handlers ===== */
  const onCreateRole: SubmitHandler<RoleFormValues> = async (data) => {
    try {
      if (!data?.module) {
        alert("⚠️ Module là bắt buộc.");
        return;
      }
      const res: AxiosResponse<{ role_id: ID }> = await api.post("/iam/roles", data, { headers: authHeader() });
      const role_id = res.data.role_id;

      if (selectedPerms.length > 0) {
        await api.post(
          "/iam/role-permissions",
          { role_id, permission_ids: selectedPerms },
          { headers: authHeader() }
        );
      }

      await fetchRoles();
      roleForm.reset();
      setSelectedPerms([]);
      alert("✅ Tạo role thành công");
    } catch (err: any) {
      alert("❌ Lỗi tạo role: " + (err?.response?.data || err?.message || String(err)));
    }
  };

  const togglePermission = (id: ID): void => {
    setSelectedPerms((prev) => (prev.includes(id) ? prev.filter((p) => p !== id) : [...prev, id]));
  };

  const assignRoleToUser = async (e: FormEvent<HTMLFormElement>): Promise<void> => {
    e.preventDefault();
    try {
      const payload = parseJwt(typeof window !== "undefined" ? localStorage.getItem("authToken") : null);
      if (!payload?.tenant_id) {
        alert("❌ Không thấy tenant_id trong JWT");
        return;
      }
      await api.post(
        "/iam/assign-role",
        { ...assignForm, tenant_id: payload.tenant_id },
        { headers: authHeader() }
      );
      alert("✅ Gán role thành công");
      setAssignForm({ user_id: "", role_id: "" });
    } catch (err: any) {
      alert("❌ Lỗi gán role: " + (err?.response?.data || err?.message || String(err)));
    }
  };

  /** ===== Render ===== */
  return (
    <Page title="Quản lý Role, Permission & Gán Role">
      <main className="grid grid-cols-1 md:grid-cols-3 gap-6 p-6">
        {/* 1) Tạo role & gán permission */}
        <Card className="p-6">
          <h2 className="text-lg font-semibold mb-4">Tạo role mới</h2>
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
                <option value="" disabled>
                  — Chọn module —
                </option>
                {availableModules.map((m) => (
                  <option key={m.key} value={m.key}>
                    {m.label} ({m.key})
                  </option>
                ))}
              </select>
              {roleForm.formState.errors?.module?.message && (
                <div className="text-red-600 text-xs mt-1">
                  {roleForm.formState.errors.module.message}
                </div>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium mb-1">Tick quyền để gán cho role:</label>
              <div className="grid grid-cols-1 gap-2 max-h-[220px] overflow-y-auto">
                {permissions.map((p) => (
                  <label key={p.id} className="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      checked={selectedPerms.includes(p.id)}
                      onChange={() => togglePermission(p.id)}
                    />
                    <span className="text-sm">
                      {p.resource}.{p.action} – {p.label}
                    </span>
                  </label>
                ))}
              </div>
            </div>
            <Button type="submit" className="w-full">
              Tạo Role
            </Button>
          </form>
        </Card>

        {/* 2) Danh sách role */}
        <Card className="p-6">
          <h2 className="text-lg font-semibold mb-4">Danh sách vai trò</h2>
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
          <h2 className="text-lg font-semibold mb-4">Gán role cho User</h2>
          <form onSubmit={assignRoleToUser} className="space-y-4">
            <Input
              label="User ID (UUID)"
              placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
              value={assignForm.user_id}
              onChange={(e: ChangeEvent<HTMLInputElement>) =>
                setAssignForm((s) => ({ ...s, user_id: e.target.value }))
              }
            />
            <Input
              label="Role ID"
              placeholder="Dán từ bảng vai trò"
              value={assignForm.role_id}
              onChange={(e: ChangeEvent<HTMLInputElement>) =>
                setAssignForm((s) => ({ ...s, role_id: e.target.value }))
              }
            />
            <Button type="submit" className="w-full">
              Gán Role
            </Button>
          </form>
          <p className="text-xs text-gray-500 mt-2">* Sau có thể đổi sang tìm user theo email.</p>
        </Card>
      </main>
    </Page>
  );
}
