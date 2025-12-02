// Import Dependencies
import { useState, useEffect, useCallback } from "react";
import { useForm } from "react-hook-form";
import * as yup from "yup";
import { yupResolver } from "@hookform/resolvers/yup";
import { useNavigate } from "react-router-dom";
import axiosInstance from "@/utils/axios";

// Local Imports
import { Page } from "@/components/shared/Page";
import { Input, Button, Card, Select, Checkbox } from "@/components/ui";

// ----------------------------------------------------------------------

// Types
interface ProviderInfo {
  code: string;
  name: string;
  description?: string;
}

interface FormField {
  name: string;
  label: string;
  field_type: string;
  required: boolean;
  placeholder?: string;
  description?: string;
}

interface ProviderFormFieldsResponse {
  provider: string;
  fields: FormField[];
}

interface LinkProviderFormData {
  provider: string;
  is_default?: boolean;
  [key: string]: string | boolean | undefined; // Dynamic fields based on provider
}

// ----------------------------------------------------------------------

export default function InvoiceLink() {
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [providers, setProviders] = useState<ProviderInfo[]>([]);
  const [selectedProvider, setSelectedProvider] = useState<string>("");
  const [formFields, setFormFields] = useState<FormField[]>([]);
  const [isLoadingProviders, setIsLoadingProviders] = useState(true);
  const [isLoadingFields, setIsLoadingFields] = useState(false);
  const [providerCredentials, setProviderCredentials] = useState<any>(null);

  // Build dynamic validation schema based on form fields
  const buildSchema = useCallback((fields: FormField[]) => {
    const schemaObject: Record<string, any> = {
      provider: yup.string().required("Vui lòng chọn nhà cung cấp"),
    };

    fields.forEach((field) => {
      if (field.required) {
        schemaObject[field.name] = yup.string().required(`${field.label} là bắt buộc`);
      } else {
        schemaObject[field.name] = yup.string();
      }
    });

    return yup.object(schemaObject);
  }, []);

  const [schema, setSchema] = useState<yup.AnyObjectSchema>(() => 
    yup.object({ provider: yup.string().required() })
  );

  const form = useForm<LinkProviderFormData>({
    resolver: yupResolver(schema) as any,
    defaultValues: {
      provider: "",
    },
  });

  const { register, handleSubmit, formState: { errors }, setValue, watch, reset } = form;

  // Watch provider change
  const watchedProvider = watch("provider");

  // Fetch providers list
  const fetchProviders = useCallback(async () => {
    try {
      setIsLoadingProviders(true);
      const token = (typeof window !== "undefined" && localStorage.getItem("authToken")) || "";
      const authHeader = token ? { Authorization: `Bearer ${token}` } : undefined;

      const response = await axiosInstance.get<{ items: ProviderInfo[] }>(
        "/invoice-link/providers",
        {
          headers: authHeader,
        }
      );

      setProviders(response.data.items || []);
    } catch (err: any) {
      console.error("❌ Lỗi load providers:", err);
      setError("Không thể tải danh sách nhà cung cấp");
    } finally {
      setIsLoadingProviders(false);
    }
  }, []);

  // Fetch form fields for selected provider
  const fetchFormFields = useCallback(async (providerCode: string) => {
    if (!providerCode) {
      setFormFields([]);
      return;
    }

    try {
      setIsLoadingFields(true);
      const token = (typeof window !== "undefined" && localStorage.getItem("authToken")) || "";
      const authHeader = token ? { Authorization: `Bearer ${token}` } : undefined;

      const response = await axiosInstance.get<ProviderFormFieldsResponse>(
        `/invoice-link/providers/${providerCode}/form-fields`,
        {
          headers: authHeader,
        }
      );

      setFormFields(response.data.fields || []);
      
      // Build new schema with fields
      const newSchema = buildSchema(response.data.fields);
      setSchema(newSchema);
      
      // Update form resolver with new schema
      form.clearErrors();
      
      // Reset form with new default values
      const newDefaults: LinkProviderFormData = {
        provider: providerCode,
      };
      response.data.fields.forEach((field) => {
        newDefaults[field.name] = "";
      });
      reset(newDefaults, { keepDefaultValues: false });
    } catch (err: any) {
      console.error("❌ Lỗi load form fields:", err);
      setError("Không thể tải form đăng nhập cho nhà cung cấp này");
      setFormFields([]);
    } finally {
      setIsLoadingFields(false);
    }
  }, [buildSchema, reset]);

  // Fetch provider credentials để hiển thị thông tin nhà cung cấp mặc định
  const fetchProviderCredentials = useCallback(async () => {
    try {
      const token = (typeof window !== "undefined" && localStorage.getItem("authToken")) || "";
      const authHeader = token ? { Authorization: `Bearer ${token}` } : undefined;

      const res = await axiosInstance.get('/invoice-link/providers/credentials', {
        headers: authHeader,
      });
      
      // Lấy credentials mặc định của Viettel
      const defaultCred = res.data?.items?.find(
        (cred: any) => cred.is_default && cred.is_active
      );
      
      if (defaultCred) {
        setProviderCredentials(defaultCred);
      }
    } catch (err) {
      console.error("❌ Lỗi load provider credentials:", err);
    }
  }, []);

  useEffect(() => {
    fetchProviders();
    fetchProviderCredentials();
  }, [fetchProviders, fetchProviderCredentials]);

  // When provider changes, fetch form fields
  useEffect(() => {
    if (watchedProvider && watchedProvider !== selectedProvider) {
      setSelectedProvider(watchedProvider);
      fetchFormFields(watchedProvider);
    }
  }, [watchedProvider, selectedProvider, fetchFormFields]);

  // Handle form submission - Link provider
  const onSubmit = async (data: LinkProviderFormData) => {
    setIsSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const token = (typeof window !== "undefined" && localStorage.getItem("authToken")) || "";
      const authHeader = token ? { Authorization: `Bearer ${token}` } : undefined;

      // Build credentials object from form fields (exclude is_default)
      const credentials: Record<string, string> = {};
      formFields.forEach((field) => {
        if (data[field.name] && typeof data[field.name] === 'string') {
          credentials[field.name] = data[field.name] as string;
        }
      });

      const response = await axiosInstance.post(
        "/invoice-link/providers/link",
        {
          provider: data.provider,
          credentials: credentials,
          is_default: data.is_default || false,
        },
        {
          headers: authHeader,
        }
      );

      if (response.data?.success) {
        setSuccess(response.data.message || "Liên kết thành công!");
        
        // Redirect to invoice list after 2 seconds
        setTimeout(() => {
          navigate("/dashboards/invoice/invoice-list");
        }, 2000);
      } else {
        setError("Liên kết thất bại");
      }
    } catch (error: any) {
      console.error("Error linking provider:", error);
      const errorMessage = error?.response?.data?.message || error?.message || "Có lỗi xảy ra khi liên kết";
      setError(errorMessage);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Page title="Kết nối Hóa đơn Điện tử">
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-2">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              Kết nối với phần mềm hóa đơn điện tử
            </h2>
          </div>
        </div>

        <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
          <div className="col-span-12 lg:col-span-8">
            <Card className="p-4 sm:px-5">
              <h3 className="text-base font-medium text-gray-800 dark:text-dark-100 mb-5">
                Thông tin đăng nhập
              </h3>

              {/* Error Message */}
              {error && (
                <div className="mb-4 rounded-lg border border-red-300 bg-red-50 p-4 text-red-800 dark:border-red-700 dark:bg-red-900/20 dark:text-red-400">
                  <div className="flex items-center justify-between">
                    <span>{error}</span>
                    <button
                      type="button"
                      onClick={() => setError(null)}
                      className="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-200"
                    >
                      ×
                    </button>
                  </div>
                </div>
              )}

              {/* Success Message */}
              {success && (
                <div className="mb-4 rounded-lg border border-green-300 bg-green-50 p-4 text-green-800 dark:border-green-700 dark:bg-green-900/20 dark:text-green-400">
                  <div className="flex items-center justify-between">
                    <span>{success}</span>
                    <button
                      type="button"
                      onClick={() => setSuccess(null)}
                      className="text-green-600 hover:text-green-800 dark:text-green-400 dark:hover:text-green-200"
                    >
                      ×
                    </button>
                  </div>
                </div>
              )}

              <form autoComplete="off" onSubmit={handleSubmit(onSubmit)}>
                <div className="space-y-5">
                  {/* Provider Selection */}
                  <div>
                    <Select
                      label="Chọn nhà cung cấp"
                      name="provider"
                      error={errors.provider?.message}
                      value={watchedProvider}
                      onChange={(e) => {
                        setValue("provider", e.target.value, { shouldValidate: true });
                      }}
                      disabled={isLoadingProviders || isSubmitting}
                      required
                    >
                      <option value="">-- Chọn nhà cung cấp --</option>
                      {providers.map((provider) => (
                        <option key={provider.code} value={provider.code}>
                          {provider.name}
                        </option>
                      ))}
                    </Select>
                    {isLoadingProviders && (
                      <p className="mt-1 text-xs text-gray-500 dark:text-dark-400">
                        Đang tải danh sách nhà cung cấp...
                      </p>
                    )}
                  </div>

                  {/* Dynamic Form Fields */}
                  {isLoadingFields && watchedProvider && (
                    <div className="text-sm text-gray-500">Đang tải form đăng nhập...</div>
                  )}

                  {!isLoadingFields && formFields.length > 0 && (
                    <>
                      {formFields.map((field) => (
                        <div key={field.name}>
                          <Input
                            type={field.field_type === "password" ? "password" : "text"}
                            label={field.label}
                            {...register(field.name)}
                            error={errors[field.name]?.message}
                            placeholder={field.placeholder || `Nhập ${field.label.toLowerCase()}`}
                            required={field.required}
                          />
                          {field.description && (
                            <p className="mt-1 text-xs text-gray-500 dark:text-dark-400">
                              {field.description}
                            </p>
                          )}
                        </div>
                      ))}
                    </>
                  )}

                  {!isLoadingFields && !watchedProvider && (
                    <div className="rounded-lg border border-gray-200 bg-gray-50 p-4 text-sm text-gray-600 dark:border-dark-500 dark:bg-dark-800 dark:text-dark-300">
                      Vui lòng chọn nhà cung cấp để hiển thị form đăng nhập
                    </div>
                  )}

                  {/* Default Provider Checkbox */}
                  {!isLoadingFields && watchedProvider && formFields.length > 0 && (
                    <div className="rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-dark-500 dark:bg-dark-800">
                      <Checkbox
                        {...register("is_default")}
                        label="Đặt làm nhà cung cấp mặc định"
                      />
                      <p className="mt-1 text-xs text-gray-500 dark:text-dark-400">
                        Khi tích chọn, hệ thống sẽ tự động xuất hóa đơn vào nhà cung cấp này
                      </p>
                    </div>
                  )}

                  <div className="flex gap-2 pt-4">
                    <Button
                      type="button"
                      variant="outlined"
                      onClick={() => navigate("/dashboards/invoice/invoice-list")}
                      disabled={isSubmitting}
                    >
                      Hủy
                    </Button>
                    <Button
                      type="submit"
                      color="primary"
                      disabled={isSubmitting || !watchedProvider || formFields.length === 0}
                    >
                      {isSubmitting ? "Đang liên kết..." : "Liên kết"}
                    </Button>
                  </div>
                </div>
              </form>
            </Card>
          </div>

          <div className="col-span-12 lg:col-span-4 space-y-4 sm:space-y-5 lg:space-y-6">
            {/* Provider Credentials Info Card */}
            {providerCredentials && (
              <Card className="p-4 sm:px-5 border-l-4 border-primary-500 bg-gradient-to-r from-primary-50 to-transparent dark:from-primary-900/10">
                <h6 className="text-base font-medium text-gray-800 dark:text-dark-100 flex items-center gap-2">
                  <svg className="w-5 h-5 text-primary-600 dark:text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                  Nhà cung cấp mặc định
                </h6>
                <div className="mt-3 space-y-2 text-sm">
                  <div className="flex items-start justify-between">
                    <span className="text-gray-600 dark:text-dark-300 font-medium">Provider:</span>
                    <span className="text-gray-900 dark:text-dark-50 font-semibold capitalize">{providerCredentials.provider}</span>
                  </div>
                  <div className="flex items-start justify-between">
                    <span className="text-gray-600 dark:text-dark-300 font-medium">Mẫu hóa đơn:</span>
                    <span className="text-gray-900 dark:text-dark-50 font-mono">{providerCredentials.template_code || 'N/A'}</span>
                  </div>
                  <div className="flex items-start justify-between">
                    <span className="text-gray-600 dark:text-dark-300 font-medium">Ký hiệu:</span>
                    <span className="text-gray-900 dark:text-dark-50 font-mono">{providerCredentials.invoice_series || 'N/A'}</span>
                  </div>
                  <div className="flex items-start justify-between pt-2 border-t border-gray-200 dark:border-dark-500">
                    <span className="text-gray-600 dark:text-dark-300 font-medium">Trạng thái:</span>
                    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                      providerCredentials.is_active 
                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400' 
                        : 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
                    }`}>
                      <span className={`w-1.5 h-1.5 rounded-full mr-1 ${
                        providerCredentials.is_active ? 'bg-green-500' : 'bg-gray-500'
                      }`}></span>
                      {providerCredentials.is_active ? 'Hoạt động' : 'Không hoạt động'}
                    </span>
                  </div>
                </div>
              </Card>
            )}

            <Card className="p-4 sm:px-5">
              <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                Hướng dẫn
              </h6>
              <div className="mt-3 space-y-2 text-sm text-gray-600 dark:text-dark-300">
                <p>
                  1. Chọn nhà cung cấp hóa đơn điện tử từ dropdown
                </p>
                <p>
                  2. Điền thông tin đăng nhập theo form hiển thị
                </p>
                <p>
                  3. Hệ thống sẽ tự động kiểm tra và lưu thông tin đăng nhập
                </p>
                <p>
                  4. Sau khi liên kết thành công, bạn có thể gửi hóa đơn đến nhà cung cấp
                </p>
              </div>
            </Card>

            <Card className="p-4 sm:px-5">
              <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                Lưu ý
              </h6>
              <div className="mt-3 space-y-2 text-sm text-gray-600 dark:text-dark-300">
                <p>
                  • Mật khẩu sẽ không được lưu trữ trên trình duyệt
                </p>
                <p>
                  • Thông tin đăng nhập sẽ được mã hóa và lưu trữ an toàn
                </p>
                <p>
                  • Token sẽ được tự động làm mới khi hết hạn
                </p>
                <p>
                  • Bạn có thể cập nhật thông tin đăng nhập bất cứ lúc nào
                </p>
              </div>
            </Card>

            {/* Provider Info */}
            {selectedProvider && providers.find(p => p.code === selectedProvider) && (
              <Card className="p-4 sm:px-5">
                <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Thông tin nhà cung cấp
                </h6>
                <div className="mt-3 space-y-2 text-sm text-gray-600 dark:text-dark-300">
                  <p>
                    <span className="font-medium">Tên:</span>{" "}
                    {providers.find(p => p.code === selectedProvider)?.name}
                  </p>
                  {providers.find(p => p.code === selectedProvider)?.description && (
                    <p>
                      <span className="font-medium">Mô tả:</span>{" "}
                      {providers.find(p => p.code === selectedProvider)?.description}
                    </p>
                  )}
                </div>
              </Card>
            )}
          </div>
        </div>
      </div>
    </Page>
  );
}
