// Import Dependencies
import { useState, useMemo } from "react";
import { useForm, useFieldArray } from "react-hook-form";
import * as yup from "yup";
import { yupResolver } from "@hookform/resolvers/yup";
import { useNavigate } from "react-router-dom";
import axiosInstance from "@/utils/axios";
import dayjs from "dayjs";

// Local Imports
import { Input, Button, Textarea } from "@/components/ui";
import { DatePicker } from "@/components/shared/form/Datepicker";
import {
  Table,
  THead,
  TBody,
  Th,
  Tr,
  Td,
} from "@/components/ui";
import { ChevronDownIcon } from "@heroicons/react/20/solid";

// ----------------------------------------------------------------------

// Types
interface InvoiceLine {
  id?: string;
  product_id?: string;
  product_name?: string;
  name?: string;
  quantity?: number;
  price_unit?: number;
  discount?: number;
  tax_ids?: string[];
  amount?: number;
  display_type?: "line_section" | "line_note" | null;
}

interface InvoiceFormData {
  partner_id?: string;
  invoice_date: string;
  invoice_date_due: string;
  invoice_payment_term_id?: string;
  narration?: string;
  invoice_lines: InvoiceLine[];
}

// Validation Schema
const schema = yup.object({
  partner_id: yup.string().optional(),
  invoice_date: yup.string().required("Invoice Date is required"),
  invoice_date_due: yup.string().required("Due Date is required"),
  invoice_payment_term_id: yup.string().optional(),
  narration: yup.string().optional(),
  invoice_lines: yup.array().of(
    yup.object().shape({
      product_id: yup.string().optional(),
      name: yup.string().optional(),
      quantity: yup.number().min(0).optional(),
      price_unit: yup.number().min(0).optional(),
      discount: yup.number().min(0).max(100).optional(),
      amount: yup.number().optional(),
      display_type: yup.string().optional(),
    })
  ),
}) as yup.ObjectSchema<InvoiceFormData>;

// ----------------------------------------------------------------------

export default function InvoiceCreate() {
  const navigate = useNavigate();
  const [status, setStatus] = useState<"draft" | "posted">("draft");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    control,
    watch,
    setValue,
    formState: { errors },
  } = useForm<InvoiceFormData>({
    resolver: yupResolver(schema),
    defaultValues: {
      invoice_date: dayjs().format("YYYY-MM-DD"),
      invoice_date_due: dayjs().add(30, "day").format("YYYY-MM-DD"),
      invoice_lines: [],
    },
  });

  const { fields, append, remove, update } = useFieldArray({
    control,
    name: "invoice_lines",
  });

  const invoiceLines = watch("invoice_lines");

  // Calculate totals
  const totals = useMemo(() => {
    let untaxed = 0;
    let tax = 0;
    let total = 0;

    invoiceLines?.forEach((line) => {
      if (line.display_type) return; // Skip section/note lines

      const qty = line.quantity || 0;
      const price = line.price_unit || 0;
      const discount = line.discount || 0;
      const subtotal = qty * price * (1 - discount / 100);
      untaxed += subtotal;
      // TODO: Calculate tax based on tax_ids
      tax += subtotal * 0.1; // Placeholder 10% tax
    });

    total = untaxed + tax;
    return { untaxed, tax, total, amountDue: total };
  }, [invoiceLines]);

  // Add invoice line
  const handleAddLine = () => {
    append({
      product_id: undefined,
      name: "",
      quantity: 1,
      price_unit: 0,
      discount: 0,
      amount: 0,
    });
  };

  // Add section
  const handleAddSection = () => {
    append({
      display_type: "line_section",
      name: "Section",
      quantity: 0,
      price_unit: 0,
    });
  };

  // Add note
  const handleAddNote = () => {
    append({
      display_type: "line_note",
      name: "Note",
      quantity: 0,
      price_unit: 0,
    });
  };

  // Update line amount
  const updateLineAmount = (index: number) => {
    const line = invoiceLines[index];
    if (!line || line.display_type) return;

    const qty = line.quantity || 0;
    const price = line.price_unit || 0;
    const discount = line.discount || 0;
    const amount = qty * price * (1 - discount / 100);
    
    update(index, { ...line, amount });
  };

  // Handle form submission
  const onSubmit = async (data: InvoiceFormData) => {
    setIsSubmitting(true);
    setError(null);
    
    try {
      console.log("Submitting invoice data:", data);
      
      // Validate that we have at least one invoice line
      const validLines = data.invoice_lines.filter((line) => !line.display_type);
      if (validLines.length === 0) {
        setError("Vui lòng thêm ít nhất một dòng sản phẩm vào hóa đơn");
        setIsSubmitting(false);
        return;
      }

      // Create invoice payload
      // Backend will auto-create journal if not provided (nil UUID)
      const payload = {
        move_type: "out_invoice",
        partner_id: data.partner_id || null,
        invoice_date: data.invoice_date,
        invoice_date_due: data.invoice_date_due,
        invoice_payment_term_id: data.invoice_payment_term_id || null,
        narration: data.narration || null,
        invoice_lines: validLines.map((line) => ({
          product_id: line.product_id || null,
          name: line.name || "",
          quantity: line.quantity || 0,
          price_unit: line.price_unit || 0,
          discount: line.discount || 0,
          tax_ids: line.tax_ids || [],
        })),
        date: data.invoice_date,
        journal_id: "00000000-0000-0000-0000-000000000000", // nil UUID - backend will auto-create
        currency_id: "00000000-0000-0000-0000-000000000000", // nil UUID - backend will use default
      };

      console.log("Invoice payload:", payload);

      // Create invoice
      const response = await axiosInstance.post("/invoice/create", payload);
      console.log("Invoice created successfully:", response.data);

      if (!response.data?.id) {
        throw new Error("Không nhận được ID hóa đơn từ server");
      }

      // If status is posted, confirm the invoice
      if (status === "posted") {
        try {
          await axiosInstance.post(`/invoice/${response.data.id}/confirm`);
          console.log("Invoice confirmed successfully");
        } catch (confirmError: any) {
          console.error("Error confirming invoice:", confirmError);
          setError(`Hóa đơn đã được tạo nhưng không thể xác nhận: ${confirmError?.response?.data?.message || confirmError.message}`);
          setIsSubmitting(false);
          return;
        }
      }

      // Navigate to invoice list
      navigate("/dashboards/invoice/invoice-list");
    } catch (error: any) {
      console.error("Error creating invoice:", error);
      const errorMessage = error?.response?.data?.message || error?.response?.data?.error || error?.message || "Có lỗi xảy ra khi tạo hóa đơn";
      setError(errorMessage);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle save (draft)
  const handleSave = async (e: React.MouseEvent) => {
    e.preventDefault();
    setStatus("draft");
    handleSubmit(onSubmit)();
  };

  // Handle confirm (post)
  const handleConfirm = async (e: React.MouseEvent) => {
    e.preventDefault();
    setStatus("posted");
    handleSubmit(onSubmit)();
  };

  return (
    <div className="flex h-full flex-col bg-white dark:bg-dark-900">
      {/* Header */}
      <div className="border-b border-gray-200 bg-white px-6 py-4 dark:border-dark-500 dark:bg-dark-800">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Button
                type="button"
                onClick={handleSave}
                variant="outlined"
                className="border-gray-300 text-gray-700 hover:bg-gray-50 dark:border-dark-500 dark:text-dark-200"
                disabled={isSubmitting}
              >
                {isSubmitting ? "Đang lưu..." : "Lưu"}
              </Button>
              <Button
                type="button"
                onClick={handleConfirm}
                className="bg-purple-600 text-white hover:bg-purple-700"
                disabled={isSubmitting}
              >
                {isSubmitting ? "Đang xử lý..." : "Confirm"}
              </Button>
            </div>
            <div>
              <h1 className="text-xl font-semibold text-gray-900 dark:text-dark-50">
                Customer Invoice
              </h1>
              <p className="mt-1 text-sm font-medium text-gray-700 dark:text-dark-200">
                {status === "draft" ? "Draft" : "Posted"}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setStatus("draft")}
              className={`rounded-full px-4 py-2 text-sm font-medium transition-colors ${
                status === "draft"
                  ? "bg-purple-600 text-white"
                  : "bg-gray-100 text-gray-600 dark:bg-dark-600 dark:text-dark-300"
              }`}
            >
              Draft
            </button>
            <button
              onClick={() => setStatus("posted")}
              className={`rounded-full px-4 py-2 text-sm font-medium transition-colors ${
                status === "posted"
                  ? "bg-purple-600 text-white"
                  : "bg-gray-100 text-gray-600 dark:bg-dark-600 dark:text-dark-300"
              }`}
            >
              Posted
            </button>
          </div>
        </div>
      </div>

      {/* Form Content */}
      <form onSubmit={handleSubmit(onSubmit)} className="flex-1 overflow-auto">
        <div className="mx-auto max-w-7xl px-6 py-6">
          {/* Error Message */}
          {error && (
            <div className="mb-4 rounded-lg border border-red-300 bg-red-50 p-4 text-red-800 dark:border-red-700 dark:bg-red-900/20 dark:text-red-400">
              <div className="flex items-center justify-between">
                <span>{error}</span>
                <button
                  type="button"
                  onClick={() => setError(null)}
                  className="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-200"
                >
                  ×
                </button>
              </div>
            </div>
          )}
          {/* Customer & Date Fields */}
          <div className="mb-6 grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
            <div>
              <Input
                label="Customer"
                placeholder="Search a name or Tax ID..."
                {...register("partner_id")}
                error={errors.partner_id?.message}
                suffix={<ChevronDownIcon className="w-4" />}
              />
            </div>
            <div>
              <DatePicker
                label="Invoice Date"
                defaultValue={dayjs().format("YYYY-MM-DD")}
                onChange={(_selectedDates, dateStr) => {
                  if (dateStr) {
                    setValue("invoice_date", dateStr);
                  }
                }}
                error={errors.invoice_date?.message}
                options={{
                  defaultDate: dayjs().toDate(),
                  dateFormat: "Y-m-d",
                }}
              />
            </div>
            <div>
              <DatePicker
                label="Due Date"
                defaultValue={dayjs().add(30, "day").format("YYYY-MM-DD")}
                onChange={(_selectedDates, dateStr) => {
                  if (dateStr) {
                    setValue("invoice_date_due", dateStr);
                  }
                }}
                error={errors.invoice_date_due?.message}
                options={{
                  defaultDate: dayjs().add(30, "day").toDate(),
                  dateFormat: "Y-m-d",
                }}
              />
            </div>
            <div>
              <Input
                label="Payment Terms"
                placeholder="or"
                {...register("invoice_payment_term_id")}
                error={errors.invoice_payment_term_id?.message}
              />
            </div>
          </div>

          {/* Invoice Lines Tabs */}
          <div className="mb-4 border-b border-gray-200 dark:border-dark-500">
            <div className="flex gap-6">
              <button
                type="button"
                className="border-b-2 border-purple-600 px-1 pb-2 text-sm font-medium text-purple-600"
              >
                Invoice Lines
              </button>
              <button
                type="button"
                className="px-1 pb-2 text-sm font-medium text-gray-500 hover:text-gray-700 dark:text-dark-400 dark:hover:text-dark-200"
              >
                Other Info
              </button>
            </div>
          </div>

          {/* Invoice Lines Table */}
          <div className="mb-6">
            <div className="overflow-x-auto rounded-lg border border-gray-200 dark:border-dark-500">
              <Table>
                <THead>
                  <Tr>
                    <Th className="bg-gray-50 dark:bg-dark-800">Product</Th>
                    <Th className="bg-gray-50 dark:bg-dark-800">Quantity</Th>
                    <Th className="bg-gray-50 dark:bg-dark-800">Price Taxes</Th>
                    <Th className="bg-gray-50 dark:bg-dark-800">
                      Amount
                      <button type="button" className="ml-2">
                        <svg
                          className="h-4 w-4"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M3 4h13M3 8h9m-9 4h6m4 0l4-4m0 0l4 4m-4-4v12"
                          />
                        </svg>
                      </button>
                    </Th>
                  </Tr>
                </THead>
                <TBody>
                  {fields.length === 0 ? (
                    <Tr>
                      <Td colSpan={4} className="py-8 text-center text-gray-500">
                        No invoice lines. Click "Add a line" to add items.
                      </Td>
                    </Tr>
                  ) : (
                    fields.map((field, index) => {
                      const line = invoiceLines[index];
                      const isSection = line?.display_type === "line_section";
                      const isNote = line?.display_type === "line_note";

                      if (isSection || isNote) {
                        return (
                          <Tr key={field.id}>
                            <Td colSpan={4} className="bg-gray-50 dark:bg-dark-800">
                              <Input
                                {...register(`invoice_lines.${index}.name`)}
                                className="border-0 bg-transparent font-semibold"
                                onBlur={() => updateLineAmount(index)}
                              />
                            </Td>
                          </Tr>
                        );
                      }

                      return (
                        <Tr key={field.id}>
                          <Td>
                            <Input
                              {...register(`invoice_lines.${index}.name`)}
                              placeholder="Product"
                              onBlur={() => updateLineAmount(index)}
                            />
                          </Td>
                          <Td>
                            <Input
                              type="number"
                              step="0.01"
                              {...register(`invoice_lines.${index}.quantity`, {
                                valueAsNumber: true,
                              })}
                              onBlur={() => updateLineAmount(index)}
                            />
                          </Td>
                          <Td>
                            <Input
                              type="number"
                              step="0.01"
                              {...register(`invoice_lines.${index}.price_unit`, {
                                valueAsNumber: true,
                              })}
                              onBlur={() => updateLineAmount(index)}
                            />
                          </Td>
                          <Td>
                            <div className="flex items-center gap-2">
                              <Input
                                type="number"
                                step="0.01"
                                {...register(`invoice_lines.${index}.amount`, {
                                  valueAsNumber: true,
                                })}
                                readOnly
                                className="flex-1"
                              />
                              <button
                                type="button"
                                onClick={() => remove(index)}
                                className="text-red-600 hover:text-red-700"
                              >
                                ×
                              </button>
                            </div>
                          </Td>
                        </Tr>
                      );
                    })
                  )}
                </TBody>
              </Table>
            </div>

            {/* Actions */}
            <div className="mt-2 flex gap-2">
              <Button
                type="button"
                variant="flat"
                onClick={handleAddLine}
                className="text-sm"
              >
                Add a line
              </Button>
              <Button
                type="button"
                variant="flat"
                onClick={handleAddSection}
                className="text-sm"
              >
                Add a section
              </Button>
              <Button
                type="button"
                variant="flat"
                onClick={handleAddNote}
                className="text-sm"
              >
                Add a note
              </Button>
              <Button
                type="button"
                variant="flat"
                className="text-sm"
              >
                Catalog
              </Button>
            </div>
          </div>

          {/* Footer */}
          <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
            {/* Terms and Conditions */}
            <div>
              <Textarea
                label="Terms and Conditions"
                rows={4}
                {...register("narration")}
                error={errors.narration?.message}
                placeholder="Terms and Conditions"
              />
            </div>

            {/* Totals */}
            <div className="flex flex-col justify-end">
              <div className="space-y-2 rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-dark-500 dark:bg-dark-800">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600 dark:text-dark-300">
                    Untaxed Amount:
                  </span>
                  <span className="font-medium text-gray-900 dark:text-dark-50">
                    $ {totals.untaxed.toFixed(2)}
                  </span>
                </div>
                <div className="flex justify-between text-lg font-bold">
                  <span className="text-gray-900 dark:text-dark-50">Total:</span>
                  <span className="text-gray-900 dark:text-dark-50">
                    $ {totals.total.toFixed(2)}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600 dark:text-dark-300">
                    Amount Due:
                  </span>
                  <span className="font-medium text-gray-900 dark:text-dark-50">
                    $ {totals.amountDue.toFixed(2)}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}

