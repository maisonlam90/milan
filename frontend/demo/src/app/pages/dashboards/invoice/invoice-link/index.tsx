// Import Dependencies
import { useState, useEffect, useCallback } from "react";
import { useForm } from "react-hook-form";
import * as yup from "yup";
import { yupResolver } from "@hookform/resolvers/yup";
import { useNavigate } from "react-router-dom";
import axiosInstance from "@/utils/axios";

// Local Imports
import { Page } from "@/components/shared/Page";
import { Input, Button, Card } from "@/components/ui";

// ----------------------------------------------------------------------

// Types
interface UserInfo {
  id: string;
  email?: string;
  name?: string;
  username?: string;
  [k: string]: unknown;
}

interface MeinvoiceLoginFormData {
  username: string;
  password: string;
  taxcode: string; // Mã số thuế
  appid: string; // AppID được MISA cung cấp
  api_url: string;
}

// Validation Schema
const schema = yup.object({
  username: yup.string().required("Tên đăng nhập là bắt buộc"),
  password: yup.string().required("Mật khẩu là bắt buộc"),
  taxcode: yup.string().required("Mã số thuế là bắt buộc"),
  appid: yup.string().required("AppID là bắt buộc"),
  api_url: yup.string().url("URL không hợp lệ").required("API URL là bắt buộc"),
}) as yup.ObjectSchema<MeinvoiceLoginFormData>;

// ----------------------------------------------------------------------

export default function InvoiceLink() {
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [userInfo, setUserInfo] = useState<UserInfo | null>(null);
  const [isLoadingUser, setIsLoadingUser] = useState(true);

  const form = useForm<MeinvoiceLoginFormData>({
    resolver: yupResolver(schema),
    defaultValues: {
      username: "",
      password: "",
      taxcode: "",
      appid: "",
      api_url: "https://testapi.meinvoice.vn", // Default test API URL
    },
  });

  const { register, handleSubmit, formState: { errors }, setValue } = form;

  // Fetch current user info
  const fetchUserInfo = useCallback(async () => {
    try {
      setIsLoadingUser(true);
      // Tạo authHeader bên trong để tránh dependency
      const token = (typeof window !== "undefined" && localStorage.getItem("authToken")) || "";
      const authHeader = token ? { Authorization: `Bearer ${token}` } : undefined;
      
      const res = await axiosInstance.get<UserInfo>("/user/profile", {
        headers: authHeader,
      });
      setUserInfo(res.data);
      
      // Pre-fill username with user email if available (chỉ set một lần)
      if (res.data.email) {
        setValue("username", res.data.email, { shouldDirty: false });
      } else if (res.data.username) {
        setValue("username", res.data.username, { shouldDirty: false });
      }
    } catch (err: any) {
      console.error("❌ Lỗi load user info:", err);
      setError("Không thể tải thông tin người dùng");
    } finally {
      setIsLoadingUser(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []); // Empty deps - chỉ chạy một lần khi mount

  useEffect(() => {
    fetchUserInfo();
  }, [fetchUserInfo]);

  // Handle form submission - Login to Meinvoice
  const onSubmit = async (data: MeinvoiceLoginFormData) => {
    setIsSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      // Call API to login to Meinvoice
      const token = (typeof window !== "undefined" && localStorage.getItem("authToken")) || "";
      const authHeader = token ? { Authorization: `Bearer ${token}` } : undefined;
      
      const response = await axiosInstance.post(
        "/invoice-link/login",
        {
          username: data.username,
          password: data.password,
          taxcode: data.taxcode,
          appid: data.appid,
          api_url: data.api_url,
        },
        {
          headers: authHeader,
        }
      );

      if (response.data?.success) {
        setSuccess(response.data.message || "Đăng nhập thành công! Bạn có thể gửi hóa đơn đến Meinvoice.");
        
        // Redirect to invoice list after 2 seconds
        setTimeout(() => {
          navigate("/dashboards/invoice/invoice-list");
        }, 2000);
      } else {
        setError("Đăng nhập thất bại");
      }
    } catch (error: any) {
      console.error("Error logging in to Meinvoice:", error);
      const errorMessage = error?.response?.data?.message || error?.message || "Có lỗi xảy ra khi đăng nhập";
      setError(errorMessage);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Page title="Kết nối Meinvoice">
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-2">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              Kết nối với phần mềm hóa đơn điện tử Meinvoice
            </h2>
          </div>
        </div>

        <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
          <div className="col-span-12 lg:col-span-8">
            <Card className="p-4 sm:px-5">
              <h3 className="text-base font-medium text-gray-800 dark:text-dark-100 mb-5">
                Thông tin đăng nhập Meinvoice
              </h3>

              {/* User Info Display */}
              {isLoadingUser ? (
                <div className="mb-5 text-sm text-gray-500">Đang tải thông tin người dùng...</div>
              ) : userInfo ? (
                <div className="mb-5 rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-dark-500 dark:bg-dark-800">
                  <h4 className="text-sm font-medium text-gray-700 dark:text-dark-200 mb-2">
                    Thông tin tài khoản hiện tại:
                  </h4>
                  <div className="space-y-1 text-sm text-gray-600 dark:text-dark-300">
                    {userInfo.email && (
                      <div>
                        <span className="font-medium">Email:</span> {userInfo.email}
                      </div>
                    )}
                    {userInfo.name && (
                      <div>
                        <span className="font-medium">Tên:</span> {userInfo.name}
                      </div>
                    )}
                    {userInfo.username && (
                      <div>
                        <span className="font-medium">Username:</span> {userInfo.username}
                      </div>
                    )}
                    {userInfo.id && (
                      <div>
                        <span className="font-medium">ID:</span> {userInfo.id}
                      </div>
                    )}
                  </div>
                </div>
              ) : null}

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
                  <Input
                    label="Tên đăng nhập Meinvoice"
                    {...register("username")}
                    error={errors.username?.message}
                    placeholder="Nhập tên đăng nhập Meinvoice"
                    required
                  />

                  <Input
                    type="password"
                    label="Mật khẩu Meinvoice"
                    {...register("password")}
                    error={errors.password?.message}
                    placeholder="Nhập mật khẩu Meinvoice"
                    required
                  />

                  <Input
                    label="Mã số thuế"
                    {...register("taxcode")}
                    error={errors.taxcode?.message}
                    placeholder="Nhập mã số thuế"
                    required
                  />

                  <div>
                    <Input
                      label="AppID"
                      {...register("appid")}
                      error={errors.appid?.message}
                      placeholder="Nhập AppID được MISA cung cấp"
                      required
                    />
                    <p className="mt-1 text-xs text-gray-500 dark:text-dark-400">
                      AppID là chuỗi ký tự được MISA cung cấp để xác thực ứng dụng
                    </p>
                  </div>

                  <div>
                    <Input
                      label="API URL"
                      {...register("api_url")}
                      error={errors.api_url?.message}
                      placeholder="https://testapi.meinvoice.vn"
                      required
                    />
                    <p className="mt-1 text-xs text-gray-500 dark:text-dark-400">
                      URL endpoint của Meinvoice API (ví dụ: https://testapi.meinvoice.vn hoặc https://api.meinvoice.vn)
                    </p>
                  </div>

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
                      disabled={isSubmitting}
                    >
                      {isSubmitting ? "Đang đăng nhập..." : "Đăng nhập"}
                    </Button>
                  </div>
                </div>
              </form>
            </Card>
          </div>

          <div className="col-span-12 lg:col-span-4 space-y-4 sm:space-y-5 lg:space-y-6">
            <Card className="p-4 sm:px-5">
              <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                Hướng dẫn
              </h6>
              <div className="mt-3 space-y-2 text-sm text-gray-600 dark:text-dark-300">
                <p>
                  1. Nhập thông tin đăng nhập Meinvoice của bạn
                </p>
                <p>
                  2. Mã số thuế và AppID được cung cấp bởi MISA
                </p>
                <p>
                  3. Token có thời hạn 15 ngày, hệ thống sẽ tự động refresh khi cần
                </p>
                <p>
                  4. Sau khi đăng nhập thành công, bạn có thể gửi hóa đơn đến Meinvoice
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
                  • AppID và Token sẽ được mã hóa và lưu trữ an toàn
                </p>
                <p>
                  • Token có thời hạn 15 ngày, hệ thống sẽ tự động làm mới khi hết hạn
                </p>
                <p>
                  • Bạn có thể cập nhật thông tin đăng nhập bất cứ lúc nào
                </p>
              </div>
            </Card>
          </div>
        </div>
      </div>
    </Page>
  );
}

