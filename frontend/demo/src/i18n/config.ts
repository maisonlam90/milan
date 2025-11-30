// Import Dependencies
import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import LanguageDetector from "i18next-browser-languagedetector";

// Local Imports
import { type LocaleCode, supportedLanguages } from "./langs";

// ----------------------------------------------------------------------

export const defaultLang: LocaleCode = "vi";
export const fallbackLang: LocaleCode = "en";

// Check URL parameter first, then localStorage, then default
const getInitialLanguage = (): LocaleCode => {
  // Check URL parameter ?lang=vi
  if (typeof window !== "undefined") {
    const urlParams = new URLSearchParams(window.location.search);
    const langParam = urlParams.get("lang") as LocaleCode;
    if (langParam && supportedLanguages.includes(langParam)) {
      localStorage.setItem("i18nextLng", langParam);
      return langParam;
    }
    
    // Check localStorage
    const storedLang = localStorage.getItem("i18nextLng") as LocaleCode;
    if (storedLang && supportedLanguages.includes(storedLang)) {
      return storedLang;
    }
  }
  
  return defaultLang;
};

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    detection: {
      order: ["localStorage", "navigator"],
      lookupLocalStorage: "i18nextLng",
      lookupSessionStorage: "i18nextLng",
    },
    fallbackLng: fallbackLang,
    lng: getInitialLanguage(),
    supportedLngs: supportedLanguages,
    ns: ["translations"],
    defaultNS: "translations",
    interpolation: {
      escapeValue: false,
    },
    lowerCaseLng: true,
    debug: false,
  });

i18n.languages = supportedLanguages;

export default i18n;
