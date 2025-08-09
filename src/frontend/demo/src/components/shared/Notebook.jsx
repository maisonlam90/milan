import { useEffect, useState } from "react";
import { useFieldArray, Controller } from "react-hook-form";
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
                  return (
                    <td key={col.name} className="px-3 py-2">
                      {isCompute ? (
                        <div className="bg-gray-100 dark:bg-dark-800 text-gray-600 px-2 py-1 rounded">
                          {form.watch(`${name}.${index}.${col.name}`) ?? ""}
                        </div>
                      ) : col.type === "date" ? (
                        <Controller
                          control={control}
                          name={`${name}.${index}.${col.name}`}
                          render={({ field: { value, onChange, ...rest } }) => (
                            <DatePicker
                              value={value || ""}
                              onChange={onChange}
                              placeholder="Chọn ngày..."
                              className="w-full"
                              options={{ disableMobile: true }}
                              {...rest}
                            />
                          )}
                        />
                      ) : col.type === "select" ? (
                        <select
                          className="w-full rounded border px-2 py-1"
                          {...register(`${name}.${index}.${col.name}`)}
                        >
                          <option value="">-- Chọn --</option>
                          {(col.options || []).map((opt) => (
                            <option key={opt.value} value={opt.value}>
                              {opt.label}
                            </option>
                          ))}
                        </select>
                      ) : col.type === "textarea" ? (
                        <Textarea
                          className="w-full rounded border px-2 py-1"
                          rows={2}
                          {...register(`${name}.${index}.${col.name}`)}
                        />
                      ) : (
                        <Input
                          type={col.type || "text"}
                          className="w-full"
                          {...register(`${name}.${index}.${col.name}`, {
                            valueAsNumber: col.type === "number",
                          })}
                        />
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
