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
  if (!fields || !Array.isArray(fields)) {
    return <p className="text-red-500">⚠️ Metadata form.fields không hợp lệ</p>;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
      {fields.map((field, idx) => {
        const span = widthClass[field.width?.toString()] || "md:col-span-12";
        const error = form.formState.errors?.[field.name]?.message;

        return (
          <div key={field.name || idx} className={span}>
            {renderField(field, form, optionsMap, error, disabled)}
          </div>
        );
      })}
    </div>
  );
}

/** format giá trị để hiển thị read-only */
function formatReadOnly(field, raw, optionsMap) {
  if (raw === null || raw === undefined || raw === "") {
    return <span className="text-gray-400">—</span>;
  }

  if (field.type === "date") {
    // hỗ trợ ISO string hoặc epoch seconds
    let d;
    if (typeof raw === "number") d = new Date(raw * 1000);
    else d = new Date(raw);
    return <span>{isNaN(d) ? String(raw) : d.toLocaleDateString('vi-VN')}</span>;
  }

  if (field.type === "select") {
    const options = optionsMap?.[field.name] || field.options || [];
    const label = options.find((o) => o.value === raw)?.label ?? raw;
    return <span>{label ?? <span className="text-gray-400">—</span>}</span>;
  }

  if (field.type === "number") {
    const n = typeof raw === "number" ? raw : parseFloat(raw);
    return <span>{isNaN(n) ? String(raw) : n.toLocaleString()}</span>;
  }

  if (field.type === "textarea") {
    return <div className="whitespace-pre-wrap">{String(raw)}</div>;
  }

  return <span>{String(raw)}</span>;
}

function FieldLabel({ label }) {
  return <label className="block mb-1 text-gray-700 dark:text-dark-100">{label}</label>;
}

function renderField(field, form, optionsMap, error, disabled) {
  const rules = { required: `${field.label} là bắt buộc` };
  const rawValue = form.getValues(field.name);

  // 🔒 READ-ONLY MODE: render text thuần, không dùng input để tránh icon/hover
  if (disabled) {
    return (
      <div>
        <FieldLabel label={field.label} />
        <div className="min-h-[38px] px-3 py-2 rounded border bg-white dark:bg-dark-900">
          {formatReadOnly(field, rawValue, optionsMap)}
        </div>
        {error && <p className="text-red-500 text-sm mt-1">{error}</p>}
      </div>
    );
  }

  // ✏️ EDIT MODE: render control như cũ
  if (field.type === "textarea") {
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
    return (
      <div>
        <FieldLabel label={field.label} />
        <select
          {...form.register(field.name, rules)}
          className="border rounded-md p-2 w-full"
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

  if (field.type === "date") {
    return (
      <Controller
        control={form.control}
        name={field.name}
        rules={rules}
        render={({ field: { value, onChange, ...rest } }) => (
          <DatePicker
            label={field.label}
            value={value || ""}
            onChange={onChange}
            error={error}
            placeholder="Chọn ngày..."
            options={{ disableMobile: true }}
            {...rest}
          />
        )}
      />
    );
  }

  return (
    <Input
      type={field.type === "number" ? "number" : "text"}
      label={field.label}
      error={error}
      {...form.register(field.name, {
        ...rules,
        valueAsNumber: field.type === "number",
      })}
    />
  );
}
