// Import Dependencies
import { useState, useCallback, ReactNode, useLayoutEffect, useEffect } from "react";
import dayjs from "dayjs";

// Local Imports
import i18n, { defaultLang } from "@/i18n/config";
import { Dir, LocaleCode, locales } from "@/i18n/langs";
import { LocaleContext } from "./context";

// ----------------------------------------------------------------------

// Set the initial language from URL param, then localStorage, then default
const getInitialLang = (): LocaleCode => {
  if (typeof window !== "undefined") {
    // Check URL parameter first
    const urlParams = new URLSearchParams(window.location.search);
    const langParam = urlParams.get("lang") as LocaleCode;
    if (langParam && Object.keys(locales).includes(langParam)) {
      return langParam;
    }
    
    // Check localStorage
    const stored = localStorage.getItem("i18nextLng") as LocaleCode;
    if (stored && Object.keys(locales).includes(stored)) {
      return stored;
    }
  }
  return defaultLang;
};

const initialLang: LocaleCode = getInitialLang();

const initialDir = i18n.dir(initialLang);

export function LocaleProvider({ children }: { children: ReactNode }) {
  const [locale, setLocale] = useState<LocaleCode>(initialLang);
  const [direction, setDirection] = useState<Dir>(initialDir as Dir);

  // Function to update the locale dynamically
  const updateLocale = useCallback(async (newLocale: LocaleCode) => {
    try {
      // 1. Update URL FIRST so axios interceptor can read it immediately
      if (typeof window !== "undefined") {
        const url = new URL(window.location.href);
        url.searchParams.set("lang", newLocale);
        window.history.replaceState({}, "", url);
      }
      
      // 2. Save to localStorage immediately
      localStorage.setItem("i18nextLng", newLocale);
      
      // 3. Dynamically load the locale resources first
      if (locales[newLocale]) {
        await locales[newLocale].dayjs();
        dayjs.locale(newLocale);
        const i18nResources = await locales[newLocale].i18n();
        i18n.addResourceBundle(newLocale, "translations", i18nResources);
      }
      
      // 4. Update i18n language FIRST (this triggers re-render of components using useTranslation)
      // This must be called before setLocale to ensure i18n.language is updated
      await i18n.changeLanguage(newLocale);
      
      // 5. Update state (triggers re-render of Provider and components using locale context)
      setLocale(newLocale);
    } catch (error) {
      console.error("Failed to update locale:", error);
      // Fallback: still update basic state
      if (typeof window !== "undefined") {
        const url = new URL(window.location.href);
        url.searchParams.set("lang", newLocale);
        window.history.replaceState({}, "", url);
      }
      localStorage.setItem("i18nextLng", newLocale);
      // Try to update i18n even if resource loading failed
      try {
        await i18n.changeLanguage(newLocale);
      } catch (e) {
        console.error("Failed to change i18n language:", e);
      }
      setLocale(newLocale);
    }
  }, []);

  // Load the initial locale resources
  useLayoutEffect(() => {
    if (locale) {
      updateLocale(locale);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Listen to URL changes and update locale when ?lang= parameter changes
  // Also preserve ?lang= parameter when navigating to new pages
  useEffect(() => {
    if (typeof window === "undefined") return;
    
    let lastUrl = window.location.href;
    let isUpdatingUrl = false; // Flag to prevent infinite loop
    
    // Save original functions before overriding
    const originalPushState = window.history.pushState;
    const originalReplaceState = window.history.replaceState;
    
    const checkUrlLang = () => {
      // Skip if we're currently updating the URL to avoid infinite loop
      if (isUpdatingUrl) return;
      
      const urlParams = new URLSearchParams(window.location.search);
      const langParam = urlParams.get("lang") as LocaleCode;
      
      // If URL has lang param and it's different from current locale, update locale
      if (langParam && Object.keys(locales).includes(langParam) && langParam !== locale) {
        updateLocale(langParam);
      }
      // If URL doesn't have lang param, preserve current locale in URL
      else if (!langParam && locale) {
        isUpdatingUrl = true;
        const url = new URL(window.location.href);
        url.searchParams.set("lang", locale);
        // Use original replaceState to avoid triggering our overridden version
        originalReplaceState.call(window.history, {}, "", url);
        // Reset flag after a short delay
        setTimeout(() => {
          isUpdatingUrl = false;
        }, 0);
      }
    };

    // Check immediately
    checkUrlLang();

    // Listen to popstate events (back/forward navigation)
    window.addEventListener("popstate", checkUrlLang);
    
    // Override pushState and replaceState to detect programmatic navigation
    window.history.pushState = function(...args) {
      originalPushState.apply(window.history, args);
      setTimeout(checkUrlLang, 0);
    };
    
    window.history.replaceState = function(...args) {
      originalReplaceState.apply(window.history, args);
      setTimeout(checkUrlLang, 0);
    };
    
    // Fallback: Poll URL changes (less frequent to reduce overhead)
    const interval = setInterval(() => {
      if (window.location.href !== lastUrl) {
        lastUrl = window.location.href;
        checkUrlLang();
      }
    }, 500);

    return () => {
      window.removeEventListener("popstate", checkUrlLang);
      window.history.pushState = originalPushState;
      window.history.replaceState = originalReplaceState;
      clearInterval(interval);
    };
  }, [locale, updateLocale]);

  // Update text direction based on the current locale
  useLayoutEffect(() => {
    const newDir = i18n.dir(locale);
    if (newDir !== direction) {
      setDirection(newDir);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [locale]);

  useLayoutEffect(() => {
    document.documentElement.dir = direction;
  }, [direction]);

  return (
    <LocaleContext
      value={{
        locale,
        updateLocale,
        direction,
        setDirection,
        isRtl: direction === "rtl",
      }}
    >
      {children}
    </LocaleContext>
  );
}
