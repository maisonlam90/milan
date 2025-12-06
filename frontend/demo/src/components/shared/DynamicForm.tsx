import React, { useMemo } from "react";
import clsx from "clsx";
import { Controller, FieldValues, UseFormReturn } from "react-hook-form";
import dayjs from "dayjs";

import { Input, Textarea, Checkbox } from "@/components/ui";
import { DatePicker } from "@/components/shared/form/Datepicker";

/* ===================== Types ===================== */

type WidthSpan = 3 | 4 | 6 | 8 | 12;

export interface SelectOption {
  value: string | number;
  label: string;
  disabled?: boolean;
}

// ✅ THÊM email và checkbox
// ✅ Export FieldType để có thể dùng ở nơi khác nếu cần
export type FieldType = "text" | "textarea" | "select" | "date" | "datetime" | "number" | "email" | "checkbox";

export interface DynamicFieldConfig {
  name: string;
  label: string;
  type?: FieldType;
  width?: WidthSpan;
  required?: boolean;
  disabled?: boolean;
  hidden?: boolean; // Nếu true thì field sẽ không hiển thị
  options?: SelectOption[];
}

interface DynamicFormProps<TForm extends FieldValues = FieldValues> {
  form: UseFormReturn<TForm>;
  fields: DynamicFieldConfig[];
  optionsMap?: Record<string, SelectOption[]>;
  disabled?: boolean;
}

/* ===================== Consts ===================== */

const widthClass: Record<`${WidthSpan}`, string> = {
  "3": "md:col-span-3",
  "4": "md:col-span-4",
  "6": "md:col-span-6",
  "8": "md:col-span-8",
  "12": "md:col-span-12",
} as const;

/* ===================== Component ===================== */

export default function DynamicForm<TForm extends FieldValues = FieldValues>({
  form,
  fields,
  optionsMap,
  disabled = false,
}: DynamicFormProps<TForm>) {
  const nf = useMemo(() => new Intl.NumberFormat("vi-VN"), []);

  const parseNumber = (str: unknown): number | null => {
    if (str === null || str === undefined) return null;
    const s = String(str).trim();
    if (s === "") return null;
    const normalized = s.replace(/\./g, "").replace(/,/g, ".");
    const n = Number(normalized);
    return Number.isFinite(n) ? n : null;
  };

  const formatNumber = (value: unknown): string => {
    if (value === null || value === undefined || value === "") return "";
    const n = typeof value === "number" ? value : parseNumber(String(value));
    return n === null ? "" : nf.format(n);
  };

  const allowNumericKeystroke = (e: React.KeyboardEvent<HTMLInputElement>) => {
    const allowed = [
      "Backspace", "Delete", "Tab", "Enter", "ArrowLeft", "ArrowRight", "Home", "End",
    ];
    if (
      allowed.includes(e.key) ||
      /^[0-9]$/.test(e.key) ||
      e.key === "." || e.key === "," ||
      (e.ctrlKey && ["a", "c", "v", "x"].includes(e.key.toLowerCase()))
    ) return;
    e.preventDefault();
  };

  const formatDateDisplay = (v: unknown): string => {
    if (!v) return "";
    
    // Use dayjs for better date parsing and formatting
    if (typeof v === "string") {
      const d = dayjs(v);
      if (d.isValid()) {
        return d.format("DD/MM/YYYY");
      }
    }
    
    // Fallback for Date objects
    if (v instanceof Date) {
      const d = dayjs(v);
      if (d.isValid()) {
        return d.format("DD/MM/YYYY");
      }
    }
    
    // Last resort: try to parse as Date
    try {
      const d = dayjs(v as any);
      if (d.isValid()) {
        return d.format("DD/MM/YYYY");
      }
    } catch (e) {
      // Ignore
    }
    
    return String(v ?? "");
  };

  const roBox = "bg-gray-100 dark:bg-dark-800 text-gray-600 px-2 py-1 rounded";
  const roOneLine = `${roBox} block w-full min-w-0 whitespace-nowrap overflow-hidden text-ellipsis`;

  const fieldsInvalid = !Array.isArray(fields);
  const safeFields: DynamicFieldConfig[] = fieldsInvalid ? [] : fields;
  
  // Filter out hidden fields (có thể dùng để "comment out" fields)
  const visibleFields = safeFields.filter(f => !f.hidden);

  return (
    <>
      {fieldsInvalid && (
        <p className="text-red-500 mb-3">⚠️ Metadata form.fields không hợp lệ</p>
      )}
      <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
        {visibleFields.map((field, idx) => {
          const span = widthClass[String(field.width ?? 12) as `${WidthSpan}`] || "md:col-span-12";
          const errObj = (form.formState.errors as any)?.[field.name];
          const error: string | undefined = errObj?.message as string | undefined;
          const isDisabled = disabled || !!field.disabled;

          return (
            <div key={field.name || idx} className={span}>
              {renderField({
                field,
                form,
                optionsMap,
                error,
                disabled: isDisabled,
                formatNumber,
                parseNumber,
                allowNumericKeystroke,
                roBox,
                roOneLine,
                formatDateDisplay,
              })}
            </div>
          );
        })}
      </div>
    </>
  );
}

/* ===================== Subcomponents ===================== */

function FieldLabel({ label }: { label: string }) {
  return <label className="block mb-1 text-gray-700 dark:text-dark-100">{label}</label>;
}

function renderField<TForm extends FieldValues>({
  field,
  form,
  optionsMap,
  error,
  disabled,
  formatNumber,
  parseNumber,
  allowNumericKeystroke,
  roBox,
  roOneLine,
  formatDateDisplay,
}: {
  field: DynamicFieldConfig;
  form: UseFormReturn<TForm>;
  optionsMap?: Record<string, SelectOption[]>;
  error?: string;
  disabled: boolean;
  formatNumber: (v: unknown) => string;
  parseNumber: (v: unknown) => number | null;
  allowNumericKeystroke: (e: React.KeyboardEvent<HTMLInputElement>) => void;
  roBox: string;
  roOneLine: string;
  formatDateDisplay: (v: unknown) => string;
}) {
  const rules = field.required ? { required: `${field.label} là bắt buộc` } : {};

  /* -------- checkbox -------- */
  if (field.type === "checkbox") {
    if (disabled) {
      const val = form.watch(field.name as any) as unknown;
      return (
        <div>
          <FieldLabel label={field.label} />
          <div className={roOneLine}>{val ? "Có" : "Không"}</div>
          {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
        </div>
      );
    }

    return (
      <Controller
        control={form.control}
        name={field.name as any}
        rules={rules}
        render={({ field: { value, onChange, ...rest } }) => (
          <div>
            <Checkbox
              checked={!!value}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => onChange(e.target.checked)}
              label={field.label}
              {...rest}
            />
            {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
          </div>
        )}
      />
    );
  }

  /* -------- email -------- */
  if (field.type === "email") {
    if (disabled) {
      const val = form.watch(field.name as any) as unknown;
      return (
        <div>
          <FieldLabel label={field.label} />
          <div className={roOneLine}>{(val as string) || ""}</div>
          {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
        </div>
      );
    }

    return (
      <Input
        type="email"
        label={field.label}
        error={error}
        {...form.register(field.name as any, {
          ...rules,
          pattern: {
            value: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
            message: "Email không hợp lệ"
          }
        })}
      />
    );
  }

  /* -------- textarea -------- */
  if (field.type === "textarea") {
    if (disabled) {
      const val = form.watch(field.name as any) as unknown;
      return (
        <div>
          <FieldLabel label={field.label} />
          <div className={clsx(roBox, "whitespace-pre-line")}>{(val as string) || ""}</div>
          {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
        </div>
      );
    }
    return (
      <Textarea
        label={field.label}
        error={error}
        rows={3}
        {...form.register(field.name as any, rules)}
      />
    );
  }

  /* -------- select -------- */
  if (field.type === "select") {
    const options = optionsMap?.[field.name] || field.options || [];
    const getSelectLabel = (val: unknown) =>
      (options || []).find((o) => String(o.value) === String(val))?.label ?? "";

    if (disabled) {
      const val = form.watch(field.name as any);
      return (
        <div>
          <FieldLabel label={field.label} />
          <div className={roOneLine}>{getSelectLabel(val)}</div>
          {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
        </div>
      );
    }

    return (
      <div>
        <FieldLabel label={field.label} />
        <select
          className="border rounded-md p-2 w-full"
          {...form.register(field.name as any, rules)}
        >
          <option value="">-- Chọn {field.label} --</option>
          {options.map((opt, idx) => (
            <option key={idx} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
        {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
      </div>
    );
  }

  /* -------- date và datetime -------- */
  if (field.type === "date" || field.type === "datetime") {
    if (disabled) {
      const val = form.watch(field.name as any);
      return (
        <div>
          <FieldLabel label={field.label} />
          <div className={roOneLine}>{formatDateDisplay(val)}</div>
          {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
        </div>
      );
    }

    return (
      <div>
        <FieldLabel label={field.label} />
        <Controller
          control={form.control}
          name={field.name as any}
          rules={rules}
          render={({ field: { value, onChange, ...rest } }) => (
            <DatePicker
              value={value || ""}
              onChange={(selectedDates: Date[]) => {
                const first = selectedDates?.[0] ?? null;
                if (!first) return onChange(null);
                const d = new Date(first);
                const utc = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
                onChange(utc.toISOString());
              }}
              placeholder="Chọn ngày..."
              className="w-full"
              options={{ disableMobile: true, dateFormat: "d/m/Y" }}
              {...rest}
            />
          )}
        />
        {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
      </div>
    );
  }

  /* -------- number -------- */
  if (field.type === "number") {
    if (disabled) {
      const v = form.watch(field.name as any) as unknown;
      const show = (() => {
        if (typeof v === "number") return formatNumber(v);
        const maybe = parseNumber(v);
        return maybe === null ? ((v as string) ?? "") : formatNumber(maybe);
      })();
      return (
        <div>
          <FieldLabel label={field.label} />
          <div className={roOneLine}>{show}</div>
          {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
        </div>
      );
    }

    return (
      <Controller
        control={form.control}
        name={field.name as any}
        rules={rules}
        render={({ field: { value, onChange, onBlur, ref } }) => {
          const display = formatNumber(value);
          return (
            <Input
              type="text"
              label={field.label}
              error={error}
              value={display}
              onKeyDown={allowNumericKeystroke}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                const raw = e.target.value;
                const parsed = parseNumber(raw);
                if (raw.trim() === "") onChange("");
                else if (parsed !== null) onChange(parsed);
              }}
              onBlur={(e: React.FocusEvent<HTMLInputElement>) => {
                const parsed = parseNumber(e.target.value);
                onChange(parsed ?? "");
                onBlur?.();
              }}
              ref={ref}
              inputMode="decimal"
              placeholder="0"
            />
          );
        }}
      />
    );
  }

  /* -------- default: text -------- */
  if (disabled) {
    const val = form.watch(field.name as any) as unknown;
    return (
      <div>
        <FieldLabel label={field.label} />
        <div className={roOneLine}>{(val as string) || ""}</div>
        {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
      </div>
    );
  }

  return (
    <Input
      type="text"
      label={field.label}
      error={error}
      {...form.register(field.name as any, rules)}
    />
  );
}