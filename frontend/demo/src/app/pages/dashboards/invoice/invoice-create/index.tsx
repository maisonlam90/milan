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
import { Button, Textarea, Card } from "@/components/ui";
import DynamicForm, { type DynamicFieldConfig } from "@/components/shared/DynamicForm";
import Notebook, { type NotebookColumn } from "@/components/shared/Notebook";

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
  tax_rate?: number | string | null; // Tax rate (%) - calculated from backend
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
  notebook?: { fields?: FormFieldDef[] };
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

// FormFieldDef -> NotebookColumn tương thích (label luôn là string)
const normalizeNotebookColumns = (fields?: FormFieldDef[]): NotebookColumn[] => {
  if (!fields) return [];
  return fields.map((f) => {
    const hasOptions = Array.isArray(f.options);
    return {
      name: f.name,
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
    } as NotebookColumn;
  });
};

// Validation Schema
const schema = yup.object({
  partner_id: yup.string().nullable().optional(),
  invoice_date: yup.string().required("Invoice Date is required"),
  invoice_date_due: yup.string().nullable().optional(),
  invoice_payment_term_id: yup.string().nullable().optional(),
  narration: yup.string().nullable().optional(),
  invoice_lines: yup.array().of(
    yup.object().shape({
      id: yup.string().optional(),
      product_id: yup.string().nullable().optional(),
      product_name: yup.string().optional(),
      name: yup.string().nullable().optional(),
      quantity: yup.number()
        .transform((value, originalValue) => {
          if (originalValue === '' || originalValue === null || originalValue === undefined) return undefined;
          const num = Number(value);
          return isNaN(num) ? undefined : num;
        })
        .nullable()
        .optional()
        .test('min', 'Quantity must be >= 0', (value) => {
          return value === undefined || value === null || value >= 0;
        }),
      price_unit: yup.number()
        .transform((value, originalValue) => {
          if (originalValue === '' || originalValue === null || originalValue === undefined) return undefined;
          const num = Number(value);
          return isNaN(num) ? undefined : num;
        })
        .nullable()
        .optional()
        .test('min', 'Price unit must be >= 0', (value) => {
          return value === undefined || value === null || value >= 0;
        }),
      discount: yup.number()
        .transform((value, originalValue) => {
          if (originalValue === '' || originalValue === null || originalValue === undefined) return undefined;
          const num = Number(value);
          return isNaN(num) ? undefined : num;
        })
        .nullable()
        .optional()
        .test('range', 'Discount must be between 0 and 100', (value) => {
          return value === undefined || value === null || (value >= 0 && value <= 100);
        }),
      tax_rate: yup.number()
        .transform((value, originalValue) => {
          if (originalValue === '' || originalValue === null || originalValue === undefined) return undefined;
          const num = Number(value);
          return isNaN(num) ? undefined : num;
        })
        .nullable()
        .optional()
        .test('range', 'Tax rate must be between 0 and 100', (value) => {
          return value === undefined || value === null || (value >= 0 && value <= 100);
        }),
      tax_ids: yup.array().of(yup.string()).optional(),
      amount: yup.number()
        .transform((value, originalValue) => {
          if (originalValue === '' || originalValue === null || originalValue === undefined) return undefined;
          return isNaN(value) ? undefined : value;
        })
        .nullable()
        .optional(),
      display_type: yup.string().nullable().optional(),
    })
  ).optional(),
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
  const [isSendingEInvoice, setIsSendingEInvoice] = useState(false);
  const [eInvoiceMessage, setEInvoiceMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null);

  const form = useForm<InvoiceFormData>({
    resolver: yupResolver(schema),
    defaultValues: {
      invoice_date: "",
      invoice_date_due: "",
      invoice_lines: [],
    },
  });

  const { register, control, watch, setValue, handleSubmit, formState: { errors } } = form;

  const { update } = useFieldArray({
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

  // ✅ Tạo danh sách notebook columns từ metadata
  const notebookColumns = useMemo<NotebookColumn[]>(() => {
    // Ưu tiên notebook, nếu không có thì dùng invoiceLines
    const fields = metadata?.notebook?.fields || metadata?.invoiceLines?.fields;
    return normalizeNotebookColumns(fields);
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
      
      // Prepare invoice lines data
      let invoiceLinesData: InvoiceLine[] = [];
      if (invoice.invoice_lines && invoice.invoice_lines.length > 0) {
        invoiceLinesData = invoice.invoice_lines.map((line) => {
          const displayType = line.display_type === "line_section" || line.display_type === "line_note" 
            ? line.display_type as "line_section" | "line_note"
            : null;
          
          // Get tax_rate from backend (calculated from tax_amount and price_subtotal)
          const taxRate = line.tax_rate 
            ? (typeof line.tax_rate === "string" ? parseFloat(line.tax_rate) : (line.tax_rate || 0))
            : 0;
          
          const qty = typeof line.quantity === "string" ? parseFloat(line.quantity) : (line.quantity || 0);
          const price = typeof line.price_unit === "string" ? parseFloat(line.price_unit) : (line.price_unit || 0);
          const discount = typeof line.discount === "string" ? parseFloat(line.discount) : (line.discount || 0);
          
          // Calculate amount
          let amount = 0;
          if (!displayType) {
            const subtotal = qty * price * (1 - discount / 100);
            const taxAmount = subtotal * (taxRate / 100);
            amount = subtotal + taxAmount;
          }
          
          return {
            id: line.id,
            product_id: line.product_id || undefined,
            product_name: line.product_name || undefined,
            name: line.name || undefined,
            quantity: qty,
            price_unit: price,
            discount: discount,
            tax_rate: taxRate,
            tax_ids: line.tax_ids || [],
            display_type: displayType,
            amount: amount,
          };
        });
      }
      
      // Prepare form data with converted dates
      const formData: InvoiceFormData = {
        partner_id: invoice.partner_id || undefined,
        invoice_date: invoice.invoice_date 
          ? (dayjs(invoice.invoice_date).isValid() 
              ? dayjs(invoice.invoice_date).toISOString()
              : invoice.invoice_date)
          : "",
        invoice_date_due: invoice.invoice_date_due
          ? (dayjs(invoice.invoice_date_due).isValid()
              ? dayjs(invoice.invoice_date_due).toISOString()
              : invoice.invoice_date_due)
          : "",
        invoice_payment_term_id: invoice.invoice_payment_term_id || undefined,
        narration: invoice.narration || undefined,
        invoice_lines: invoiceLinesData,
      };
      
      // Reset form with all data (similar to loan module)
      form.reset(formData);
    } catch (err) {
      console.error("❌ Lỗi load invoice:", err);
      setError("Không thể tải dữ liệu hóa đơn");
    } finally {
      setIsLoadingInvoice(false);
    }
  }, [invoiceId, form, authHeader]);

  useEffect(() => {
    fetchInvoice();
  }, [fetchInvoice]);

  // ✅ Đảm bảo invoice_date là empty string khi tạo mới (không có invoiceId)
  useEffect(() => {
    if (!invoiceId && !isLoadingInvoice) {
      const currentValue = watch("invoice_date");
      // Nếu có giá trị, reset về empty string
      if (currentValue && currentValue !== "") {
        setValue("invoice_date", "", { shouldValidate: false, shouldDirty: false });
      }
    }
  }, [invoiceId, isLoadingInvoice, setValue, watch]);


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


  // ✅ Tự động tính amount khi quantity, price_unit, discount, tax_rate thay đổi
  useEffect(() => {
    const subscription = form.watch((value, { name }) => {
      // Chỉ xử lý khi có thay đổi trong invoice_lines
      if (name && name.startsWith("invoice_lines")) {
        const lines = value.invoice_lines as InvoiceLine[] || [];
        
        lines.forEach((line, index) => {
          if (line.display_type) return; // Skip section/note lines

          const qty = typeof line.quantity === "number" ? line.quantity : (parseFloat(String(line.quantity || 0)) || 0);
          const price = typeof line.price_unit === "number" ? line.price_unit : (parseFloat(String(line.price_unit || 0)) || 0);
          const discount = typeof line.discount === "number" ? line.discount : (parseFloat(String(line.discount || 0)) || 0);
          const taxRate = typeof line.tax_rate === "number" ? line.tax_rate : (parseFloat(String(line.tax_rate || 0)) || 0);
          
          const subtotal = qty * price * (1 - discount / 100);
          const taxAmount = subtotal * (taxRate / 100);
          const amount = subtotal + taxAmount;

          // Chỉ update nếu amount khác với giá trị hiện tại (tránh loop vô hạn)
          const currentAmount = typeof line.amount === "number" ? line.amount : (parseFloat(String(line.amount || 0)) || 0);
          if (Math.abs(currentAmount - amount) > 0.01) { // Cho phép sai số nhỏ do floating point
            update(index, { ...line, amount });
          }
        });
      }
    });
    
    return () => subscription.unsubscribe();
  }, [form, update]);

  // Helper function to normalize date format from ISO string to YYYY-MM-DD
  const normalizeDate = (dateValue: string | undefined | null): string => {
    if (!dateValue || dateValue.trim() === "") {
      return dayjs().format("YYYY-MM-DD");
    }
    
    // If it's already in YYYY-MM-DD format, return as is
    if (/^\d{4}-\d{2}-\d{2}$/.test(dateValue)) {
      return dateValue;
    }
    
    // If it's an ISO string, extract just the date part
    const isoMatch = dateValue.match(/^(\d{4}-\d{2}-\d{2})/);
    if (isoMatch) {
      return isoMatch[1];
    }
    
    // Try parsing with dayjs and format to YYYY-MM-DD
    const parsed = dayjs(dateValue);
    if (parsed.isValid()) {
      return parsed.format("YYYY-MM-DD");
    }
    
    // Fallback to today
    return dayjs().format("YYYY-MM-DD");
  };

  // Handle form submission
  const onSubmit = async (data: InvoiceFormData) => {
    setIsSubmitting(true);
    setError(null);
    
    // Use current status state
    const currentStatus = status;
    console.log("Submitting invoice data:", data, "with status:", currentStatus);
    
    try {
      // Validate that we have at least one invoice line
      const validLines = data.invoice_lines.filter((line) => !line.display_type);
      if (validLines.length === 0) {
        setError("Vui lòng thêm ít nhất một dòng sản phẩm vào hóa đơn");
        setIsSubmitting(false);
        return;
      }

      // Create invoice payload
      // Backend will auto-create journal if not provided (nil UUID)
      // Normalize invoice_date to YYYY-MM-DD format (handle ISO strings)
      const invoiceDate = normalizeDate(data.invoice_date);
      const invoiceDateDue = data.invoice_date_due ? normalizeDate(data.invoice_date_due) : null;
      const payload = {
        move_type: "out_invoice",
        partner_id: data.partner_id || null,
        invoice_date: invoiceDate,
        invoice_date_due: invoiceDateDue,
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
        date: invoiceDate,
        journal_id: "00000000-0000-0000-0000-000000000000", // nil UUID - backend will auto-create
        currency_id: "00000000-0000-0000-0000-000000000000", // nil UUID - backend will use default
      };

      console.log("Invoice payload:", payload);

      if (invoiceId) {
        // Update existing invoice with invoice lines (include all lines: products, sections, notes)
        // Normalize invoice_date to YYYY-MM-DD format (handle ISO strings)
        const invoiceDate = normalizeDate(data.invoice_date);
        const invoiceDateDue = data.invoice_date_due ? normalizeDate(data.invoice_date_due) : null;
        const updatePayload = {
          partner_id: data.partner_id || null,
          invoice_date: invoiceDate,
          invoice_date_due: invoiceDateDue,
          invoice_payment_term_id: data.invoice_payment_term_id || null,
          narration: data.narration || null,
          date: invoiceDate,
          invoice_lines: data.invoice_lines.map((line) => ({
            ...(line.id ? { id: line.id } : {}), // Include ID only if line already exists
            product_id: line.product_id || null,
            name: line.name || "",
            quantity: line.quantity || 0,
            price_unit: line.price_unit || 0,
            discount: line.discount || 0,
            tax_rate: line.tax_rate || 0,
            tax_ids: line.tax_ids || [],
            display_type: line.display_type || null,
          })),
        };
        console.log("Update payload:", updatePayload);
        console.log("Sending PUT request to:", `/invoice/${invoiceId}/update`);
        try {
          const response = await axiosInstance.put(`/invoice/${invoiceId}/update`, updatePayload);
          console.log("Invoice updated successfully, response:", response);
        } catch (updateError: any) {
          console.error("Error updating invoice:", updateError);
          console.error("Error response:", updateError?.response);
          throw updateError;
        }

        // If status is posted, confirm the invoice
        if (currentStatus === "posted") {
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
        if (currentStatus === "posted") {
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
      console.error("Error saving invoice:", error);
      console.error("Error response:", error?.response?.data);
      const errorMessage = error?.response?.data?.message || error?.response?.data?.error || error?.message || "Có lỗi xảy ra khi lưu hóa đơn";
      setError(errorMessage);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle save (draft) - set status and submit form
  const handleSave = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setStatus("draft");
    // Trigger form submit - status will be used in onSubmit
    handleSubmit(onSubmit)();
  };

  // Handle confirm (post) - set status and submit form
  const handleConfirm = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setStatus("posted");
    // Trigger form submit - status will be used in onSubmit
    handleSubmit(onSubmit)();
  };

  const handleCancel = () => {
    setIsEditing(false);
    // TODO: Reload invoice data if editing
  };

  // Handle creating e-invoice
  const handleCreateEInvoice = async () => {
    if (!invoiceId) {
      setEInvoiceMessage({ 
        type: 'error', 
        text: 'Vui lòng lưu hóa đơn trước khi tạo hóa đơn điện tử' 
      });
      return;
    }

    setIsSendingEInvoice(true);
    setEInvoiceMessage(null);

    try {
      const response = await axiosInstance.post('/invoice-link/send', {
        invoice_id: invoiceId,
        provider: 'viettel',
      });

      const data = response.data;
      
      if (data.status === 'linked') {
        setEInvoiceMessage({ 
          type: 'success', 
          text: data.message || 'Hóa đơn điện tử đã được tạo thành công trên Viettel!' 
        });
      } else if (data.status === 'failed') {
        setEInvoiceMessage({ 
          type: 'error', 
          text: data.message || 'Không thể tạo hóa đơn điện tử' 
        });
      } else {
        setEInvoiceMessage({ 
          type: 'success', 
          text: 'Đang xử lý hóa đơn điện tử...' 
        });
      }
    } catch (error: any) {
      console.error("Error creating e-invoice:", error);
      const errorMessage = error?.response?.data?.message 
        || error?.response?.data?.error 
        || error?.message 
        || "Không thể tạo hóa đơn điện tử. Vui lòng kiểm tra kết nối với Viettel.";
      setEInvoiceMessage({ type: 'error', text: errorMessage });
    } finally {
      setIsSendingEInvoice(false);
    }
  };

  return (
    <Page title={invoiceId ? "Chi tiết hóa đơn" : "Tạo hóa đơn mới"}>
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
                  form="invoice-form"
                >
                  {isSubmitting ? "Đang lưu..." : "Lưu"}
                </Button>
                <Button
                  className="min-w-[7rem]"
                  color="primary"
                  type="button"
                  onClick={handleConfirm}
                  disabled={isSubmitting}
                  form="invoice-form"
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

                  {/* Invoice Lines Notebook */}
                  <div className="mt-5">
                    <Notebook
                      name="invoice_lines"
                      editable={isEditing}
                      form={form}
                      fields={notebookColumns}
                    />
                  </div>

                  {/* Terms and Conditions */}
                  <div className="mt-5">
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

              {/* E-Invoice Card */}
              {invoiceId && (
                <Card className="p-4 sm:px-5">
                  <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                    Hóa đơn điện tử
                  </h6>
                  <div className="mt-3 space-y-3">
                    {eInvoiceMessage && (
                      <div className={`text-sm p-3 rounded ${
                        eInvoiceMessage.type === 'success' 
                          ? 'bg-green-50 text-green-800 dark:bg-green-900/20 dark:text-green-400' 
                          : 'bg-red-50 text-red-800 dark:bg-red-900/20 dark:text-red-400'
                      }`}>
                        {eInvoiceMessage.text}
                      </div>
                    )}
                    <Button
                      className="w-full"
                      color="primary"
                      onClick={handleCreateEInvoice}
                      disabled={isSendingEInvoice || !invoiceId}
                    >
                      {isSendingEInvoice ? "Đang gửi..." : "Tạo hóa đơn điện tử"}
                    </Button>
                    <p className="text-xs text-gray-500 dark:text-dark-400">
                      Gửi hóa đơn lên hệ thống Viettel Invoice
                    </p>
                  </div>
                </Card>
              )}
            </div>
          </div>
        </form>
      </div>
    </Page>
  );
}

