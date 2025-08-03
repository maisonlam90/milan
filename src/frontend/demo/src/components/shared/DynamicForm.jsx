import { Input, Textarea } from "components/ui";
import { DatePicker } from "components/shared/form/Datepicker";

const widthClass = {
  "3": "md:col-span-3",
  "4": "md:col-span-4",
  "6": "md:col-span-6",
  "8": "md:col-span-8",
  "12": "md:col-span-12",
};

export default function DynamicForm({ form, fields, optionsMap }) {
  if (!fields || !Array.isArray(fields)) {
    return <p className="text-red-500">⚠️ Metadata form.fields không hợp lệ</p>;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
      {fields.map((field, idx) => {
        const span = widthClass[field.width?.toString()] || "md:col-span-12";
        const error = form.formState.errors?.[field.name]?.message;
        const value = form.getValues(field.name) || "";

        return (
          <div key={field.name || idx} className={span}>
            {renderField(field, form, optionsMap, value, error)}
          </div>
        );
      })}
    </div>
  );
}

function renderField(field, form, optionsMap, value, error) {
  const rules = { required: `${field.label} là bắt buộc` };

  // textarea
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

  // select (HTML thuần)
  if (field.type === "select") {
    const options = optionsMap?.[field.name] || field.options || [];
    return (
      <div>
        <label className="block mb-1">{field.label}</label>
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

  // date (DatePicker theme, fallback nếu lỗi)
  if (field.type === "date") {
    return (
      <DatePicker
        label={field.label}
        error={error}
        value={value || null}
        onChange={(date) => form.setValue(field.name, date)}
      />
    );
  }

  // number và text
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
