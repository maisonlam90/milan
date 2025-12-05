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

interface SaleOrderLine {
  id?: string;
  product_id?: string;
  name?: string;
  product_uom_qty?: number;
  product_uom_id?: string;
  price_unit?: number;
  discount?: number;
  price_tax?: number;
  price_subtotal?: number;
  price_total?: number;
  qty_delivered?: number;
  qty_invoiced?: number;
  qty_to_invoice?: number;
  invoice_status?: string;
  warehouse_id?: string;
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

interface SaleFormValues extends Record<string, any> {
  order_lines?: SaleOrderLine[];
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
  return fields.filter(isDynamicFieldConfig);
}

// Convert metadata fields → NotebookColumn
function normalizeNotebookColumns(fields?: FormFieldDef[]): NotebookColumn[] {
  if (!fields) return [];
  return fields.map((f) => ({
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
            
            // Convert based on type
            if (fieldType === "number") {
              // Convert to number
              if (typeof value === "string") {
                const numValue = parseFloat(value);
                lineData[key] = isNaN(numValue) ? value : numValue;
              } else if (typeof value === "number") {
                lineData[key] = value;
              } else {
                lineData[key] = value;
              }
            } else if (fieldType === "checkbox") {
              // Convert to boolean
              if (typeof value === "string") {
                lineData[key] = value === "true" || value === "1" || value === "yes";
              } else {
                lineData[key] = Boolean(value);
              }
            } else {
              // Text or other types - convert IDs to string, keep others as is
              if (key.endsWith("_id") && typeof value === "number") {
                lineData[key] = String(value);
              } else {
                lineData[key] = value;
              }
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
  const totals = useMemo(() => {
    let untaxed = 0;
    let tax = 0;
    let total = 0;

    orderLines.forEach((line: SaleOrderLine) => {
      const qty = line.product_uom_qty || 0;
      const price = line.price_unit || 0;
      const discount = line.discount || 0;
      const subtotal = qty * price * (1 - discount / 100);
      untaxed += subtotal;
      const taxAmount = line.price_tax || 0;
      tax += taxAmount;
    });

    total = untaxed + tax;
    return { untaxed, tax, total };
  }, [orderLines]);

  // 5️⃣ Submit form → Gửi lên API /sale/create
  const onSubmit = async (data: SaleFormValues) => {
    try {
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
        alert("✅ Cập nhật thành công!");
      } else {
        // Create mode
        const res = await api.post("/sale/create", payload, { headers });
        console.log("✅ Tạo thành công:", res.data);
        alert("✅ Tạo đơn hàng thành công!");
      }

      navigate("/dashboards/sale/sale-list");
    } catch (err: any) {
      console.error("❌ Lỗi:", err);
      const errorMsg = err.response?.data?.message || err.message || "Lỗi không xác định";
      alert(`❌ Lỗi: ${errorMsg}`);
    }
  };

  return (
    <Page title={saleId ? "Cập nhật Đơn Hàng" : "Tạo Mới Đơn Hàng"}>
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-2">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              🛒 {saleId ? "Cập nhật" : "Tạo Mới"} Đơn Hàng Bán Hàng
            </h2>
          </div>
          <div className="flex gap-2">
            <Button
              className="min-w-[7rem]"
              color="primary"
              type="button"
              onClick={form.handleSubmit(onSubmit)}
            >
              {saleId ? "Lưu thay đổi" : "Lưu"}
            </Button>
          </div>
        </div>

        {isLoadingSale ? (
          <Card className="p-8 text-center">
            <p className="text-gray-600 dark:text-dark-200">Đang tải dữ liệu đơn hàng...</p>
          </Card>
        ) : (
          <form autoComplete="off" onSubmit={form.handleSubmit(onSubmit)}>
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
                          {notebookColumns.length > 0 ? (
                            <Notebook
                              name="order_lines"
                              editable={true}
                              form={form}
                              fields={notebookColumns}
                            />
                          ) : (
                            <div className="p-4 bg-gray-50 dark:bg-dark-600 rounded">
                              <p className="text-sm text-gray-600 dark:text-dark-300">
                                Đang tải notebook... (columns: {notebookColumns.length})
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
                              />
                            )}
                            
                            {/* Terms and Conditions */}
                            <div>
                              <Textarea
                                label="Điều khoản và điều kiện"
                                rows={4}
                                {...form.register("note")}
                                placeholder="Điều khoản và điều kiện"
                              />
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

