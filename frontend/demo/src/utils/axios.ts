import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from "axios";
import { JWT_HOST_API } from "@/configs/auth";
import i18n from "@/i18n/config";

const axiosInstance = axios.create({
  baseURL: JWT_HOST_API,
});

// Request interceptor: Add Accept-Language header based on current i18n language
axiosInstance.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // Get current language from i18n (always get fresh value)
    const currentLanguage = i18n.language || localStorage.getItem("i18nextLng") || "vi";
    
    // Add Accept-Language header (standard HTTP header, allowed by CORS)
    if (config.headers) {
      config.headers["Accept-Language"] = currentLanguage;
      // Debug: Log the header being sent (remove in production)
      if (process.env.NODE_ENV === "development") {
        console.log(`[i18n] Sending Accept-Language: ${currentLanguage}`);
      }
    }
    
    return config;
  },
  (error: AxiosError) => {
    return Promise.reject(error);
  }
);

// Response interceptor
axiosInstance.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error: AxiosError) =>
    Promise.reject(error.response?.data || "Something went wrong")
);

export default axiosInstance;
