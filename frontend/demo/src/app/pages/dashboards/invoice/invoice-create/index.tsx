// Import Dependencies
import { useState, useMemo, useEffect, useCallback } from "react";
import { useForm, useFieldArray } from "react-hook-form";
import * as yup from "yup";
import { yupResolver } from "@hookform/resolvers/yup";
import { useNavigate, useSearchParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import axiosInstance from "@/utils/axios";
import dayjs from "dayjs";

// Local Imports
import { Page } from "@/components/shared/Page";
import { Input, Button, Textarea, Card } from "@/components/ui";
import DynamicForm, { type DynamicFieldConfig } from "@/components/shared/DynamicForm";
import {
  Table,
  THead,
  TBody,
  Th,
  Tr,
  Td,
} from "@/components/ui";

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
  tax_rate?: number; // Thuế suất (%)
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

interface ContactLite {
  id: string;
  display_name?: string | null;
  name?: string | null;
  email?: string | null;
  phone?: string | null;
  [k: string]: unknown;
}

interface InvoiceDto {
  id: string;
  partner_id?: string | null;
  invoice_date?: string | null;
  invoice_date_due?: string | null;
  invoice_payment_term_id?: string | null;
  narration?: string | null;
  state?: string;
  invoice_lines?: InvoiceLineDto[];
  [k: string]: unknown;
}

interface InvoiceLineDto {
  id?: string;
  product_id?: string | null;
  product_name?: string | null;
  name?: string | null;
  quantity?: number | string | null;
  price_unit?: number | string | null;
  discount?: number | string | null;
  tax_ids?: string[] | null;
  display_type?: string | null;
  [k: string]: unknown;
}

interface FormFieldDef {
  name: string;
  label?: string;
  type?: string;
  width?: number;
  disabled?: boolean;
  required?: boolean;
  options?: Array<{ label?: string; value: string | number }>;
  [k: string]: unknown;
}

interface MetadataDto {
  form?: { fields?: FormFieldDef[] };
  invoiceLines?: { fields?: FormFieldDef[] };
  [k: string]: unknown;
}

/* ====================== Chuẩn hoá metadata -> đúng type ====================== */

// FormFieldDef -> DynamicFieldConfig (label luôn là string)
const normalizeDynamicFields = (fields?: FormFieldDef[]): DynamicFieldConfig[] => {
  if (!fields) return [];
  return fields.map((f) => {
    const hasOptions = Array.isArray(f.options);
    return {
      ...f,
      label: f.label ?? "",
      type: (f.type as any) ?? "text",
      ...(hasOptions
        ? {
            options: f.options!.map((o) => ({
              label: o?.label ?? String(o?.value ?? ""),
              value: o?.value,
            })),
          }
        : {}),
    } as DynamicFieldConfig;
  });
};

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
      tax_rate: yup.number().min(0).max(100).optional(),
      amount: yup.number().optional(),
      display_type: yup.string().optional(),
    })
  ),
}) as yup.ObjectSchema<InvoiceFormData>;

// ----------------------------------------------------------------------

export default function InvoiceCreate() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const invoiceId = searchParams.get("id");
  const { i18n } = useTranslation(); // Get i18n instance to listen to language changes
  const [status, setStatus] = useState<"draft" | "posted">("draft");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isEditing, setIsEditing] = useState<boolean>(!invoiceId);
  const [contacts, setContacts] = useState<ContactLite[]>([]);
  const [isLoadingInvoice, setIsLoadingInvoice] = useState<boolean>(!!invoiceId);
  const [metadata, setMetadata] = useState<MetadataDto | null>(null);

  const form = useForm<InvoiceFormData>({
    resolver: yupResolver(schema),
    defaultValues: {
      invoice_date: dayjs().format("YYYY-MM-DD"),
      invoice_date_due: dayjs().add(30, "day").format("YYYY-MM-DD"),
      invoice_lines: [],
    },
  });

  const { register, handleSubmit, control, watch, setValue, formState: { errors } } = form;

  const { fields, append, remove, update, replace } = useFieldArray({
    control,
    name: "invoice_lines",
  });

  const invoiceLines = watch("invoice_lines");

  // ✅ giữ ổn định header để tránh loop useEffect
  const token = (typeof window !== "undefined" && localStorage.getItem("authToken")) || "";
  const authHeader = useMemo<undefined | Record<string, string>>(
    () => (token ? { Authorization: `Bearer ${token}` } : undefined),
    [token]
  );

  const fetchMetadata = useCallback(async () => {
    try {
      const res = await axiosInstance.get<MetadataDto>("/invoice/metadata");
      setMetadata(res.data);
    } catch (err) {
      console.error("❌ Lỗi load metadata:", err);
    }
  }, []);

  // ✅ Tạo danh sách fields đã chỉnh sửa: (chuẩn hoá -> chèn field nếu cần)
  const adjustedFields = useMemo<DynamicFieldConfig[]>(() => {
    if (!metadata?.form?.fields) return [];
    // chuẩn hoá trước để label luôn là string
    return normalizeDynamicFields(metadata.form.fields);
  }, [metadata]);

  // Fetch contacts
  const fetchContacts = useCallback(async () => {
    try {
      const res = await axiosInstance.get<ContactLite[]>("/contact/list", {
        headers: authHeader,
      });
      setContacts(res.data || []);
    } catch (err) {
      console.error("❌ Lỗi load contacts:", err);
    }
  }, [authHeader]);

  useEffect(() => {
    fetchMetadata();
    fetchContacts();
  }, [fetchMetadata, fetchContacts]);

  // Refetch metadata when language changes
  useEffect(() => {
    fetchMetadata();
  }, [i18n.language, fetchMetadata]);

  // Fetch invoice data when invoiceId exists
  const fetchInvoice = useCallback(async () => {
    if (!invoiceId) return;
    
    try {
      setIsLoadingInvoice(true);
      const res = await axiosInstance.get<InvoiceDto>(`/invoice/${invoiceId}`, {
        headers: authHeader,
      });
      
      const invoice = res.data;
      
      // Set status from invoice state
      if (invoice.state) {
        if (invoice.state === "posted") {
          setStatus("posted");
        } else {
          setStatus("draft");
        }
      }
      
      // Load invoice data into form
      if (invoice.partner_id) {
        setValue("partner_id", invoice.partner_id);
      }
      if (invoice.invoice_date) {
        setValue("invoice_date", invoice.invoice_date);
      }
      if (invoice.invoice_date_due) {
        setValue("invoice_date_due", invoice.invoice_date_due);
      }
      if (invoice.invoice_payment_term_id) {
        setValue("invoice_payment_term_id", invoice.invoice_payment_term_id);
      }
      if (invoice.narration) {
        setValue("narration", invoice.narration);
      }
      
      // Load invoice lines
      if (invoice.invoice_lines && invoice.invoice_lines.length > 0) {
        const lines: InvoiceLine[] = invoice.invoice_lines.map((line) => {
          const displayType = line.display_type === "line_section" || line.display_type === "line_note" 
            ? line.display_type as "line_section" | "line_note"
            : null;
          
          // Calculate tax_rate from tax data if available, otherwise default to 0
          // TODO: Calculate actual tax_rate from tax_ids if tax data is available
          const taxRate = 0; // Default, can be calculated from tax data later
          
          return {
            id: line.id,
            product_id: line.product_id || undefined,
            product_name: line.product_name || undefined,
            name: line.name || undefined,
            quantity: typeof line.quantity === "string" ? parseFloat(line.quantity) : (line.quantity || 0),
            price_unit: typeof line.price_unit === "string" ? parseFloat(line.price_unit) : (line.price_unit || 0),
            discount: typeof line.discount === "string" ? parseFloat(line.discount) : (line.discount || 0),
            tax_rate: taxRate,
            tax_ids: line.tax_ids || [],
            display_type: displayType,
            amount: 0, // Will be calculated
          };
        });
        
        // Calculate amounts for each line
        lines.forEach((line) => {
          if (!line.display_type) {
            const qty = line.quantity || 0;
            const price = line.price_unit || 0;
            const discount = line.discount || 0;
            const taxRate = line.tax_rate || 0;
            const subtotal = qty * price * (1 - discount / 100);
            const taxAmount = subtotal * (taxRate / 100);
            line.amount = subtotal + taxAmount;
          }
        });
        
        replace(lines);
      }
    } catch (err) {
      console.error("❌ Lỗi load invoice:", err);
      setError("Không thể tải dữ liệu hóa đơn");
    } finally {
      setIsLoadingInvoice(false);
    }
  }, [invoiceId, setValue, replace, authHeader]);

  useEffect(() => {
    fetchInvoice();
  }, [fetchInvoice]);

  // Map contacts to select options
  const contactOptions = useMemo(() => {
    const options = contacts.map((contact) => ({
      value: contact.id,
      label: contact.display_name || contact.name || contact.email || contact.phone || contact.id,
    }));
    // Add empty option at the beginning
    return [{ value: "", label: "-- Chọn khách hàng --" }, ...options];
  }, [contacts]);

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
      const taxRate = line.tax_rate || 0;
      const subtotal = qty * price * (1 - discount / 100);
      untaxed += subtotal;
      const taxAmount = subtotal * (taxRate / 100);
      tax += taxAmount;
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
      tax_rate: 0,
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
    const taxRate = line.tax_rate || 0;
    const subtotal = qty * price * (1 - discount / 100);
    const taxAmount = subtotal * (taxRate / 100);
    const amount = subtotal + taxAmount;
    
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
          tax_rate: line.tax_rate || 0, // Gửi tax_rate lên backend
          tax_ids: line.tax_ids || [],
        })),
        date: data.invoice_date,
        journal_id: "00000000-0000-0000-0000-000000000000", // nil UUID - backend will auto-create
        currency_id: "00000000-0000-0000-0000-000000000000", // nil UUID - backend will use default
      };

      console.log("Invoice payload:", payload);

      if (invoiceId) {
        // Update existing invoice (without invoice_lines - they need to be updated separately)
        const updatePayload = {
          partner_id: data.partner_id || null,
          invoice_date: data.invoice_date,
          invoice_date_due: data.invoice_date_due,
          invoice_payment_term_id: data.invoice_payment_term_id || null,
          narration: data.narration || null,
          date: data.invoice_date,
        };
        await axiosInstance.put(`/invoice/${invoiceId}/update`, updatePayload);
        console.log("Invoice updated successfully");
        
        // TODO: Update invoice lines separately if needed
        // For now, invoice lines are not updated through this form

        // If status is posted, confirm the invoice
        if (status === "posted") {
          try {
            await axiosInstance.post(`/invoice/${invoiceId}/confirm`);
            console.log("Invoice confirmed successfully");
          } catch (confirmError: any) {
            console.error("Error confirming invoice:", confirmError);
            setError(`Hóa đơn đã được cập nhật nhưng không thể xác nhận: ${confirmError?.response?.data?.message || confirmError.message}`);
            setIsSubmitting(false);
            return;
          }
        }

        // Refresh invoice data
        await fetchInvoice();
        setIsEditing(false);
      } else {
        // Create new invoice
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
      }
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

  const handleCancel = () => {
    setIsEditing(false);
    // TODO: Reload invoice data if editing
  };

  return (
    <Page title={invoiceId ? "✏️ Chi tiết hóa đơn" : "Tạo hóa đơn mới"}>
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-2">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              {invoiceId ? "Chi tiết hóa đơn" : "Tạo hóa đơn mới"}
            </h2>
            {isLoadingInvoice && (
              <span className="text-xs text-gray-400">Đang tải dữ liệu...</span>
            )}
            <div className="flex items-center gap-2">
              <button
                onClick={() => setStatus("draft")}
                className={`rounded-full px-3 py-1 text-xs font-medium transition-colors ${
                  status === "draft"
                    ? "bg-primary-500 text-white"
                    : "bg-gray-100 text-gray-600 dark:bg-dark-600 dark:text-dark-300"
                }`}
              >
                Draft
              </button>
              <button
                onClick={() => setStatus("posted")}
                className={`rounded-full px-3 py-1 text-xs font-medium transition-colors ${
                  status === "posted"
                    ? "bg-primary-500 text-white"
                    : "bg-gray-100 text-gray-600 dark:bg-dark-600 dark:text-dark-300"
                }`}
              >
                Posted
              </button>
            </div>
          </div>
          <div className="flex gap-2">
            {invoiceId && !isEditing && (
              <Button className="min-w-[7rem]" onClick={() => setIsEditing(true)}>
                Chỉnh sửa
              </Button>
            )}
            {isEditing && (
              <>
                <Button
                  className="min-w-[7rem]"
                  variant="outlined"
                  onClick={handleCancel}
                  disabled={isSubmitting}
                >
                  Hủy
                </Button>
                <Button
                  className="min-w-[7rem]"
                  color="primary"
                  type="button"
                  onClick={handleSave}
                  disabled={isSubmitting}
                >
                  {isSubmitting ? "Đang lưu..." : "Lưu"}
                </Button>
                <Button
                  className="min-w-[7rem]"
                  color="primary"
                  type="button"
                  onClick={handleConfirm}
                  disabled={isSubmitting}
                >
                  {isSubmitting ? "Đang xử lý..." : "Xác nhận"}
                </Button>
              </>
            )}
          </div>
        </div>

        <form autoComplete="off" onSubmit={handleSubmit(onSubmit)} id="invoice-form">
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

          <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
            <div className="col-span-12 lg:col-span-8">
              <Card className="p-4 sm:px-5">
                <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Thông tin hóa đơn
                </h3>

                <div className="mt-5 space-y-5">
                  <DynamicForm
                    form={form}
                    fields={adjustedFields}
                    optionsMap={{
                      partner_id: contactOptions,
                    }}
                    disabled={!isEditing}
                  />

                  {/* Invoice Lines Table */}
                  <div>
                    <div className="overflow-x-auto rounded-lg border border-gray-200 dark:border-dark-500">
                      <Table>
                        <THead>
                          <Tr>
                            <Th className="bg-gray-50 dark:bg-dark-800">Tên sản phẩm</Th>
                            <Th className="bg-gray-50 dark:bg-dark-800">Số lượng</Th>
                            <Th className="bg-gray-50 dark:bg-dark-800">Đơn giá</Th>
                            <Th className="bg-gray-50 dark:bg-dark-800">Thuế (%)</Th>
                            <Th className="bg-gray-50 dark:bg-dark-800">Thành tiền</Th>
                          </Tr>
                        </THead>
                        <TBody>
                          {fields.length === 0 ? (
                            <Tr>
                              <Td colSpan={5} className="py-8 text-center text-gray-500">
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
                                    <Td colSpan={5} className="bg-gray-50 dark:bg-dark-800">
                                      <Input
                                        {...register(`invoice_lines.${index}.name`)}
                                        className="border-0 bg-transparent font-semibold"
                                        onBlur={() => updateLineAmount(index)}
                                        disabled={!isEditing}
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
                                      placeholder="Tên sản phẩm"
                                      onBlur={() => updateLineAmount(index)}
                                      disabled={!isEditing}
                                    />
                                  </Td>
                                  <Td>
                                    <Input
                                      type="number"
                                      step="0.01"
                                      {...register(`invoice_lines.${index}.quantity`, {
                                        valueAsNumber: true,
                                      })}
                                      placeholder="Số lượng"
                                      onBlur={() => updateLineAmount(index)}
                                      disabled={!isEditing}
                                    />
                                  </Td>
                                  <Td>
                                    <Input
                                      type="number"
                                      step="0.01"
                                      {...register(`invoice_lines.${index}.price_unit`, {
                                        valueAsNumber: true,
                                      })}
                                      placeholder="Đơn giá"
                                      onBlur={() => updateLineAmount(index)}
                                      disabled={!isEditing}
                                    />
                                  </Td>
                                  <Td>
                                    <Input
                                      type="number"
                                      step="0.01"
                                      {...register(`invoice_lines.${index}.tax_rate`, {
                                        valueAsNumber: true,
                                      })}
                                      placeholder="Thuế (%)"
                                      onBlur={() => updateLineAmount(index)}
                                      disabled={!isEditing}
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
                                        placeholder="Thành tiền"
                                        disabled={!isEditing}
                                      />
                                      {isEditing && (
                                        <button
                                          type="button"
                                          onClick={() => remove(index)}
                                          className="text-red-600 hover:text-red-700"
                                        >
                                          ×
                                        </button>
                                      )}
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
                    {isEditing && (
                      <div className="flex gap-2">
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
                    )}

                    {/* Terms and Conditions */}
                    <div>
                      <Textarea
                        label="Terms and Conditions"
                        rows={4}
                        {...register("narration")}
                        error={errors.narration?.message}
                        placeholder="Terms and Conditions"
                        disabled={!isEditing}
                      />
                    </div>
                  </div>
                </div>
              </Card>
            </div>

            <div className="col-span-12 lg:col-span-4 space-y-4 sm:space-y-5 lg:space-y-6">
              <Card className="p-4 sm:px-5">
                <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Tổng kết
                </h6>
                <div className="mt-3 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600 dark:text-dark-300">
                      Untaxed Amount:
                    </span>
                    <span className="font-medium text-gray-900 dark:text-dark-50">
                      {new Intl.NumberFormat("vi-VN").format(totals.untaxed)}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600 dark:text-dark-300">
                      Tax:
                    </span>
                    <span className="font-medium text-gray-900 dark:text-dark-50">
                      {new Intl.NumberFormat("vi-VN").format(totals.tax)}
                    </span>
                  </div>
                  <div className="flex justify-between text-lg font-bold border-t border-gray-200 dark:border-dark-500 pt-2">
                    <span className="text-gray-900 dark:text-dark-50">Total:</span>
                    <span className="text-gray-900 dark:text-dark-50">
                      {new Intl.NumberFormat("vi-VN").format(totals.total)}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600 dark:text-dark-300">
                      Amount Due:
                    </span>
                    <span className="font-medium text-gray-900 dark:text-dark-50">
                      {new Intl.NumberFormat("vi-VN").format(totals.amountDue)}
                    </span>
                  </div>
                </div>
              </Card>

              <Card className="p-4 sm:px-5">
                <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Thông tin khác
                </h6>
                <div className="mt-3 text-sm text-gray-600 dark:text-dark-50 space-y-2">
                  <div>
                    <span className="opacity-70">Trạng thái:&nbsp;</span>
                    {status === "draft" ? "Draft" : "Posted"}
                  </div>
                </div>
              </Card>
            </div>
          </div>
        </form>
      </div>
    </Page>
  );
}

