// Form Tạo Mới Đơn Hàng Bán Hàng - Load metadata từ API /sale/metadata
import { useEffect, useState, useCallback, useMemo } from "react";
import { useForm, useFieldArray } from "react-hook-form";
import { useNavigate, useSearchParams } from "react-router-dom";
import axios from "axios";
import dayjs from "dayjs";
import { Tab, TabGroup, TabList, TabPanel, TabPanels } from "@headlessui/react";

import { Page } from "@/components/shared/Page";
import { Card, Button, Textarea } from "@/components/ui";
import DynamicForm from "@/components/shared/DynamicForm";
import type { DynamicFieldConfig } from "@/components/shared/DynamicForm";
import Notebook, { type NotebookColumn } from "@/components/shared/Notebook";
import { JWT_HOST_API } from "@/configs/auth";

const api = axios.create({ baseURL: JWT_HOST_API });

// SaleOrderLine interface theo manifest.json notebook fields
interface SaleOrderLine {
  id?: string | number; // ID từ database
  product_id?: number; // type: number trong manifest
  name?: string; // type: text trong manifest
  product_uom_qty?: number; // type: number trong manifest
  product_uom_id?: number; // type: number trong manifest
  price_unit?: number; // type: number trong manifest
  tax_rate?: number; // type: number trong manifest
  customer_lead?: number; // type: number trong manifest
  price_tax?: number; // type: number trong manifest (readonly)
  price_subtotal?: number; // type: number trong manifest (readonly)
  price_total?: number; // type: number trong manifest (readonly)
  // Các field khác không có trong manifest nhưng có thể có trong database
  discount?: number;
  qty_delivered?: number;
  qty_invoiced?: number;
  qty_to_invoice?: number;
  invoice_status?: string;
  warehouse_id?: number;
  is_downpayment?: boolean;
  is_optional?: boolean;
  sequence?: number;
}

interface Metadata {
  form?: {
    fields?: unknown;
  };
  notebook?: {
    table?: string;
    foreign_key?: string;
    fields?: unknown;
  };
}

// SaleFormValues interface theo manifest.json form fields
interface SaleFormValues {
  // Text fields
  name?: string; // type: text
  state?: string; // type: select
  client_order_ref?: string; // type: text
  origin?: string; // type: text
  incoterm_location?: string; // type: text
  picking_policy?: string; // type: text
  delivery_status?: string; // type: text
  invoice_status?: string; // type: text
  reference?: string; // type: text
  signed_by?: string; // type: text
  note?: string; // type: textarea
  
  // Number fields (IDs và số)
  partner_id?: number; // type: number
  user_id?: number; // type: number
  company_id?: number; // type: number
  team_id?: number; // type: number (hidden)
  warehouse_id?: number; // type: number
  partner_invoice_id?: number; // type: number
  partner_shipping_id?: number; // type: number
  pricelist_id?: number; // type: number
  currency_id?: number; // type: number
  payment_term_id?: number; // type: number
  fiscal_position_id?: number; // type: number
  incoterm?: number; // type: number
  amount_untaxed?: number; // type: number (readonly)
  amount_tax?: number; // type: number (readonly)
  amount_total?: number; // type: number (readonly)
  currency_rate?: number; // type: number
  prepayment_percent?: number; // type: number
  
  // Date/Datetime fields
  date_order?: string; // type: datetime (ISO string)
  validity_date?: string; // type: date (ISO string)
  commitment_date?: string; // type: datetime (ISO string)
  effective_date?: string; // type: datetime (ISO string)
  signed_on?: string; // type: datetime (ISO string)
  
  // Checkbox fields
  require_signature?: boolean; // type: checkbox
  require_payment?: boolean; // type: checkbox
  locked?: boolean; // type: checkbox
  
  // Notebook/Order lines
  order_lines?: SaleOrderLine[];
  
  // Allow other fields that might not be in manifest
  [key: string]: any;
}

interface FormFieldDef {
  name: string;
  label?: string;
  type?: string;
  width?: number;
  readonly?: boolean;
  required?: boolean;
  [k: string]: unknown;
}

function isDynamicFieldConfig(x: any): x is DynamicFieldConfig {
  return (
    x &&
    typeof x === "object" &&
    typeof x.name === "string" &&
    typeof x.label === "string"
  );
}

// Convert metadata fields → DynamicForm fields
function toDynamicFields(fields: unknown): DynamicFieldConfig[] {
  if (!Array.isArray(fields)) return [];
  return fields
    .filter(isDynamicFieldConfig)
    .filter((f) => !f.hidden); // Filter out hidden fields
}

// Convert metadata fields → NotebookColumn
function normalizeNotebookColumns(fields?: FormFieldDef[]): NotebookColumn[] {
  if (!fields) return [];
  // Filter out hidden fields first
  return fields
    .filter((f) => !(f as any).hidden) // Skip hidden fields
    .map((f) => ({
      name: f.name,
      label: f.label ?? "",
      type: (f.type as any) ?? "text",
      readonly: f.readonly ?? false,
    }));
}

export default function SaleCreatePage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const saleId = searchParams.get("id");
  const [metadata, setMetadata] = useState<Metadata | null>(null);
  const [isLoadingSale, setIsLoadingSale] = useState<boolean>(!!saleId);
  const [isEditing, setIsEditing] = useState<boolean>(!saleId);
  const [saving, setSaving] = useState<boolean>(false);
  const form = useForm<SaleFormValues>({
    defaultValues: {
      order_lines: [],
    },
  });

  const { control, reset } = form;

  useFieldArray({
    control,
    name: "order_lines",
  });

  // 1️⃣ Load metadata từ API /sale/metadata (load từ manifest.json ngoài binary)
  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get<Metadata>("/sale/metadata");
      setMetadata(res.data);
      console.log("✅ Metadata loaded:", res.data);
      console.log("✅ Notebook metadata:", res.data?.notebook);
      console.log("✅ Notebook fields:", res.data?.notebook?.fields);
    } catch (e) {
      console.error("❌ Lỗi load metadata:", e);
    }
  }, []);

  useEffect(() => {
    fetchMetadata();
  }, [fetchMetadata]);

  // Fetch sale order data when saleId exists
  const fetchSale = useCallback(async () => {
    if (!saleId) return;
    
    try {
      setIsLoadingSale(true);
      const token = localStorage.getItem("authToken");
      const headers = token ? { Authorization: `Bearer ${token}` } : {};
      
      const res = await api.get(`/sale/${saleId}`, { headers });
      const sale = res.data;
      
      console.log("📦 Sale data loaded:", sale);
      console.log("📅 date_order value:", sale.date_order, "type:", typeof sale.date_order);
      
      // Prepare order lines data - map ALL fields from response
      let orderLinesData: SaleOrderLine[] = [];
      if (sale.order_lines && sale.order_lines.length > 0) {
        console.log("📋 Order lines from API:", sale.order_lines);
        
        // Get notebook field types from metadata
        const notebookFieldTypeMap = new Map<string, string>();
        if (metadata?.notebook?.fields) {
          (metadata.notebook.fields as FormFieldDef[]).forEach(field => {
            if (field.name && field.type) {
              notebookFieldTypeMap.set(field.name, field.type);
            }
          });
        }
        
        orderLinesData = sale.order_lines.map((line: any) => {
          const lineData: any = {
            id: line.id,
          };
          
          // Map ALL fields from line object
          Object.keys(line).forEach(key => {
            if (key === "id" || key === "tenant_id" || key === "order_id" || key === "created_by" || key === "created_at" || key === "updated_at") {
              // Skip system fields
              return;
            }
            
            const value = line[key];
            if (value === null || value === undefined) {
              // Keep null/undefined as is for optional fields
              lineData[key] = value;
              return;
            }
            
            const fieldType = notebookFieldTypeMap.get(key) || "text";
            
            // Convert based on type from manifest
            if (fieldType === "number") {
              // Convert to number (theo manifest, các _id fields là number)
              if (typeof value === "string") {
                const numValue = parseFloat(value);
                lineData[key] = isNaN(numValue) ? null : numValue;
              } else if (typeof value === "number") {
                lineData[key] = value;
              } else {
                lineData[key] = null;
              }
            } else if (fieldType === "checkbox") {
              // Convert to boolean
              if (typeof value === "string") {
                lineData[key] = value === "true" || value === "1" || value === "yes";
              } else {
                lineData[key] = Boolean(value);
              }
            } else {
              // Text or other types - keep as is
              lineData[key] = value;
            }
          });
          
          // Ensure required fields have defaults
          if (!lineData.name) lineData.name = "";
          if (lineData.product_uom_qty === null || lineData.product_uom_qty === undefined) {
            lineData.product_uom_qty = 0;
          }
          if (lineData.price_unit === null || lineData.price_unit === undefined) {
            lineData.price_unit = 0;
          }
          if (lineData.customer_lead === null || lineData.customer_lead === undefined) {
            lineData.customer_lead = 0;
          }
          
          return lineData as SaleOrderLine;
        });
        
        console.log("✅ Order lines mapped:", orderLinesData);
      }
      
      // Prepare form data - map ALL fields from sale object
      const formData: SaleFormValues = {
        order_lines: orderLinesData,
      };
      
      // Get field types from metadata if available
      const fieldTypeMap = new Map<string, string>();
      if (metadata?.form?.fields) {
        (metadata.form.fields as FormFieldDef[]).forEach(field => {
          if (field.name && field.type) {
            fieldTypeMap.set(field.name, field.type);
          }
        });
      }
      
      // Map all fields from sale object
      Object.keys(sale).forEach(key => {
        if (key === "order_lines" || key === "id" || key === "tenant_id" || key === "created_by" || key === "created_at" || key === "updated_at") {
          // Skip these fields
          return;
        }
        
        const value = sale[key];
        const fieldType = fieldTypeMap.get(key) || "text";
        
        // Handle date/datetime fields specially - don't skip null, set to empty string
        if (fieldType === "date" || fieldType === "datetime") {
          if (value === null || value === undefined) {
            formData[key] = "";
          } else if (typeof value === "string") {
            const dateValue = dayjs(value);
            if (dateValue.isValid()) {
              formData[key] = dateValue.toISOString();
            } else {
              formData[key] = value;
            }
          } else {
            formData[key] = value;
          }
          return; // Skip to next field
        }
        
        // Skip null/undefined for other field types
        if (value === null || value === undefined) {
          return;
        }
        
        // Convert based on type
        if (fieldType === "number") {
          // Convert to number
          if (typeof value === "string") {
            const numValue = parseFloat(value);
            formData[key] = isNaN(numValue) ? value : numValue;
          } else {
            formData[key] = value;
          }
        } else if (fieldType === "checkbox") {
          // Convert to boolean
          if (typeof value === "string") {
            formData[key] = value === "true" || value === "1" || value === "yes";
          } else {
            formData[key] = Boolean(value);
          }
        } else {
          // Text or other types - keep as is
          formData[key] = value;
        }
      });
      
      console.log("📝 Form data prepared:", formData);
      
      // Reset form with all data
      reset(formData);
      setIsEditing(false); // Set to view mode after loading
    } catch (err: any) {
      console.error("❌ Lỗi load sale order:", err);
      alert(`❌ Không thể tải dữ liệu đơn hàng: ${err.response?.data?.message || err.message}`);
    } finally {
      setIsLoadingSale(false);
    }
  }, [saleId, reset, metadata]);

  useEffect(() => {
    fetchSale();
  }, [fetchSale]);

  // 2️⃣ Convert metadata fields → DynamicForm fields và chia thành 2 nhóm
  const allFields: DynamicFieldConfig[] = useMemo(() => {
    return metadata?.form?.fields
      ? toDynamicFields(metadata.form.fields)
      : [];
  }, [metadata]);

  // Các trường quan trọng hiển thị trực tiếp
  const importantFields: DynamicFieldConfig[] = useMemo(() => {
    const importantFieldNames = [
      "name", "state", "date_order", "partner_id", "user_id", 
      "company_id", "partner_invoice_id", "partner_shipping_id",
      "picking_policy", "amount_untaxed", "amount_tax", "amount_total"
    ];
    return allFields.filter(f => importantFieldNames.includes(f.name));
  }, [allFields]);

  // Các trường ít quan trọng hơn (ẩn trong tab)
  const otherFields: DynamicFieldConfig[] = useMemo(() => {
    const importantFieldNames = [
      "name", "state", "date_order", "partner_id", "user_id", 
      "company_id", "partner_invoice_id", "partner_shipping_id",
      "picking_policy", "amount_untaxed", "amount_tax", "amount_total", "note"
    ];
    return allFields.filter(f => !importantFieldNames.includes(f.name));
  }, [allFields]);

  // 3️⃣ Convert notebook fields → NotebookColumn
  const notebookColumns: NotebookColumn[] = useMemo(() => {
    const notebookFields = metadata?.notebook?.fields as FormFieldDef[] | undefined;
    return normalizeNotebookColumns(notebookFields);
  }, [metadata]);

  // 4️⃣ Tính tổng tiền từ order_lines
  const orderLines = form.watch("order_lines") || [];
  
  // State để trigger totals update khi line values thay đổi
  const [totalsUpdateTrigger, setTotalsUpdateTrigger] = useState(0);
  
  // 4.1️⃣ Tự động tính price_subtotal, price_tax, price_total cho mỗi line khi qty/price thay đổi
  useEffect(() => {
    if (!isEditing || !metadata) return;
    
    const calculateLineTotals = async (lineIndex: number, line: SaleOrderLine) => {
      const qty = line.product_uom_qty || 0;
      const priceUnit = line.price_unit || 0;
      
      // Skip nếu qty hoặc price = 0
      if (qty === 0 || priceUnit === 0) {
        form.setValue(`order_lines.${lineIndex}.price_subtotal` as any, 0);
        form.setValue(`order_lines.${lineIndex}.price_tax` as any, 0);
        form.setValue(`order_lines.${lineIndex}.price_total` as any, 0);
        return;
      }
      
      // Lấy tax_rate từ form, mặc định 10% nếu không có
      const taxRate = line.tax_rate !== undefined && line.tax_rate !== null 
        ? Number(line.tax_rate) 
        : 10.0;
      
      try {
        // Gọi WASM function để tính toán
        const token = localStorage.getItem("authToken");
        const headers = token ? { Authorization: `Bearer ${token}` } : {};
        
        const response = await api.post(
          "/sale/wasm/calculate_line",
          { args: [qty, priceUnit, taxRate] },
          { headers }
        );
        
        if (response.data?.success && response.data?.result) {
          const result = JSON.parse(response.data.result);
          
          // Cập nhật form values với shouldTouch để trigger watch
          form.setValue(`order_lines.${lineIndex}.price_subtotal` as any, result.subtotal || 0, { shouldDirty: false, shouldTouch: true });
          form.setValue(`order_lines.${lineIndex}.price_tax` as any, result.tax || 0, { shouldDirty: false, shouldTouch: true });
          form.setValue(`order_lines.${lineIndex}.price_total` as any, result.total || 0, { shouldDirty: false, shouldTouch: true });
          
          // Trigger totals update
          setTotalsUpdateTrigger(prev => prev + 1);
        }
      } catch (err) {
        console.error("❌ Lỗi tính toán line totals:", err);
        // Fallback: tính toán local nếu WASM fail
        const subtotal = qty * priceUnit;
        const tax = subtotal * taxRate / 100;
        const total = subtotal + tax;
        
        form.setValue(`order_lines.${lineIndex}.price_subtotal` as any, subtotal, { shouldDirty: false, shouldTouch: true });
        form.setValue(`order_lines.${lineIndex}.price_tax` as any, tax, { shouldDirty: false, shouldTouch: true });
        form.setValue(`order_lines.${lineIndex}.price_total` as any, total, { shouldDirty: false, shouldTouch: true });
        
        // Trigger totals update
        setTotalsUpdateTrigger(prev => prev + 1);
      }
    };
    
    // Tính toán cho tất cả lines
    orderLines.forEach((line: SaleOrderLine, index: number) => {
      // Chỉ tính nếu có qty và price_unit
      if (line.product_uom_qty !== undefined && line.price_unit !== undefined) {
        calculateLineTotals(index, line);
      }
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [orderLines.map(l => `${l.product_uom_qty || 0}-${l.price_unit || 0}-${l.tax_rate || 0}`).join(','), isEditing, metadata]);
  
  // 4.2️⃣ Tính tổng đơn hàng bằng WASM (nhất quán với tính từng dòng)
  const [totals, setTotals] = useState({ untaxed: 0, tax: 0, total: 0 });
  
  // Tạo dependency string từ các giá trị price_subtotal, price_tax, price_total
  // Để tự động tính lại khi các giá trị này thay đổi
  const totalsDependency = useMemo(() => {
    return orderLines.map((line: SaleOrderLine) => 
      `${line.price_subtotal || 0}-${line.price_tax || 0}-${line.price_total || 0}`
    ).join('|');
  }, [orderLines, totalsUpdateTrigger]); // Thêm trigger để force update
  
  useEffect(() => {
    const calculateTotals = async () => {
      if (orderLines.length === 0) {
        setTotals({ untaxed: 0, tax: 0, total: 0 });
        return;
      }
      
      // Prepare arrays for WASM
      const subtotals = orderLines.map((line: SaleOrderLine) => line.price_subtotal || 0);
      const taxes = orderLines.map((line: SaleOrderLine) => line.price_tax || 0);
      const totals = orderLines.map((line: SaleOrderLine) => line.price_total || 0);
      
      try {
        // Gọi WASM function để tính tổng
        const token = localStorage.getItem("authToken");
        const headers = token ? { Authorization: `Bearer ${token}` } : {};
        
        const response = await api.post(
          "/sale/wasm/calculate_order_totals",
          { 
            args: [
              JSON.stringify(subtotals),
              JSON.stringify(taxes),
              JSON.stringify(totals)
            ]
          },
          { headers }
        );
        
        if (response.data?.success && response.data?.result) {
          const result = JSON.parse(response.data.result);
          setTotals({
            untaxed: result.untaxed || 0,
            tax: result.tax || 0,
            total: result.total || 0,
          });
        }
      } catch (err) {
        console.error("❌ Lỗi tính tổng đơn hàng bằng WASM:", err);
        // Fallback: tính bằng JS nếu WASM fail
        let untaxed = 0;
        let tax = 0;
        let total = 0;
        
        orderLines.forEach((line: SaleOrderLine) => {
          untaxed += line.price_subtotal || 0;
          tax += line.price_tax || 0;
          total += line.price_total || 0;
        });
        
        setTotals({ untaxed, tax, total });
      }
    };
    
    calculateTotals();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [totalsDependency, totalsUpdateTrigger]); // Tự động tính lại khi các giá trị price_subtotal/tax/total thay đổi

  // 5️⃣ Submit form → Gửi lên API /sale/create
  const onSubmit = async (data: SaleFormValues) => {
    try {
      setSaving(true);
      const token = localStorage.getItem("authToken");
      const headers = token ? { Authorization: `Bearer ${token}` } : {};

      // Prepare payload with order_lines
      const payload = {
        ...data,
        order_lines: data.order_lines || [],
      };

      if (saleId) {
        // Update mode (nếu có id)
        await api.post(`/sale/${saleId}/update`, payload, { headers });
        // Reload data after update
        await fetchSale();
        setIsEditing(false);
      } else {
        // Create mode
        const res = await api.post("/sale/create", payload, { headers });
        console.log("✅ Tạo thành công:", res.data);
        const newSaleId = res.data?.id;
        if (newSaleId) {
          // Navigate to the new sale order
          navigate(`/dashboards/sale/sale-create?id=${newSaleId}`);
        } else {
          navigate("/dashboards/sale/sale-list");
        }
      }
    } catch (err: any) {
      console.error("❌ Lỗi:", err);
      const errorMsg = err.response?.data?.message || err.message || "Lỗi không xác định";
      alert(`❌ Lỗi: ${errorMsg}`);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Page title={saleId ? "Cập nhật Đơn Hàng" : "Tạo Mới Đơn Hàng"}>
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-1">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              🛒 {saleId ? "Chi tiết Đơn Hàng" : "Tạo Mới Đơn Hàng Bán Hàng"}
            </h2>
            {isLoadingSale && (
              <span className="ml-3 text-xs text-gray-400">Đang tải dữ liệu đơn hàng…</span>
            )}
          </div>
          <div className="flex gap-2">
            {saleId && !isEditing && (
              <Button className="min-w-[7rem]" onClick={() => setIsEditing(true)}>
                Chỉnh sửa
              </Button>
            )}
            {isEditing && (
              <>
                <Button
                  className="min-w-[7rem]"
                  variant="outlined"
                  onClick={() => {
                    if (saleId) {
                      fetchSale();
                    } else {
                      navigate("/dashboards/sale/sale-list");
                    }
                  }}
                  disabled={saving}
                >
                  Hủy
                </Button>
                <Button
                  className="min-w-[7rem]"
                  color="primary"
                  type="submit"
                  form="sale-form"
                  disabled={saving}
                >
                  {saving ? "Đang lưu..." : "Lưu"}
                </Button>
              </>
            )}
          </div>
        </div>

        {isLoadingSale ? (
          <Card className="p-8 text-center">
            <p className="text-gray-600 dark:text-dark-200">Đang tải dữ liệu đơn hàng...</p>
          </Card>
        ) : (
          <form autoComplete="off" onSubmit={form.handleSubmit(onSubmit)} id="sale-form">
            <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
            {/* Left Column - Main Form */}
            <div className="col-span-12 lg:col-span-8">
              <Card className="p-4 sm:px-5">
                <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Thông tin đơn hàng
                </h3>

                <div className="mt-5 space-y-5">
                  {/* Important Fields */}
                  {importantFields.length > 0 && (
                    <DynamicForm
                      form={form}
                      fields={importantFields}
                      disabled={!isEditing}
                    />
                  )}

                  {/* Tabs: Sale Lines và Other Info */}
                  <div className="mt-5">
                    <TabGroup>
                      <TabList className="flex space-x-1 rounded-xl bg-gray-100 dark:bg-dark-600 p-1">
                        <Tab className={({ selected }) =>
                          `w-full rounded-lg py-2.5 text-sm font-medium leading-5 transition-colors ${
                            selected
                              ? "bg-white dark:bg-dark-700 text-primary-600 dark:text-primary-400 shadow"
                              : "text-gray-600 dark:text-dark-300 hover:bg-white/50 dark:hover:bg-dark-700/50"
                          }`
                        }>
                          Chi tiết đơn hàng
                        </Tab>
                        <Tab className={({ selected }) =>
                          `w-full rounded-lg py-2.5 text-sm font-medium leading-5 transition-colors ${
                            selected
                              ? "bg-white dark:bg-dark-700 text-primary-600 dark:text-primary-400 shadow"
                              : "text-gray-600 dark:text-dark-300 hover:bg-white/50 dark:hover:bg-dark-700/50"
                          }`
                        }>
                          Thông tin khác
                        </Tab>
                      </TabList>

                      <TabPanels className="mt-5">
                        {/* Tab 1: Sale Lines (Notebook) */}
                        <TabPanel>
                          {metadata?.notebook ? (
                            <Notebook
                              name="order_lines"
                              editable={isEditing}
                              form={form}
                              fields={notebookColumns}
                            />
                          ) : (
                            <div className="p-4 bg-gray-50 dark:bg-dark-600 rounded">
                              <p className="text-sm text-gray-600 dark:text-dark-300">
                                Đang tải notebook...
                              </p>
                            </div>
                          )}
                        </TabPanel>

                        {/* Tab 2: Other Info (Các trường ít quan trọng) */}
                        <TabPanel>
                          <div className="space-y-5">
                            {otherFields.length > 0 && (
                              <DynamicForm
                                form={form}
                                fields={otherFields}
                                disabled={!isEditing}
                              />
                            )}
                            
                            {/* Terms and Conditions */}
                            <div>
                              {isEditing ? (
                                <Textarea
                                  label="Điều khoản và điều kiện"
                                  rows={4}
                                  {...form.register("note")}
                                  placeholder="Điều khoản và điều kiện"
                                />
                              ) : (
                                <>
                                  <label className="block mb-1 text-gray-700 dark:text-dark-100">
                                    Điều khoản và điều kiện
                                  </label>
                                  <div className="bg-gray-100 dark:bg-dark-800 text-gray-600 px-2 py-1 rounded whitespace-pre-line">
                                    {form.watch("note") || ""}
                                  </div>
                                </>
                              )}
                            </div>
                          </div>
                        </TabPanel>
                      </TabPanels>
                    </TabGroup>
                  </div>
                </div>
              </Card>
            </div>

            {/* Right Column - Summary */}
            <div className="col-span-12 lg:col-span-4 space-y-4 sm:space-y-5 lg:space-y-6">
              <Card className="p-4 sm:px-5">
                <h6 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Tổng kết
                </h6>
                <div className="mt-3 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600 dark:text-dark-300">
                      Tổng chưa thuế:
                    </span>
                    <span className="font-medium text-gray-900 dark:text-dark-50">
                      {new Intl.NumberFormat("vi-VN", {
                        style: "currency",
                        currency: "VND"
                      }).format(totals.untaxed)}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600 dark:text-dark-300">
                      Thuế:
                    </span>
                    <span className="font-medium text-gray-900 dark:text-dark-50">
                      {new Intl.NumberFormat("vi-VN", {
                        style: "currency",
                        currency: "VND"
                      }).format(totals.tax)}
                    </span>
                  </div>
                  <div className="flex justify-between text-lg font-bold border-t border-gray-200 dark:border-dark-500 pt-2">
                    <span className="text-gray-900 dark:text-dark-50">Tổng cộng:</span>
                    <span className="text-gray-900 dark:text-dark-50">
                      {new Intl.NumberFormat("vi-VN", {
                        style: "currency",
                        currency: "VND"
                      }).format(totals.total)}
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
                    {form.watch("state") || "Draft"}
                  </div>
                </div>
              </Card>
            </div>
          </div>
        </form>
        )}
      </div>
    </Page>
  );
}

