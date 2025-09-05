import { useMemo } from "react";
import { clsx } from "clsx";
import { Input, Textarea } from "components/ui";
import { DatePicker } from "components/shared/form/Datepicker";
import { Controller } from "react-hook-form";

const widthClass = {
  "3": "md:col-span-3",
  "4": "md:col-span-4",
  "6": "md:col-span-6",
  "8": "md:col-span-8",
  "12": "md:col-span-12",
};

export default function DynamicForm({ form, fields, optionsMap, disabled = false }) {
  const nf = useMemo(() => new Intl.NumberFormat("vi-VN"), []);
  const parseNumber = (str) => {
    if (str === null || str === undefined) return null;
    const s = String(str).trim();
    if (s === "") return null;
    const normalized = s.replace(/\./g, "").replace(/,/g, ".");
    const n = Number(normalized);
    return Number.isFinite(n) ? n : null;
  };
  const formatNumber = (value) => {
    if (value === null || value === undefined || value === "") return "";
    const n = typeof value === "number" ? value : parseNumber(String(value));
    return n === null ? "" : nf.format(n);
  };

  const allowNumericKeystroke = (e) => {
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

  const formatDateDisplay = (v) => {
    if (!v) return "";
    if (typeof v === "string" && /^\d{4}-\d{2}-\d{2}$/.test(v)) {
      const [y, m, d] = v.split("-").map(Number);
      return `${String(d).padStart(2, "0")}/${String(m).padStart(2, "0")}/${y}`;
    }
    const d = v instanceof Date ? v : new Date(v);
    if (Number.isNaN(d.getTime())) return String(v ?? "");
    const dd = String(d.getDate()).padStart(2, "0");
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    const yy = d.getFullYear();
    return `${dd}/${mm}/${yy}`;
  };

  const roBox = "bg-gray-100 dark:bg-dark-800 text-gray-600 px-2 py-1 rounded";
  const roOneLine = `${roBox} block w-full min-w-0 whitespace-nowrap overflow-hidden text-ellipsis`;

  const fieldsInvalid = !Array.isArray(fields);
  const safeFields = fieldsInvalid ? [] : fields;

  return (
    <>
      {fieldsInvalid && (
        <p className="text-red-500 mb-3">⚠️ Metadata form.fields không hợp lệ</p>
      )}
      <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
        {safeFields.map((field, idx) => {
          const span = widthClass[field.width?.toString()] || "md:col-span-12";
          const error = form.formState.errors?.[field.name]?.message;
          const isDisabled = disabled || field.disabled;

          return (
            <div key={field.name || idx} className={span}>
              {renderField({
                field, form, optionsMap, error,
                disabled: isDisabled,
                formatNumber, parseNumber, allowNumericKeystroke,
                roBox, roOneLine, formatDateDisplay,
              })}
            </div>
          );
        })}
      </div>
    </>
  );
}

function FieldLabel({ label }) {
  return <label className="block mb-1 text-gray-700 dark:text-dark-100">{label}</label>;
}

function renderField({
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
}) {
  const rules = field.required ? { required: `${field.label} là bắt buộc` } : {};

  if (field.type === "textarea") {
    if (disabled) {
      const val = form.watch(field.name);
      return (
        <div>
          <FieldLabel label={field.label} />
          <div className={clsx(roBox, "whitespace-pre-line")}>{val || ""}</div>
          {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
        </div>
      );
    }
    return (
      <Textarea
        label={field.label}
        error={error}
        rows={3}
        {...form.register(field.name, rules)}
      />
    );
  }

  if (field.type === "select") {
    const options = optionsMap?.[field.name] || field.options || [];
    const getSelectLabel = (val) =>
      (options || []).find((o) => String(o.value) === String(val))?.label ?? "";

    if (disabled) {
      const val = form.watch(field.name);
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
          {...form.register(field.name, rules)}
        >
          <option value="">-- Chọn {field.label} --</option>
          {options.map((opt, idx) => (
            <option key={idx} value={opt.value}>{opt.label}</option>
          ))}
        </select>
        {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
      </div>
    );
  }

  if (field.type === "date") {
    if (disabled) {
      const val = form.watch(field.name);
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
          name={field.name}
          rules={rules}
          render={({ field: { value, onChange, ...rest } }) => (
            <DatePicker
              value={value || ""}
              onChange={onChange}
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

  if (field.type === "number") {
    if (disabled) {
      const v = form.watch(field.name);
      const show = (() => {
        if (typeof v === "number") return formatNumber(v);
        const maybe = parseNumber(v);
        return maybe === null ? (v ?? "") : formatNumber(maybe);
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
        name={field.name}
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
              onChange={(e) => {
                const raw = e.target.value;
                const parsed = parseNumber(raw);
                if (raw.trim() === "") onChange("");
                else if (parsed !== null) onChange(parsed);
              }}
              onBlur={(e) => {
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

  if (disabled) {
    const val = form.watch(field.name);
    return (
      <div>
        <FieldLabel label={field.label} />
        <div className={roOneLine}>{val || ""}</div>
        {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
      </div>
    );
  }

  return (
    <Input
      type="text"
      label={field.label}
      error={error}
      {...form.register(field.name, rules)}
    />
  );
}
