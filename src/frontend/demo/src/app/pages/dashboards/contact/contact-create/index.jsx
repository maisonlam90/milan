import { useEffect, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { useSearchParams } from "react-router-dom"; // ✅ Thêm dòng này
import { Page } from "components/shared/Page";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Card, Button } from "components/ui";
import DynamicForm from "components/shared/DynamicForm";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function ContactCreatePage() {
  const [metadata, setMetadata] = useState(null);
  const [companies, setCompanies] = useState([]);
  const [loadingContact, setLoadingContact] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [localContactId, setLocalContactId] = useState(null);
  const [saving, setSaving] = useState(false);

  const form = useForm();
  const token = localStorage.getItem("authToken");
  const [searchParams] = useSearchParams(); // ✅ Dùng hook
  const contactId = searchParams.get("id") || localContactId;

  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get("/contact/metadata");
      setMetadata(res.data);
    } catch (err) {
      console.error("❌ Lỗi load metadata:", err);
    }
  }, []);

  const fetchCompanies = useCallback(async () => {
    try {
      const res = await api.get("/contact/list", {
        headers: { Authorization: `Bearer ${token}` },
        params: { is_company: true, limit: 200 },
      });
      const items = res.data?.items ?? [];
      setCompanies(items);
    } catch (err) {
      console.error("❌ Lỗi load danh sách công ty:", err);
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
            ? dto.tags_cached
                .split(",")
                .map((s) => s.trim())
                .filter(Boolean)
            : [];
        form.reset({ ...dto, tags: tagsArray });
        setIsEditing(false);
      } catch (err) {
        alert("❌ Lỗi load liên hệ: " + (err.response?.data || err.message));
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

  const onSubmit = async (data) => {
    const payload = {
      is_company: !!data.is_company,
      parent_id: data.parent_id || null,
      name: data.name?.trim(),
      display_name: data.display_name || null,
      email: data.email || null,
      phone: data.phone || null,
      mobile: data.mobile || null,
      website: data.website || null,
      street: data.street || null,
      street2: data.street2 || null,
      city: data.city || null,
      state: data.state || null,
      zip: data.zip || null,
      country_code: data.country_code || null,
      notes: data.notes || null,
      tags: Array.isArray(data.tags) ? data.tags : undefined,
      idempotency_key: data.idempotency_key || undefined,
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
      alert("❌ Lỗi lưu liên hệ: " + (err.response?.data || err.message));
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
      alert("❌ Lỗi xóa liên hệ: " + (err.response?.data || err.message));
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
