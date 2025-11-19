import React, { useEffect, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { useSearchParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { AxiosError } from "axios";
import axiosInstance from "@/utils/axios";

import { Page } from "@/components/shared/Page";
import { Card, Button } from "@/components/ui";
import DynamicForm from "@/components/shared/DynamicForm";
import type { DynamicFieldConfig } from "@/components/shared/DynamicForm";
/* ================== Types ================== */
type ID = string;

interface Company {
  id: ID;
  display_name?: string | null;
  name?: string | null;
  email?: string | null;
  phone?: string | null;
}

interface Metadata {
  form?: {
    fields?: unknown;
  };
}

// ✅ CHỈ GIỮ LẠI CÁC FIELD CỐ ĐỊNH (không đổi)
interface ContactBaseFields {
  is_company: boolean;
  parent_id: string | null;
  created_at?: string | null;
  updated_at?: string | null;
}

// ✅ Form values = base + dynamic fields
type ContactFormValues = ContactBaseFields & Record<string, any>;

interface AppErrorShape {
  code: string;
  message: string;
  field?: string;
  http: number;
  raw: unknown;
}

// Use shared axios instance which includes Accept-Language header interceptor
const api = axiosInstance;

/* --- Constraint mapping cho validation errors --- */
const constraintMap: Record<string, { field: string; message: string }> = {
  contact_phone_digits_check: { field: "phone", message: "Số điện thoại chỉ gồm 8–15 chữ số." },
  contact_mobile_digits_check: { field: "mobile", message: "Số mobile chỉ gồm 8–15 chữ số." },
  contact_email_lower_check: { field: "email", message: "Email phải là chữ thường." },
  contact_email_format_check: { field: "email", message: "Email không hợp lệ." },
  contact_web_format_check: { field: "website", message: "URL không hợp lệ." },
  contact_country_code_check: { field: "country_code", message: "Mã quốc gia phải là 2 chữ cái in hoa." },
  contact_zip_check: { field: "zip", message: "Mã bưu chính không hợp lệ." },
};

/* --- Helpers --- */
function getAppError(err: unknown): AppErrorShape {
  const axiosErr = err as AxiosError<any>;
  const res = axiosErr?.response;
  const data = res?.data;

  if (data && typeof data === "object") {
    return {
      code: String((data as any).code || (data as any).sqlstate || ""),
      message: (data as any).message || (data as any).detail || "",
      field: (data as any).field,
      http: res?.status ?? 0,
      raw: data,
    };
  }

  return {
    code: "",
    message: axiosErr?.message || "Unknown error",
    field: undefined,
    http: res?.status ?? 0,
    raw: data,
  };
}

const normOrNull = (v: unknown): string | null => {
  if (v == null) return null;
  if (typeof v !== "string") return null;
  const s = v.trim();
  return s === "" ? null : s;
};

const sanitizeFieldPath = (field: string): string => {
  if (/^tags\.\d+$/.test(field)) return "tags";
  return field;
};

function isDynamicFieldConfig(x: any): x is DynamicFieldConfig {
  return (
    x &&
    typeof x === "object" &&
    typeof x.name === "string" &&
    typeof x.label === "string"
  );
}

function toDynamicFields(raw: unknown): DynamicFieldConfig[] {
  if (!Array.isArray(raw)) return [];
  return (raw as unknown[])
    .filter(isDynamicFieldConfig)
    .map((f) => ({
      type: "text",
      width: 12,
      required: false,
      disabled: false,
      options: [],
      ...f,
    }));
}

/* ================== Component ================== */
const ContactCreatePage: React.FC = () => {
  const { i18n } = useTranslation(); // Get i18n instance to listen to language changes
  const [metadata, setMetadata] = useState<Metadata | null>(null);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loadingContact, setLoadingContact] = useState<boolean>(false);
  const [isEditing, setIsEditing] = useState<boolean>(false);
  const [localContactId, setLocalContactId] = useState<ID | null>(null);
  const [saving, setSaving] = useState<boolean>(false);

  const form = useForm<ContactFormValues>({ shouldUnregister: false });

  const [searchParams] = useSearchParams();
  const contactId: ID | null = (searchParams.get("id") as ID | null) || localContactId;
  const token = localStorage.getItem("authToken");

  // ✅ Tạo default values từ metadata fields
  const getDefaultValues = useCallback((fields: DynamicFieldConfig[]): ContactFormValues => {
    const defaults: ContactFormValues = {
      is_company: false, // Mặc định là Cá nhân
      parent_id: null,
      created_at: null,
      updated_at: null,
    };

    fields.forEach((field) => {
      if (field.type === "checkbox") {
        defaults[field.name] = false;
      } else if (field.name === "tags") {
        defaults[field.name] = [];
      } else {
        defaults[field.name] = null;
      }
    });

    return defaults;
  }, []);

  const fetchMetadata = useCallback(async () => {
    try {
      // Use axiosInstance which automatically includes Accept-Language header
      // The interceptor will read from URL parameter or i18n.language
      const currentLang = typeof window !== "undefined" 
        ? new URLSearchParams(window.location.search).get("lang") || i18n.language || "vi"
        : i18n.language || "vi";
      
      if (process.env.NODE_ENV === "development") {
        console.log(`[contact-create] Fetching metadata with language: ${currentLang}`);
      }
      
      const res = await api.get<Metadata>("/contact/metadata");
      setMetadata(res.data);
    } catch (err) {
      const e = getAppError(err);
      console.error("❌ Lỗi load metadata:", e.message);
    }
  }, [i18n]);

  const fetchCompanies = useCallback(async () => {
    try {
      const res = await api.get<Company[] | { items?: Company[] }>("/contact/list", {
        headers: { Authorization: `Bearer ${token}` },
        params: { is_company: true, limit: 200 },
      });
      const items = Array.isArray(res.data) ? res.data : res.data?.items ?? [];
      setCompanies(items);
    } catch (err) {
      const e = getAppError(err);
      console.error("❌ Lỗi load danh sách công ty:", e.message);
    }
  }, [token]);

  const fetchContact = useCallback(
    async (id: ID | null = contactId) => {
      const fields = toDynamicFields(metadata?.form?.fields);

      if (!id) {
        setIsEditing(true);
        form.reset(getDefaultValues(fields));
        return;
      }

      setLoadingContact(true);
      try {
        const res = await api.get<Record<string, any>>(`/contact/${id}`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const dto = res.data || {};

        // ✅ Auto-map tất cả fields từ API response
        const formData: ContactFormValues = {
          is_company: !!dto.is_company,
          parent_id: dto.parent_id ?? null,
          created_at: dto.created_at ?? null,
          updated_at: dto.updated_at ?? null,
        };

        // Map dynamic fields
        fields.forEach((field) => {
          const value = dto[field.name];

          if (field.name === "tags") {
            // Xử lý tags đặc biệt
            if (typeof dto.tags_cached === "string") {
              formData.tags = dto.tags_cached.split(",").map((s) => s.trim()).filter(Boolean);
            } else if (Array.isArray(value)) {
              formData.tags = value;
            } else {
              formData.tags = [];
            }
          } else {
            formData[field.name] = value ?? null;
          }
        });

        form.reset(formData);
        setIsEditing(false);
      } catch (err) {
        const e = getAppError(err);
        alert(`❌ Lỗi load liên hệ: ${e.message}`);
      } finally {
        setLoadingContact(false);
      }
    },
    [contactId, token, form, metadata, getDefaultValues]
  );

  useEffect(() => {
    fetchMetadata();
    fetchCompanies();
  }, [fetchMetadata, fetchCompanies]);

  // Refetch metadata when language changes
  useEffect(() => {
    // Add small delay to ensure i18n.language is fully updated
    const timer = setTimeout(() => {
      fetchMetadata();
    }, 100);
    return () => clearTimeout(timer);
  }, [i18n.language, fetchMetadata]);

  // Chỉ fetch contact khi đã có metadata
  useEffect(() => {
    if (metadata) {
      fetchContact();
    }
  }, [metadata, contactId]);

  const onSubmit = async (data: ContactFormValues) => {
    // ✅ Auto-build payload từ tất cả fields
    const payload: Record<string, any> = {
      is_company: !!data.is_company,
      parent_id: data.parent_id || null,
    };

    const fields = toDynamicFields(metadata?.form?.fields);
    fields.forEach((field) => {
      const value = data[field.name];

      if (field.type === "text" || field.type === "email" || field.type === "textarea") {
        payload[field.name] = normOrNull(value);
      } else if (field.name === "tags" && Array.isArray(value)) {
        payload.tags = value;
      } else {
        payload[field.name] = value ?? null;
      }
    });

    try {
      setSaving(true);

      if (contactId) {
        await api.post(`/contact/${contactId}/update`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
        await fetchContact(contactId);
        setIsEditing(false);
      } else {
        const res = await api.post<{ id?: ID }>(`/contact/create`, payload, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const newId = res.data?.id;
        if (newId) {
          setLocalContactId(newId);
          await fetchContact(newId);
          setIsEditing(false);
        } else {
          alert("❌ Không lấy được ID liên hệ mới");
        }
      }
    } catch (err) {
      const e = getAppError(err);

      let field = (e.field || "").toString();
      let message = e.message || "Dữ liệu không hợp lệ";

      if (!field) {
        const rawMsg = (e.message || "").toLowerCase();
        const found = Object.entries(constraintMap).find(([k]) =>
          rawMsg.includes(k.toLowerCase())
        );
        if (found) {
          const [, map] = found;
          field = map.field;
          message = map.message;
        }
      }

      field = sanitizeFieldPath(field);

      // ✅ Dynamic setError - không cần type check
      if (field && field in data) {
        form.setError(field as any, { type: "server", message });
        form.setValue(field as any, data[field] ?? "");
        form.setFocus(field as any);
      } else {
        alert(`❌ Lỗi lưu liên hệ: ${e.code ? `[${e.code}] ` : ""}${message}`);
      }

      setIsEditing(true);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!contactId) return;
    const confirmDelete = window.confirm("Bạn có chắc muốn xóa liên hệ này?");
    if (!confirmDelete) return;
    try {
      await api.delete(`/contact/${contactId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      window.location.href = "/dashboards/contact/list";
    } catch (err) {
      const e = getAppError(err);
      alert(`❌ Lỗi xóa liên hệ: ${e.message}`);
    }
  };

  const handleCancel = () => fetchContact();

  return (
    <Page title={contactId ? "✏️ Chi tiết liên hệ" : "Tạo liên hệ mới"}>
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-2">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              {contactId ? "Chi tiết liên hệ" : "Tạo liên hệ mới"}
            </h2>
            {loadingContact && (
              <span className="ml-3 text-xs text-gray-400">Đang tải dữ liệu liên hệ…</span>
            )}
          </div>
          <div className="flex gap-2">
            {contactId && !isEditing && (
              <Button className="min-w-[7rem]" onClick={() => setIsEditing(true)}>
                Chỉnh sửa
              </Button>
            )}
            {isEditing && (
              <>
                <Button
                  className="min-w-[7rem]"
                  variant="outlined"
                  onClick={handleCancel}
                  disabled={saving}
                >
                  Hủy
                </Button>
                {contactId && (
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
                  form="contact-form"
                  disabled={saving}
                >
                  {saving ? "Đang lưu..." : "Lưu"}
                </Button>
              </>
            )}
          </div>
        </div>

        <form autoComplete="off" onSubmit={form.handleSubmit(onSubmit)} id="contact-form">
          <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
            <div className="col-span-12 lg:col-span-8">
              <Card className="p-4 sm:px-5">
                <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Thông tin liên hệ
                </h3>

                <div className="mt-5 space-y-5">
                  {/* Custom Company Fields */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Phân loại */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-dark-100 mb-2">
                        Phân loại
                      </label>
                      <div className="grid grid-cols-2 gap-2">
                        {/* Cá nhân */}
                        <label
                          className={`relative flex min-w-0 cursor-pointer items-center justify-between gap-2 rounded-lg border p-3 ${
                            !form.watch("is_company")
                              ? "border-primary-500 ring-1 ring-primary-500/30"
                              : "border-gray-200 dark:border-dark-600"
                          }`}
                        >
                          <div className="flex min-w-0 gap-2">
                            <span className="text-sm">Cá nhân</span>
                          </div>
                          <input
                            type="radio"
                            name="contact_type"
                            className="size-4"
                            checked={!form.watch("is_company")}
                            onChange={() => form.setValue("is_company", false)}
                            disabled={!isEditing}
                          />
                        </label>

                        {/* Công ty */}
                        <label
                          className={`relative flex min-w-0 cursor-pointer items-center justify-between gap-2 rounded-lg border p-3 ${
                            form.watch("is_company")
                              ? "border-primary-500 ring-1 ring-primary-500/30"
                              : "border-gray-200 dark:border-dark-600"
                          }`}
                        >
                          <div className="flex min-w-0 gap-2">
                            <span className="text-sm">Công ty</span>
                          </div>
                          <input
                            type="radio"
                            name="contact_type"
                            className="size-4"
                            checked={form.watch("is_company")}
                            onChange={() => form.setValue("is_company", true)}
                            disabled={!isEditing}
                          />
                        </label>
                      </div>
                    </div>

                    {/* Thuộc công ty */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-dark-100 mb-2">
                        Thuộc công ty
                      </label>
                      <label
                        className={`relative flex min-w-0 cursor-pointer items-center justify-between gap-2 rounded-lg border p-3 ${
                          form.watch("parent_id")
                            ? "border-primary-500 ring-1 ring-primary-500/30"
                            : "border-gray-200 dark:border-dark-600"
                        }`}
                      >
                        <div className="flex min-w-0 gap-2">
                          <span className="text-sm">
                            {(() => {
                              const parentId = form.watch("parent_id");
                              const company = companies.find(c => c.id === parentId);
                              return company ? (company.display_name || company.name || company.email || company.phone || company.id) : "-- Chọn Thuộc công ty --";
                            })()}
                          </span>
                        </div>
                        <select
                          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                          value={form.watch("parent_id") || ""}
                          onChange={(e) => form.setValue("parent_id", e.target.value || null)}
                          disabled={!isEditing}
                        >
                          <option value="">-- Chọn Thuộc công ty --</option>
                          {companies.map((c) => (
                            <option key={c.id} value={c.id}>
                              {c.display_name || c.name || c.email || c.phone || c.id}
                            </option>
                          ))}
                        </select>
                        <svg className="size-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                        </svg>
                      </label>
                    </div>
                  </div>

                  {/* Dynamic Form cho các field khác (loại bỏ is_company và parent_id) */}
                  <DynamicForm
                    form={form}
                    fields={toDynamicFields(metadata?.form?.fields).filter(field => 
                      field.name !== 'is_company' && field.name !== 'parent_id'
                    )}
                    disabled={!isEditing}
                    optionsMap={{
                      parent_id: (companies || []).map((c) => ({
                        value: c.id,
                        label: c.display_name || c.name || c.email || c.phone || c.id,
                      })),
                    }}
                  />
                </div>
              </Card>
            </div>

            <div className="col-span-12 lg:col-span-4 space-y-4 sm:space-y-5 lg:space-y-6">
              <Card className="p-4 sm:px-5">
                <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Thông tin khác
                </h6>
                <div className="mt-3 text-sm text-gray-600 dark:text-dark-50 space-y-2">
                  <div>
                    <span className="opacity-70">Là công ty:&nbsp;</span>
                    {form.watch("is_company") ? "Có" : "Không"}
                  </div>
                  <div className="opacity-70">
                    Cập nhật lần cuối: {form.watch("updated_at") || "—"}
                  </div>
                  <div className="opacity-70">Tạo lúc: {form.watch("created_at") || "—"}</div>
                </div>
              </Card>
            </div>
          </div>
        </form>
      </div>
    </Page>
  );
};

export default ContactCreatePage;