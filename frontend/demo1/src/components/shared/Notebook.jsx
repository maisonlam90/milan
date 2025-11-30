import { useEffect, useState, useMemo } from "react";
import { useFieldArray, Controller } from "react-hook-form";
import { clsx } from "clsx";
import { Button, Input, Textarea } from "components/ui";
import { DatePicker } from "components/shared/form/Datepicker";

export default function Notebook({ name = "transactions", editable = true, form, fields = [] }) {
  const { control, register } = form;
  const { fields: rowFields, append, remove } = useFieldArray({ control, name });

  const [columns, setColumns] = useState([]);

  useEffect(() => {
    setColumns(fields);
  }, [fields]);

  const addEmptyRow = () => {
    const row = {};
    columns.forEach((col) => {
      if (col.type === "number") row[col.name] = 0;
      else if (col.type === "select" && col.options?.length) row[col.name] = col.options[0].value;
      else row[col.name] = "";
    });
    append(row);
  };

  const nf = useMemo(() => new Intl.NumberFormat("vi-VN"), []);
  const formatNumber = (value) => {
    if (value === null || value === undefined || value === "") return "";
    const n = typeof value === "number" ? value : parseNumber(String(value));
    if (n === null) return "";
    return nf.format(n);
  };
  const parseNumber = (str) => {
    if (str === null || str === undefined) return null;
    const s = String(str).trim();
    if (s === "") return null;
    const normalized = s.replace(/\./g, "").replace(/,/g, ".");
    const n = Number(normalized);
    return Number.isFinite(n) ? n : null;
  };

  const allowNumericKeystroke = (e) => {
    const allowed = ["Backspace","Delete","Tab","Enter","ArrowLeft","ArrowRight","Home","End"];
    if (
      allowed.includes(e.key) ||
      /^[0-9]$/.test(e.key) ||
      e.key === "." || e.key === "," ||
      (e.ctrlKey && (e.key === "a" || e.key === "c" || e.key === "v" || e.key === "x"))
    ) return;
    e.preventDefault();
  };

  const formatDateDisplay = (v) => {
    if (!v) return "";
    if (typeof v === "string" && /^\d{4}-\d{2}-\d{2}$/.test(v)) {
      const [y,m,d] = v.split("-").map(Number);
      const dd = String(d).padStart(2,"0");
      const mm = String(m).padStart(2,"0");
      return `${dd}/${mm}/${y}`;
    }
    const d = v instanceof Date ? v : new Date(v);
    if (Number.isNaN(d.getTime())) return String(v ?? "");
    const dd = String(d.getDate()).padStart(2,"0");
    const mm = String(d.getMonth()+1).padStart(2,"0");
    const yy = d.getFullYear();
    return `${dd}/${mm}/${yy}`;
  };

  const roBox = "bg-gray-100 dark:bg-dark-800 text-gray-600 px-2 py-1 rounded";
  const roOneLine = `${roBox} block w-full min-w-0 whitespace-nowrap overflow-hidden text-ellipsis`;

  const getSelectLabel = (col, val) =>
    (col.options || []).find((o) => String(o.value) === String(val))?.label ?? "";

  return (
    <div className="mt-6">
      <div className="flex items-center justify-between">
        <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
          Lịch sử giao dịch
        </h3>
        {editable && (
          <Button size="sm" onClick={addEmptyRow}>
            + Thêm dòng
          </Button>
        )}
      </div>

      <div className="mt-3 overflow-x-auto">
        <table className="min-w-full table-auto border text-sm text-gray-700 dark:text-dark-50">
          <thead className="bg-gray-100 dark:bg-dark-800">
            <tr>
              {columns.map((col) => (
                <th key={col.name} className="px-3 py-2 text-left">
                  {col.label}
                </th>
              ))}
              {editable && <th className="px-3 py-2"></th>}
            </tr>
          </thead>
          <tbody>
            {rowFields.map((field, index) => (
              <tr key={field.id} className="border-t">
                {columns.map((col) => {
                  const isCompute = col.type === "compute";
                  const path = `${name}.${index}.${col.name}`;
                  const watched = form.watch(path);

                  return (
                    <td key={col.name} className="px-3 py-2">
                      {isCompute ? (
                        <div className={roBox}>
                          {(() => {
                            const v = watched;
                            if (typeof v === "number") return formatNumber(v);
                            const maybe = parseNumber(v);
                            return maybe === null ? (v ?? "") : formatNumber(maybe);
                          })()}
                        </div>
                      ) : col.type === "date" ? (
                        editable ? (
                          <Controller
                            control={control}
                            name={path}
                            render={({ field: { value, onChange, ...rest } }) => (
                              <DatePicker
                                value={value || ""}
                                onChange={(val) => {
                                  if (!val) return onChange(null);
                                  const d = new Date(val);
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
                        ) : (
                          <div className={roOneLine}>{formatDateDisplay(watched)}</div>
                        )
                      ) : col.type === "select" ? (
                        editable ? (
                          <select
                            className="w-full rounded border px-2 py-1"
                            {...form.register(path)}
                          >
                            <option value="">-- Chọn --</option>
                            {(col.options || []).map((opt) => (
                              <option key={opt.value} value={opt.value}>
                                {opt.label}
                              </option>
                            ))}
                          </select>
                        ) : (
                          <div className={roOneLine}>{getSelectLabel(col, watched)}</div>
                        )
                      ) : col.type === "textarea" ? (
                        editable ? (
                          <Textarea
                            className="w-full rounded border px-2 py-1"
                            rows={2}
                            {...form.register(path)}
                          />
                        ) : (
                          <div className={clsx(roBox, "whitespace-pre-line")}>
                            {watched || ""}
                          </div>
                        )
                      ) : col.type === "number" ? (
                        editable ? (
                          <Controller
                            control={control}
                            name={path}
                            render={({ field: { value, onChange, onBlur, ref } }) => {
                              const display = formatNumber(value);
                              return (
                                <Input
                                  type="text"
                                  className="w-full"
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
                                    if (parsed === null) onChange("");
                                    else onChange(parsed);
                                    onBlur?.();
                                  }}
                                  ref={ref}
                                  inputMode="decimal"
                                  placeholder="0"
                                />
                              );
                            }}
                          />
                        ) : (
                          <div className={roOneLine}>
                            {(() => {
                              const v = watched;
                              if (typeof v === "number") return formatNumber(v);
                              const maybe = parseNumber(v);
                              return maybe === null ? (v ?? "") : formatNumber(maybe);
                            })()}
                          </div>
                        )
                      ) : (
                        editable ? (
                          <Input
                            type={col.type || "text"}
                            className="w-full"
                            {...register(path)}
                          />
                        ) : (
                          <div className={roOneLine}>{watched || ""}</div>
                        )
                      )}
                    </td>
                  );
                })}
                {editable && (
                  <td className="px-3 py-2 text-center">
                    <button
                      type="button"
                      className="text-red-600 hover:underline"
                      onClick={() => remove(index)}
                    >
                      Xóa
                    </button>
                  </td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}