import { useEffect, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { useSearchParams } from "react-router-dom";
import { Page } from "components/shared/Page";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Card, Button } from "components/ui";
import DynamicForm from "components/shared/DynamicForm";

const api = axios.create({ baseURL: JWT_HOST_API });

// --- Map constraint Postgres -> field + message đẹp
const constraintMap = {
  contact_phone_digits_check:  { field: "phone",        message: "Số điện thoại chỉ gồm 8–15 chữ số." },
  contact_mobile_digits_check: { field: "mobile",       message: "Số mobile chỉ gồm 8–15 chữ số." },
  contact_email_lower_check:   { field: "email",        message: "Email phải là chữ thường." },
  contact_email_format_check:  { field: "email",        message: "Email không hợp lệ." },
  contact_web_format_check:    { field: "website",      message: "URL không hợp lệ (ví dụ: https://example.com)." },
  contact_country_code_check:  { field: "country_code", message: "Mã quốc gia phải là 2 chữ cái in hoa (VD: VN, US)." },
  contact_zip_check:           { field: "zip",          message: "Mã bưu chính không hợp lệ." },
};

// --- Chuẩn hoá lỗi từ Axios/BE -> {code, message, field?}
function getAppError(err) {
  const res = err?.response;
  const data = res?.data;

  // AppError chuẩn: { code, message, field? }
  if (data && typeof data === "object") {
    return {
      code: String(data.code || data.sqlstate || data.error_code || ""),
      message: data.message || data.error || data.detail || data.reason || "",
      field: data.field || data.path,
      http: res?.status ?? 0,
      raw: data,
    };
  }

  if (typeof data === "string") {
    return { code: "", message: data, field: undefined, http: res?.status ?? 0, raw: data };
  }

  const fallback = err?.message || (typeof data !== "undefined" ? JSON.stringify(data) : "Unknown error");
  return { code: "", message: fallback, field: undefined, http: res?.status ?? 0, raw: data };
}

export default function ContactCreatePage() {
  const [metadata, setMetadata] = useState(null);
  const [companies, setCompanies] = useState([]);
  const [loadingContact, setLoadingContact] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [localContactId, setLocalContactId] = useState(null);
  const [saving, setSaving] = useState(false);

  // GIỮ state khi re-render
  const form = useForm({ shouldUnregister: false });

  const [searchParams] = useSearchParams();
  const contactId = searchParams.get("id") || localContactId;
  const token = localStorage.getItem("authToken");

  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get("/contact/metadata");
      setMetadata(res.data);
    } catch (err) {
      const e = getAppError(err);
      console.error("❌ Lỗi load metadata:", e.message, e.raw || "");
    }
  }, []);

  const fetchCompanies = useCallback(async () => {
    try {
      const res = await api.get("/contact/list", {
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
    async (id = contactId) => {
      if (!id) {
        setIsEditing(true);
        form.reset({ is_company: false });
        return;
      }
      setLoadingContact(true);
      try {
        const res = await api.get(`/contact/${id}`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const dto = res.data || {};
        const tagsArray =
          typeof dto.tags_cached === "string"
            ? dto.tags_cached.split(",").map((s) => s.trim()).filter(Boolean)
            : [];
        form.reset({ ...dto, tags: tagsArray });
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

  const normOrNull = (v) => {
    if (typeof v !== "string") return v ?? null;
    const s = v.trim();
    return s === "" ? null : s;
  };

  const onSubmit = async (data) => {
    const payload = {
      is_company: !!data.is_company,
      parent_id: data.parent_id || null,
      name: normOrNull(data.name),
      display_name: normOrNull(data.display_name),
      email: normOrNull(data.email),
      phone: data.phone ?? null,        // giữ raw, DB CHECK validate
      mobile: data.mobile ?? null,      // giữ raw
      website: normOrNull(data.website),
      street: normOrNull(data.street),
      street2: normOrNull(data.street2),
      city: normOrNull(data.city),
      state: normOrNull(data.state),
      zip: normOrNull(data.zip),
      country_code: normOrNull(data.country_code),
      notes: normOrNull(data.notes),
      tags: Array.isArray(data.tags) ? data.tags : undefined,
      idempotency_key: normOrNull(data.idempotency_key) || undefined,
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
        const res = await api.post(`/contact/create`, payload, {
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
      // KHÔNG reset/refetch — giữ dữ liệu người dùng
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
          field = map.field;
          message = map.message;
        }
      }

      if (field) {
        form.setError(field, { type: "server", message });
        form.setValue(field, form.getValues(field) ?? "");
        form.setFocus(field);
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
                    fields={metadata?.form?.fields || []}
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
}
