// Import Dependencies
import { useState, useCallback, ReactNode, useLayoutEffect } from "react";
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
      // Dynamically load the locale and update dependencies
      if (locales[newLocale]) {
        await locales[newLocale].dayjs();
        dayjs.locale(newLocale);
        const i18nResources = await locales[newLocale].i18n();
        i18n.addResourceBundle(newLocale, "translations", i18nResources);
      }
      // Update i18n language and save to localStorage
      await i18n.changeLanguage(newLocale);
      localStorage.setItem("i18nextLng", newLocale);
      setLocale(newLocale);
      
      // Update URL if needed (optional - add ?lang=vi to URL)
      const url = new URL(window.location.href);
      url.searchParams.set("lang", newLocale);
      window.history.replaceState({}, "", url);
    } catch (error) {
      console.error("Failed to update locale:", error);
      await i18n.changeLanguage(newLocale);
      localStorage.setItem("i18nextLng", newLocale);
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
