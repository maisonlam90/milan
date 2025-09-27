// src/components/datagrid/AgGridView.tsx
"use client";

import { useEffect, useMemo, useState, type CSSProperties } from "react";
import { AgGridReact } from "ag-grid-react";
import type { AgGridReactProps } from "ag-grid-react";
import {
  ModuleRegistry,
  ClientSideRowModelModule,
  TextFilterModule,
  NumberFilterModule,
  RowDragModule,
  RowSelectionModule,
  ValidationModule,
  ColDef,
  type RowSelectionOptions,
  // Base functional themes
  themeQuartz,
  themeBalham,
  themeMaterial,
  themeAlpine,
  // Color schemes (theo demo AG Grid)
  colorSchemeLight,
  colorSchemeLightCold,
  colorSchemeLightWarm,
  colorSchemeDark,
  colorSchemeDarkWarm,
  colorSchemeDarkBlue,
  colorSchemeVariable,
} from "ag-grid-community";

// ❗️ KHÔNG import CSS ở file này (Next không cho). CSS đã import trong app/layout.tsx.

// --- register modules once ---
const _g: any = globalThis as any;
if (!_g.__AG_MODULES_REGISTERED__) {
  ModuleRegistry.registerModules([
    TextFilterModule,
    NumberFilterModule,
    RowDragModule,
    RowSelectionModule,
    ClientSideRowModelModule,
    ...(process.env.NODE_ENV !== "production" ? [ValidationModule] : []),
  ]);
  _g.__AG_MODULES_REGISTERED__ = true;
}

/** Theme + Scheme mapping */
export type ThemeId = "quartz" | "alpine" | "balham" | "material";
const themeMap: Record<ThemeId, any> = {
  quartz: themeQuartz,
  alpine: themeAlpine,
  balham: themeBalham,
  material: themeMaterial,
};
// className theme để chắc chắn có CSS
const THEME_CLASS: Record<ThemeId, string> = {
  quartz: "ag-theme-quartz",
  alpine: "ag-theme-alpine",
  balham: "ag-theme-balham",
  material: "ag-theme-material",
};

export type SchemeId =
  | "(unchanged)"
  | "light"
  | "lightCold"
  | "lightWarm"
  | "dark"
  | "darkWarm"
  | "darkBlue"
  | "variable";

const schemeMap: Record<SchemeId, any | null> = {
  "(unchanged)": null,
  light: colorSchemeLight,
  lightCold: colorSchemeLightCold,
  lightWarm: colorSchemeLightWarm,
  dark: colorSchemeDark,
  darkWarm: colorSchemeDarkWarm,
  darkBlue: colorSchemeDarkBlue,
  variable: colorSchemeVariable,
};

export type AgGridViewProps<T = any> = {
  title?: string;
  height?: number;

  theme?: ThemeId;            // theme mặc định
  themeSwitcher?: boolean;    // bật dropdown Theme
  schemeSwitcher?: boolean;   // bật dropdown Color scheme
  themeParams?: Record<string, any>; // optional withParams

  rowData?: T[];
  fetchUrl?: string;
  getHeaders?: () => Record<string, string>;

  columnDefs: ColDef<T>[];
  defaultColDef?: ColDef;

  rowSelection?: RowSelectionOptions | "single" | "multiple";
  rowDragManaged?: boolean;
  rowDragMultiRow?: boolean;

  loadingOverride?: boolean;
  gridProps?: Omit<AgGridReactProps<T>, "rowData" | "columnDefs" | "defaultColDef">;
};

export default function AgGridView<T = any>({
  title,
  height = 500,
  theme = "quartz",
  themeSwitcher = true,
  schemeSwitcher = true,
  themeParams,
  rowData,
  fetchUrl,
  getHeaders,
  columnDefs,
  defaultColDef,
  rowSelection = { mode: "multiRow", headerCheckbox: false } as RowSelectionOptions,
  rowDragManaged = true,
  rowDragMultiRow = true,
  loadingOverride,
  gridProps,
}: AgGridViewProps<T>) {
  const [data, setData] = useState<T[]>(rowData ?? []);
  const [loading, setLoading] = useState<boolean>(!!fetchUrl);
  const [activeThemeId, setActiveThemeId] = useState<ThemeId>(theme);
  const [activeSchemeId, setActiveSchemeId] = useState<SchemeId>("darkBlue"); // ✅ default Dark Blue

  // Fetch nếu có fetchUrl
  useEffect(() => {
    if (!fetchUrl) return;
    let cancelled = false;
    (async () => {
      try {
        setLoading(true);
        const res = await fetch(fetchUrl, { headers: getHeaders ? getHeaders() : {} });
        const json = await res.json();
        if (!cancelled) setData(Array.isArray(json) ? json : (json?.data ?? []));
      } catch {
        if (!cancelled) setData([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, [fetchUrl, getHeaders]);

  // Functional theme + withPart(color scheme) + withParams (nếu có)
  const themed = useMemo(() => {
    let base = themeMap[activeThemeId];
    const scheme = schemeMap[activeSchemeId];
    if (scheme) base = base.withPart(scheme);
    if (themeParams) base = base.withParams(themeParams);
    return base;
  }, [activeThemeId, activeSchemeId, themeParams]);

  const containerStyle = useMemo<CSSProperties>(
    () => ({ width: "100%", height: "100%", display: "flex", flexDirection: "column" }),
    []
  );
  const gridStyle = useMemo<CSSProperties>(() => ({ height, width: "100%" }), [height]);

  const mergedDefault: ColDef = useMemo(
    () => ({
      editable: false,
      flex: 1,
      minWidth: 120,
      filter: true,
      floatingFilter: true,
      sortable: true,
      resizable: true,
      ...(defaultColDef ?? {}),
    }),
    [defaultColDef]
  );

  return (
    <div style={{ padding: 20 }}>
      {(title || themeSwitcher || schemeSwitcher) && (
        <div className="flex items-center gap-3 mb-3">
          {title ? <h2 className="text-xl font-semibold m-0">{title}</h2> : null}
          <div style={{ marginLeft: "auto", display: "flex", gap: 12, alignItems: "center" }}>
            {themeSwitcher && (
              <>
                <span className="text-sm text-gray-600">Theme:</span>
                <select
                  value={activeThemeId}
                  onChange={(e) => setActiveThemeId(e.currentTarget.value as ThemeId)}
                  className="border rounded px-2 py-1 text-sm"
                >
                  <option value="quartz">Quartz</option>
                  <option value="alpine">Alpine</option>
                  <option value="balham">Balham</option>
                  <option value="material">Material</option>
                </select>
              </>
            )}
            {schemeSwitcher && (
              <>
                <span className="text-sm text-gray-600">Color scheme:</span>
                <select
                  value={activeSchemeId}
                  onChange={(e) => setActiveSchemeId(e.currentTarget.value as SchemeId)}
                  className="border rounded px-2 py-1 text-sm"
                >
                  <option value="(unchanged)">(unchanged)</option>
                  <option value="light">Light</option>
                  <option value="lightCold">Light Cold</option>
                  <option value="lightWarm">Light Warm</option>
                  <option value="dark">Dark</option>
                  <option value="darkWarm">Dark Warm</option>
                  <option value="darkBlue">Dark Blue</option>
                  <option value="variable">Variable</option>
                </select>
              </>
            )}
          </div>
        </div>
      )}

      <div style={containerStyle}>
        {/* ✅ Bọc className theme để đảm bảo có CSS */}
        <div style={gridStyle} className={THEME_CLASS[activeThemeId]}>
          <AgGridReact<T>
            theme={themed} // vẫn truyền functional theme để dùng Color scheme
            rowData={rowData ?? data}
            loading={loadingOverride ?? (!!fetchUrl && loading)}
            columnDefs={columnDefs}
            defaultColDef={mergedDefault}
            rowSelection={rowSelection}
            rowDragManaged={rowDragManaged}
            rowDragMultiRow={rowDragMultiRow}

            // ✅ Bật lại copy nội dung & DOM order ổn định
            enableCellTextSelection={true}
            ensureDomOrder={true}

            {...gridProps}
          />
        </div>
      </div>
    </div>
  );
}

/** ---------- Helpers (named exports) ---------- */

export function makeIndexCol(): ColDef {
  return {
    headerName: "#",
    field: "__idx" as any,
    width: 60,
    minWidth: 60,
    valueGetter: (p) => (p.node ? p.node.rowIndex! + 1 : ""),
    sortable: false,
    filter: false,
    suppressHeaderMenuButton: true, // thay cho suppressMenu
    resizable: false,
    pinned: "left",
  };
}

export function makeTextDateCol<T extends Record<string, any>>(
  field: keyof T,
  headerName = "Ngày",
  opts?: Partial<ColDef<T>>
): ColDef<T> {
  const key = field as string;
  return {
    field: key as any,
    headerName,
    filter: "agTextColumnFilter",
    floatingFilter: true,
    valueGetter: (p) => {
      const v = (p.data as any)?.[key];
      if (!v) return "";
      const d = new Date(v);
      const mm = String(d.getMonth() + 1).padStart(2, "0");
      const dd = String(d.getDate()).padStart(2, "0");
      return `${d.getFullYear()}-${mm}-${dd}`;
    },
    valueFormatter: (p) => {
      const v = (p.data as any)?.[key];
      return v ? new Date(v).toLocaleDateString("vi-VN") : "";
    },
    ...(opts || {}),
  };
}
