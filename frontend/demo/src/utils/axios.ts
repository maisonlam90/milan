import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from "axios";
import { JWT_HOST_API } from "@/configs/auth";
import i18n from "@/i18n/config";

const axiosInstance = axios.create({
  baseURL: JWT_HOST_API,
});

// Request interceptor: Add Accept-Language header based on current i18n language
axiosInstance.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // Priority: URL parameter > i18n.language > localStorage > default
    let currentLanguage = "vi";
    let source = "default";
    
    if (typeof window !== "undefined") {
      // Check URL parameter first (highest priority)
      const urlParams = new URLSearchParams(window.location.search);
      const langParam = urlParams.get("lang");
      if (langParam) {
        currentLanguage = langParam;
        source = "URL";
      } else {
        // Fallback to i18n language (always get fresh value)
        // Use i18n.language which is updated synchronously when changeLanguage is called
        currentLanguage = i18n.language || localStorage.getItem("i18nextLng") || "vi";
        source = "i18n";
      }
    } else {
      // Server-side fallback
      currentLanguage = i18n.language || "vi";
      source = "i18n";
    }
    
    // Add Accept-Language header (standard HTTP header, allowed by CORS)
    if (config.headers) {
      config.headers["Accept-Language"] = currentLanguage;
      // Debug: Log the header being sent (remove in production)
      if (process.env.NODE_ENV === "development") {
        console.log(`[i18n] Sending Accept-Language: ${currentLanguage} (from ${source})`);
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
