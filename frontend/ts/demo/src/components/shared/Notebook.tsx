// src/components/shared/Notebook.tsx
import { useEffect, useState, useMemo } from "react";
import { useFieldArray, Controller, type UseFormReturn, type FieldValues } from "react-hook-form";
import clsx from "clsx";
import { Button, Input, Textarea } from "@/components/ui";
import { DatePicker } from "@/components/shared/form/Datepicker";

/* ==== Types ==== */

export type NotebookColumnType = "text" | "number" | "date" | "select" | "textarea" | "compute";

export interface NotebookOption {
  label: string;
  value: string | number;
}

export interface NotebookColumn {
  name: string;
  label: string;
  type?: NotebookColumnType;
  options?: NotebookOption[];
  [k: string]: unknown;
}

export interface NotebookProps<TForm extends FieldValues = FieldValues> {
  /** Tên mảng trong RHF, ví dụ "transactions" */
  name?: string;
  /** Cho phép chỉnh sửa hay chỉ đọc */
  editable?: boolean;
  /** RHF form instance */
  form: UseFormReturn<TForm>;
  /** Danh sách cột */
  fields?: NotebookColumn[];
}

/* ==== Component ==== */

export default function Notebook<TForm extends FieldValues = FieldValues>({
  name = "transactions",
  editable = true,
  form,
  fields = [],
}: NotebookProps<TForm>) {
  const { control, register } = form;
  const { fields: rowFields, append, remove } = useFieldArray({
    control,
    name: name as any, // name động
  });

  const [columns, setColumns] = useState<NotebookColumn[]>([]);

  useEffect(() => {
    setColumns(fields);
  }, [fields]);

  const addEmptyRow = () => {
    const row: Record<string, unknown> = {};
    columns.forEach((col) => {
      if (col.type === "number") row[col.name] = 0;
      else if (col.type === "date") row[col.name] = null; // ✅ tránh "" gây Invalid Date
      else if (col.type === "select" && col.options?.length) row[col.name] = col.options[0].value;
      else row[col.name] = "";
    });
    append(row as never);
  };

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
    if (n === null) return "";
    return nf.format(n);
  };

  const allowNumericKeystroke = (e: React.KeyboardEvent<HTMLInputElement>) => {
    const allowed = ["Backspace", "Delete", "Tab", "Enter", "ArrowLeft", "ArrowRight", "Home", "End"];
    if (
      allowed.includes(e.key) ||
      /^[0-9]$/.test(e.key) ||
      e.key === "." ||
      e.key === "," ||
      (e.ctrlKey && (e.key === "a" || e.key === "c" || e.key === "v" || e.key === "x"))
    )
      return;
    e.preventDefault();
  };

  const formatDateDisplay = (v: unknown): string => {
    if (!v) return "";
    if (typeof v === "string" && /^\d{4}-\d{2}-\d{2}$/.test(v)) {
      const [y, m, d] = v.split("-").map(Number);
      const dd = String(d).padStart(2, "0");
      const mm = String(m).padStart(2, "0");
      return `${dd}/${mm}/${y}`;
    }
    const d = v instanceof Date ? v : new Date(v as any);
    if (Number.isNaN(d.getTime())) return String(v ?? "");
    const dd = String(d.getDate()).padStart(2, "0");
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    const yy = d.getFullYear();
    return `${dd}/${mm}/${yy}`;
  };

  const roBox = "bg-gray-100 dark:bg-dark-800 text-gray-600 px-2 py-1 rounded";
  const roOneLine = `${roBox} block w-full min-w-0 whitespace-nowrap overflow-hidden text-ellipsis`;

  const getSelectLabel = (col: NotebookColumn, val: unknown) =>
    (col.options || []).find((o) => String(o.value) === String(val))?.label ?? "";

  // Chuyển mọi kiểu trả về từ DatePicker về ISO UTC 00:00:00
  const toISODate = (val: unknown): string | null => {
    if (!val) return null;
    let d: Date | null = null;
    if (val instanceof Date) {
      d = val;
    } else if (Array.isArray(val) && val[0] instanceof Date) {
      d = val[0] as Date;
    } else if (typeof val === "string") {
      const m = val.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/); // dd/mm/yyyy
      if (m) {
        const dd = parseInt(m[1], 10);
        const mm = parseInt(m[2], 10) - 1;
        const yy = parseInt(m[3], 10);
        d = new Date(yy, mm, dd);
      } else {
        const tmp = new Date(val);
        d = Number.isNaN(tmp.getTime()) ? null : tmp;
      }
    }
    if (!d || Number.isNaN(d.getTime())) return null;
    const utc = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
    return utc.toISOString();
  };

  return (
    <div className="mt-6">
      <div className="flex items-center justify-between">
        <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">Lịch sử giao dịch</h3>
        {editable && (
          <Button type="button" className="h-8 px-2 text-sm" onClick={addEmptyRow}>
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
            {rowFields.map((fieldRow, rowIndex) => (
              <tr key={fieldRow.id} className="border-t">
                {columns.map((col) => {
                  const isCompute = col.type === "compute";
                  const path = `${name}.${rowIndex}.${col.name}`;
                  const watched = form.watch(path as any);

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
                            name={path as any}
                            render={({ field: { value, onChange, ...rest } }) => {
                              const safeValue = (value ?? "") as string; // Flatpickr nhận "" = empty
                              return (
                                <DatePicker
                                  value={safeValue}
                                  onChange={(val: unknown) => {
                                    const iso = toISODate(val);
                                    onChange(iso ?? null); // null nếu không parse được
                                  }}
                                  placeholder="Chọn ngày..."
                                  className="w-full"
                                  options={{ disableMobile: true, dateFormat: "d/m/Y" }}
                                  {...rest}
                                />
                              );
                            }}
                          />
                        ) : (
                          <div className={roOneLine}>{formatDateDisplay(watched)}</div>
                        )
                      ) : col.type === "select" ? (
                        editable ? (
                          <select className="w-full rounded border px-2 py-1" {...register(path as any)}>
                            <option value="">-- Chọn --</option>
                            {(col.options || []).map((opt) => (
                              <option key={String(opt.value)} value={String(opt.value)}>
                                {opt.label}
                              </option>
                            ))}
                          </select>
                        ) : (
                          <div className={roOneLine}>{getSelectLabel(col, watched)}</div>
                        )
                      ) : col.type === "textarea" ? (
                        editable ? (
                          <Textarea className="w-full rounded border px-2 py-1" rows={2} {...register(path as any)} />
                        ) : (
                          <div className={clsx(roBox, "whitespace-pre-line")}>{(watched as string) || ""}</div>
                        )
                      ) : col.type === "number" ? (
                        editable ? (
                          <Controller
                            control={control}
                            name={path as any}
                            render={({ field: { value, onChange, onBlur, ref } }) => {
                              const display = formatNumber(value);
                              return (
                                <Input
                                  type="text"
                                  className="w-full"
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
                          <Input type={(col.type as string) || "text"} className="w-full" {...register(path as any)} />
                        ) : (
                          <div className={roOneLine}>{(watched as string) || ""}</div>
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
                      onClick={() => remove(rowIndex)}
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
