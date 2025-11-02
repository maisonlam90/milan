// Form Tạo Mới Trường Học - Load metadata từ API /school/metadata
import { useEffect, useState, useCallback } from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useSearchParams } from "react-router-dom";
import axios, { AxiosError } from "axios";

import { Page } from "@/components/shared/Page";
import { Card, Button } from "@/components/ui";
import DynamicForm from "@/components/shared/DynamicForm";
import type { DynamicFieldConfig } from "@/components/shared/DynamicForm";
import { JWT_HOST_API } from "@/configs/auth";

const api = axios.create({ baseURL: JWT_HOST_API });

interface Metadata {
  form?: {
    fields?: unknown;
  };
}

type SchoolFormValues = Record<string, any>;

function isDynamicFieldConfig(x: any): x is DynamicFieldConfig {
  return (
    x &&
    typeof x === "object" &&
    typeof x.name === "string" &&
    typeof x.label === "string"
  );
}

// Convert metadata fields → DynamicForm fields
function toDynamicFields(fields: unknown): DynamicFieldConfig[] {
  if (!Array.isArray(fields)) return [];
  return fields.filter(isDynamicFieldConfig);
}

export default function SchoolCreatePage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const schoolId = searchParams.get("id");
  const [metadata, setMetadata] = useState<Metadata | null>(null);
  const form = useForm<SchoolFormValues>();

  // 1️⃣ Load metadata từ API /school/metadata (load từ manifest.json ngoài binary)
  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get<Metadata>("/school/metadata");
      setMetadata(res.data);
      console.log("✅ Metadata loaded:", res.data);
    } catch (e) {
      console.error("❌ Lỗi load metadata:", e);
    }
  }, []);

  useEffect(() => {
    fetchMetadata();
  }, [fetchMetadata]);

  // 2️⃣ Convert metadata fields → DynamicForm fields
  const fields: DynamicFieldConfig[] = metadata?.form?.fields
    ? toDynamicFields(metadata.form.fields)
    : [];

  // 3️⃣ Submit form → Gửi lên API /school/create
  const onSubmit = async (data: SchoolFormValues) => {
    try {
      const token = localStorage.getItem("authToken");
      const headers = token ? { Authorization: `Bearer ${token}` } : {};

      if (schoolId) {
        // Update mode (nếu có id)
        await api.post(`/school/${schoolId}/update`, data, { headers });
        alert("✅ Cập nhật thành công!");
      } else {
        // Create mode
        const res = await api.post("/school/create", data, { headers });
        console.log("✅ Tạo thành công:", res.data);
        alert("✅ Tạo trường học thành công!");
      }

      navigate("/dashboards/school/school-list");
    } catch (err: any) {
      console.error("❌ Lỗi:", err);
      const errorMsg = err.response?.data?.message || err.message || "Lỗi không xác định";
      alert(`❌ Lỗi: ${errorMsg}`);
    }
  };

  return (
    <Page title={schoolId ? "Cập nhật Trường Học" : "Tạo Mới Trường Học"}>
      <div className="w-full px-(--margin-x) pb-8">
        <div className="py-5">
          <h2 className="text-xl font-medium">
            🏫 {schoolId ? "Cập nhật" : "Tạo Mới"} Trường Học
          </h2>
        </div>

        <Card className="p-6">
          {fields.length > 0 ? (
            // 4️⃣ Render form động từ metadata (từ manifest.json)
            <DynamicForm
              form={form}
              fields={fields}
              onSubmit={onSubmit}
            />
          ) : (
            <div className="text-center py-8">
              <p>Đang tải form...</p>
            </div>
          )}
        </Card>
      </div>
    </Page>
  );
}

