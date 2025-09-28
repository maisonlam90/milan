import React, { useEffect, useState, useCallback } from "react";
import { useForm, FieldPath, UseFormReturn } from "react-hook-form";
import { useSearchParams } from "react-router-dom";
import axios, { AxiosError } from "axios";

/* === Imports (giữ alias @ nếu bạn đã map trong tsconfig & bundler) === */
import { Page } from "@/components/shared/Page";
import { Card, Button } from "@/components/ui";
import DynamicForm from "@/components/shared/DynamicForm";
import type { DynamicFieldConfig } from "@/components/shared/DynamicForm";
import { JWT_HOST_API } from "@/configs/auth";

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
    fields?: unknown; // sẽ chuẩn hoá bằng toDynamicFields
  };
}

interface ContactDTO {
  id?: ID;
  is_company?: boolean;
  parent_id?: ID | null;
  name?: string | null;
  display_name?: string | null;
  email?: string | null;
  phone?: string | null;
  mobile?: string | null;
  website?: string | null;
  street?: string | null;
  street2?: string | null;
  city?: string | null;
  state?: string | null;
  zip?: string | null;
  country_code?: string | null;
  notes?: string | null;
  tags?: string[];             // có thể array
  tags_cached?: string | null; // hoặc "a,b,c"
  idempotency_key?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
}

type ContactFormValues = Required<Pick<ContactDTO,
  | "is_company"
  | "parent_id"
  | "name"
  | "display_name"
  | "email"
  | "phone"
  | "mobile"
  | "website"
  | "street"
  | "street2"
  | "city"
  | "state"
  | "zip"
  | "country_code"
  | "notes"
  | "idempotency_key"
>> & {
  tags?: string[];
  created_at?: string | null;
  updated_at?: string | null;
};

interface AppErrorShape {
  code: string;
  message: string;
  field?: string;
  http: number;
  raw: unknown;
}

const api = axios.create({ baseURL: JWT_HOST_API });

/* --- Map constraint Postgres -> field + message --- */
const constraintMap: Record<
  string,
  { field: keyof ContactFormValues; message: string }
> = {
  contact_phone_digits_check:  { field: "phone",        message: "Số điện thoại chỉ gồm 8–15 chữ số." },
  contact_mobile_digits_check: { field: "mobile",       message: "Số mobile chỉ gồm 8–15 chữ số." },
  contact_email_lower_check:   { field: "email",        message: "Email phải là chữ thường." },
  contact_email_format_check:  { field: "email",        message: "Email không hợp lệ." },
  contact_web_format_check:    { field: "website",      message: "URL không hợp lệ (ví dụ: https://example.com)." },
  contact_country_code_check:  { field: "country_code", message: "Mã quốc gia phải là 2 chữ cái in hoa (VD: VN, US)." },
  contact_zip_check:           { field: "zip",          message: "Mã bưu chính không hợp lệ." },
};

/* --- Helpers --- */
function getAppError(err: unknown): AppErrorShape {
  const axiosErr = err as AxiosError<any>;
  const res = axiosErr?.response;
  const data = res?.data;

  if (data && typeof data === "object") {
    return {
      code: String((data as any).code || (data as any).sqlstate || (data as any).error_code || ""),
      message: (data as any).message || (data as any).error || (data as any).detail || (data as any).reason || "",
      field: (data as any).field || (data as any).path,
      http: res?.status ?? 0,
      raw: data,
    };
  }

  if (typeof data === "string") {
    return { code: "", message: data, field: undefined, http: res?.status ?? 0, raw: data };
  }

  const fallback =
    (axiosErr && axiosErr.message) ||
    (typeof data !== "undefined" ? JSON.stringify(data) : "Unknown error");
  return { code: "", message: fallback, field: undefined, http: res?.status ?? 0, raw: data };
}

const normOrNull = (v: unknown): string | null | undefined => {
  if (v == null) return null;
  if (typeof v !== "string") return (v as any) ?? null;
  const s = v.trim();
  return s === "" ? null : s;
};

function safeField<T extends Record<string, any>>(
  key: string,
  form: UseFormReturn<T>
): FieldPath<T> | undefined {
  if (key in (form.getValues() as Record<string, any>)) {
    return key as FieldPath<T>;
  }
  return undefined;
}

/** Gom các path kiểu `tags.0`, `tags.1` về key gốc `tags` để tránh lỗi index type */
const sanitizeFieldPath = (field: string): string => {
  if (/^tags\.\d+$/.test(field)) return "tags";
  return field;
};

/** Type guard cho DynamicFieldConfig */
function isDynamicFieldConfig(x: any): x is DynamicFieldConfig {
  return (
    x &&
    typeof x === "object" &&
    typeof x.name === "string" &&
    typeof x.label === "string" &&
    (x.type === undefined ||
      ["text", "textarea", "select", "date", "number", "email", "checkbox"].includes(x.type)) &&
    (x.width === undefined || [3, 4, 6, 8, 12].includes(x.width))
  );
}

/** Chuẩn hoá metadata.form.fields -> DynamicFieldConfig[] */
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
  const [metadata, setMetadata] = useState<Metadata | null>(null);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loadingContact, setLoadingContact] = useState<boolean>(false);
  const [isEditing, setIsEditing] = useState<boolean>(false);
  const [localContactId, setLocalContactId] = useState<ID | null>(null);
  const [saving, setSaving] = useState<boolean>(false);

  // GIỮ state khi re-render
  const form = useForm<ContactFormValues>({ shouldUnregister: false });

  const [searchParams] = useSearchParams();
  const contactId: ID | null = (searchParams.get("id") as ID | null) || localContactId;
  const token = localStorage.getItem("authToken");

  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get<Metadata>("/contact/metadata");
      setMetadata(res.data);
    } catch (err) {
      const e = getAppError(err);
      console.error("❌ Lỗi load metadata:", e.message, e.raw || "");
    }
  }, []);

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
      if (!id) {
        setIsEditing(true);
        form.reset({
          is_company: false,
          parent_id: null,
          name: null,
          display_name: null,
          email: null,
          phone: null,
          mobile: null,
          website: null,
          street: null,
          street2: null,
          city: null,
          state: null,
          zip: null,
          country_code: null,
          notes: null,
          idempotency_key: null,
          tags: [],
          created_at: null,
          updated_at: null,
        });
        return;
      }
      setLoadingContact(true);
      try {
        const res = await api.get<ContactDTO>(`/contact/${id}`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const dto = res.data || {};
        const tagsArray =
          typeof dto.tags_cached === "string"
            ? dto.tags_cached.split(",").map((s) => s.trim()).filter(Boolean)
            : (Array.isArray(dto.tags) ? dto.tags : []);
        form.reset({
          is_company: !!dto.is_company,
          parent_id: dto.parent_id ?? null,
          name: dto.name ?? null,
          display_name: dto.display_name ?? null,
          email: dto.email ?? null,
          phone: dto.phone ?? null,
          mobile: dto.mobile ?? null,
          website: dto.website ?? null,
          street: dto.street ?? null,
          street2: dto.street2 ?? null,
          city: dto.city ?? null,
          state: dto.state ?? null,
          zip: dto.zip ?? null,
          country_code: dto.country_code ?? null,
          notes: dto.notes ?? null,
          idempotency_key: dto.idempotency_key ?? null,
          tags: tagsArray,
          created_at: dto.created_at ?? null,
          updated_at: dto.updated_at ?? null,
        });
        setIsEditing(false);
      } catch (err) {
        const e = getAppError(err);
        alert(`❌ Lỗi load liên hệ: ${e.message}`);
      } finally {
        setLoadingContact(false);
      }
    },
    [contactId, token, form]
  );

  useEffect(() => {
    fetchMetadata();
    fetchCompanies();
    fetchContact();
  }, [fetchMetadata, fetchCompanies, fetchContact]);

  const onSubmit = async (data: ContactFormValues) => {
    const payload: Partial<ContactDTO> = {
      is_company: !!data.is_company,
      parent_id: data.parent_id || null,
      name: normOrNull(data.name) ?? null,
      display_name: normOrNull(data.display_name) ?? null,
      email: normOrNull(data.email) ?? null,
      phone: data.phone ?? null,        // giữ raw, DB CHECK validate
      mobile: data.mobile ?? null,      // giữ raw
      website: normOrNull(data.website) ?? null,
      street: normOrNull(data.street) ?? null,
      street2: normOrNull(data.street2) ?? null,
      city: normOrNull(data.city) ?? null,
      state: normOrNull(data.state) ?? null,
      zip: normOrNull(data.zip) ?? null,
      country_code: normOrNull(data.country_code) ?? null,
      notes: normOrNull(data.notes) ?? null,
      tags: Array.isArray(data.tags) ? data.tags : undefined,
      idempotency_key: (normOrNull(data.idempotency_key) ?? undefined) as string | undefined,
    };

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

      // Ưu tiên field từ BE
      let field = (e.field || "").toString();
      let message = e.message || "Dữ liệu không hợp lệ";

      // Nếu chưa có field, dò theo tên constraint trong message
      const rawMsg = (e.message || "").toLowerCase();
      if (!field) {
        const found = Object.entries(constraintMap).find(([k]) =>
          rawMsg.includes(k.toLowerCase())
        );
        if (found) {
          const [, map] = found;
          field = map.field as string;
          message = map.message;
        }
      }

      // ✅ Fix: gom 'tags.0', 'tags.1' -> 'tags'
      field = sanitizeFieldPath(field);

      const typedField = safeField<ContactFormValues>(field, form);
      if (typedField) {
        form.setError(typedField, { type: "server", message });
        const current = form.getValues(typedField);

        // ép kiểu mềm để input không lỗi
        form.setValue(typedField as any, (current ?? "") as any, { shouldDirty: true });
        form.setFocus(typedField);
      } else {
        // Không match constraint/field → fallback alert
        alert(`❌ Lỗi lưu liên hệ: ${e.code ? `[${e.code}] ` : ""}${e.message}`);
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
    <Page title={contactId ? "✏️ Chi tiết liên hệ" : "👤 Tạo liên hệ mới"}>
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
                  <DynamicForm
                    form={form}
                    fields={toDynamicFields(metadata?.form?.fields)}
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
