// Form Tạo Mới Sản Phẩm - Load metadata từ API /product/metadata
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

// ProductVariant interface theo manifest.json notebook fields
interface ProductVariant {
  id?: string | number;
  default_code?: string;
  barcode?: string;
  standard_price?: number;
  volume?: number;
  weight?: number;
  active?: boolean;
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

// ProductFormValues interface theo manifest.json form fields
interface ProductFormValues {
  // Text fields
  name?: string;
  default_code?: string;
  type?: string;
  tracking?: string;
  service_tracking?: string;
  service_type?: string;
  expense_policy?: string;
  invoice_policy?: string;
  purchase_method?: string;
  description?: string;
  description_purchase?: string;
  description_sale?: string;
  
  // Number fields
  categ_id?: number;
  list_price?: number;
  uom_id?: number;
  company_id?: number;
  weight?: number;
  volume?: number;
  sale_delay?: number;
  color?: number;
  sequence?: number;
  
  // Checkbox fields
  active?: boolean;
  sale_ok?: boolean;
  purchase_ok?: boolean;
  
  // Notebook/Variants
  variants?: ProductVariant[];
  
  // Allow other fields
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
    .filter((f) => !f.hidden);
}

// Convert metadata fields → NotebookColumn
function normalizeNotebookColumns(fields?: FormFieldDef[]): NotebookColumn[] {
  if (!fields) return [];
  return fields
    .filter((f) => !(f as any).hidden)
    .map((f) => ({
      name: f.name,
      label: f.label ?? "",
      type: (f.type as any) ?? "text",
      readonly: f.readonly ?? false,
    }));
}

export default function ProductCreatePage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const productId = searchParams.get("id");
  const [metadata, setMetadata] = useState<Metadata | null>(null);
  const [isLoadingProduct, setIsLoadingProduct] = useState<boolean>(!!productId);
  const [isEditing, setIsEditing] = useState<boolean>(!productId);
  const [saving, setSaving] = useState<boolean>(false);
  const form = useForm<ProductFormValues>({
    defaultValues: {
      variants: [],
      active: true,
      sale_ok: true,
      purchase_ok: true,
      type: "consu",
      tracking: "none",
      service_tracking: "no",
    },
  });

  const { control, reset } = form;

  useFieldArray({
    control,
    name: "variants",
  });

  // 1️⃣ Load metadata từ API /product/metadata
  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get<Metadata>("/product/metadata");
      setMetadata(res.data);
      console.log("✅ Metadata loaded:", res.data);
      console.log("✅ Form metadata:", res.data?.form);
      console.log("✅ Form fields:", res.data?.form?.fields);
      console.log("✅ Notebook metadata:", res.data?.notebook);
      console.log("✅ Notebook fields:", res.data?.notebook?.fields);
    } catch (e) {
      console.error("❌ Lỗi load metadata:", e);
    }
  }, []);

  useEffect(() => {
    fetchMetadata();
  }, [fetchMetadata]);

  // Fetch product data when productId exists
  const fetchProduct = useCallback(async () => {
    if (!productId) return;
    
    try {
      setIsLoadingProduct(true);
      const token = localStorage.getItem("authToken");
      const headers = token ? { Authorization: `Bearer ${token}` } : {};
      
      const res = await api.get(`/product/${productId}`, { headers });
      const product = res.data;
      
      console.log("📦 Product data loaded:", product);
      
      // Prepare variants data
      let variantsData: ProductVariant[] = [];
      if (product.variants && product.variants.length > 0) {
        console.log("📋 Variants from API:", product.variants);
        
        const notebookFieldTypeMap = new Map<string, string>();
        if (metadata?.notebook?.fields) {
          (metadata.notebook.fields as FormFieldDef[]).forEach(field => {
            if (field.name && field.type) {
              notebookFieldTypeMap.set(field.name, field.type);
            }
          });
        }
        
        variantsData = product.variants.map((variant: any) => {
          const variantData: any = { id: variant.id };
          
          Object.keys(variant).forEach(key => {
            if (key === "id" || key === "tenant_id" || key === "product_tmpl_id" || key === "created_by" || key === "created_at" || key === "updated_at") {
              return;
            }
            
            const value = variant[key];
            if (value === null || value === undefined) {
              variantData[key] = value;
              return;
            }
            
            const fieldType = notebookFieldTypeMap.get(key) || "text";
            
            if (fieldType === "number") {
              if (typeof value === "string") {
                const numValue = parseFloat(value);
                variantData[key] = isNaN(numValue) ? null : numValue;
              } else if (typeof value === "number") {
                variantData[key] = value;
              } else {
                variantData[key] = null;
              }
            } else if (fieldType === "checkbox") {
              if (typeof value === "string") {
                variantData[key] = value === "true" || value === "1" || value === "yes";
              } else {
                variantData[key] = Boolean(value);
              }
            } else {
              variantData[key] = value;
            }
          });
          
          return variantData as ProductVariant;
        });
        
        console.log("✅ Variants mapped:", variantsData);
      }
      
      // Prepare form data
      const formData: ProductFormValues = {
        variants: variantsData,
      };
      
      const fieldTypeMap = new Map<string, string>();
      if (metadata?.form?.fields) {
        (metadata.form.fields as FormFieldDef[]).forEach(field => {
          if (field.name && field.type) {
            fieldTypeMap.set(field.name, field.type);
          }
        });
      }
      
      Object.keys(product).forEach(key => {
        if (key === "variants" || key === "id" || key === "tenant_id" || key === "created_by" || key === "created_at" || key === "updated_at") {
          return;
        }
        
        const value = product[key];
        const fieldType = fieldTypeMap.get(key) || "text";
        
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
          return;
        }
        
        if (value === null || value === undefined) {
          return;
        }
        
        if (fieldType === "number") {
          if (typeof value === "string") {
            const numValue = parseFloat(value);
            formData[key] = isNaN(numValue) ? value : numValue;
          } else {
            formData[key] = value;
          }
        } else if (fieldType === "checkbox") {
          if (typeof value === "string") {
            formData[key] = value === "true" || value === "1" || value === "yes";
          } else {
            formData[key] = Boolean(value);
          }
        } else {
          formData[key] = value;
        }
      });
      
      console.log("📝 Form data prepared:", formData);
      
      reset(formData);
      setIsEditing(false);
    } catch (err: any) {
      console.error("❌ Lỗi load product:", err);
      alert(`❌ Không thể tải dữ liệu sản phẩm: ${err.response?.data?.message || err.message}`);
    } finally {
      setIsLoadingProduct(false);
    }
  }, [productId, reset, metadata]);

  useEffect(() => {
    fetchProduct();
  }, [fetchProduct]);

  // 2️⃣ Convert metadata fields → DynamicForm fields
  const allFields: DynamicFieldConfig[] = useMemo(() => {
    const fields = metadata?.form?.fields
      ? toDynamicFields(metadata.form.fields)
      : [];
    console.log("🔍 All fields converted:", fields);
    return fields;
  }, [metadata]);

  // Các trường quan trọng hiển thị trực tiếp
  const importantFields: DynamicFieldConfig[] = useMemo(() => {
    const importantFieldNames = [
      "name", "default_code", "active", "type", "categ_id", 
      "list_price", "uom_id", "sale_ok", "purchase_ok", "tracking"
    ];
    const filtered = allFields.filter(f => importantFieldNames.includes(f.name));
    console.log("🔍 Important fields:", filtered);
    return filtered;
  }, [allFields]);

  // Các trường ít quan trọng hơn
  const otherFields: DynamicFieldConfig[] = useMemo(() => {
    const importantFieldNames = [
      "name", "default_code", "active", "type", "categ_id", 
      "list_price", "uom_id", "sale_ok", "purchase_ok", "tracking",
      "description", "description_purchase", "description_sale"
    ];
    const filtered = allFields.filter(f => !importantFieldNames.includes(f.name));
    console.log("🔍 Other fields:", filtered);
    return filtered;
  }, [allFields]);

  // 3️⃣ Convert notebook fields → NotebookColumn
  const notebookColumns: NotebookColumn[] = useMemo(() => {
    const notebookFields = metadata?.notebook?.fields as FormFieldDef[] | undefined;
    return normalizeNotebookColumns(notebookFields);
  }, [metadata]);

  // 4️⃣ Tính toán margin/profit khi thay đổi giá
  const listPrice = form.watch("list_price") || 0;
  const [costPrice, setCostPrice] = useState(0);
  const [margin, setMargin] = useState({ margin: 0, profit: 0 });
  
  // Calculate margin when prices change
  useEffect(() => {
    const calculateMargin = async () => {
      if (listPrice === 0 || costPrice === 0) {
        setMargin({ margin: 0, profit: 0 });
        return;
      }
      
      try {
        const token = localStorage.getItem("authToken");
        const headers = token ? { Authorization: `Bearer ${token}` } : {};
        
        const response = await api.post(
          "/product/wasm/calculate_margin_from_prices",
          { args: [costPrice, listPrice] },
          { headers }
        );
        
        if (response.data?.success && response.data?.result) {
          const result = JSON.parse(response.data.result);
          setMargin({
            margin: result.margin || 0,
            profit: result.profit || 0,
          });
        }
      } catch (err) {
        console.error("❌ Lỗi tính margin:", err);
        // Fallback: tính local
        const profit = listPrice - costPrice;
        const marginPercent = costPrice > 0 ? (profit / costPrice) * 100 : 0;
        setMargin({ margin: marginPercent, profit });
      }
    };
    
    calculateMargin();
  }, [listPrice, costPrice]);

  // 5️⃣ Submit form
  const onSubmit = async (data: ProductFormValues) => {
    try {
      setSaving(true);
      const token = localStorage.getItem("authToken");
      const headers = token ? { Authorization: `Bearer ${token}` } : {};

      const payload = {
        ...data,
        variants: data.variants || [],
      };

      if (productId) {
        await api.post(`/product/${productId}/update`, payload, { headers });
        await fetchProduct();
        setIsEditing(false);
      } else {
        const res = await api.post("/product/create", payload, { headers });
        console.log("✅ Tạo thành công:", res.data);
        const newProductId = res.data?.id;
        if (newProductId) {
          navigate(`/dashboards/product/product-create?id=${newProductId}`);
        } else {
          navigate("/dashboards/product/product-list");
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
    <Page title={productId ? "Cập nhật Sản Phẩm" : "Tạo Mới Sản Phẩm"}>
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-1">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              📦 {productId ? "Chi tiết Sản Phẩm" : "Tạo Mới Sản Phẩm"}
            </h2>
            {isLoadingProduct && (
              <span className="ml-3 text-xs text-gray-400">Đang tải dữ liệu sản phẩm…</span>
            )}
          </div>
          <div className="flex gap-2">
            {productId && !isEditing && (
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
                    if (productId) {
                      fetchProduct();
                    } else {
                      navigate("/dashboards/product/product-list");
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
                  form="product-form"
                  disabled={saving}
                >
                  {saving ? "Đang lưu..." : "Lưu"}
                </Button>
              </>
            )}
          </div>
        </div>

        {isLoadingProduct ? (
          <Card className="p-8 text-center">
            <p className="text-gray-600 dark:text-dark-200">Đang tải dữ liệu sản phẩm...</p>
          </Card>
        ) : (
          <form autoComplete="off" onSubmit={form.handleSubmit(onSubmit)} id="product-form">
            <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
            {/* Left Column - Main Form */}
            <div className="col-span-12 lg:col-span-8">
              <Card className="p-4 sm:px-5">
                <h3 className="text-base font-medium text-gray-800 dark:text-dark-100">
                  Thông tin sản phẩm
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

                  {/* Tabs: Product Variants và Other Info */}
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
                          Biến thể sản phẩm
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
                        {/* Tab 1: Product Variants (Notebook) */}
                        <TabPanel>
                          {metadata?.notebook ? (
                            <Notebook
                              name="variants"
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

                        {/* Tab 2: Other Info */}
                        <TabPanel>
                          <div className="space-y-5">
                            {otherFields.length > 0 && (
                              <DynamicForm
                                form={form}
                                fields={otherFields}
                                disabled={!isEditing}
                              />
                            )}
                            
                            {/* Description */}
                            <div>
                              {isEditing ? (
                                <Textarea
                                  label="Mô tả"
                                  rows={4}
                                  {...form.register("description")}
                                  placeholder="Mô tả sản phẩm"
                                />
                              ) : (
                                <>
                                  <label className="block mb-1 text-gray-700 dark:text-dark-100">
                                    Mô tả
                                  </label>
                                  <div className="bg-gray-100 dark:bg-dark-800 text-gray-600 px-2 py-1 rounded whitespace-pre-line">
                                    {form.watch("description") || ""}
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
                  Thông tin giá
                </h6>
                <div className="mt-3 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600 dark:text-dark-300">
                      Giá bán:
                    </span>
                    <span className="font-medium text-gray-900 dark:text-dark-50">
                      {new Intl.NumberFormat("vi-VN", {
                        style: "currency",
                        currency: "VND"
                      }).format(listPrice)}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600 dark:text-dark-300">
                      Lợi nhuận:
                    </span>
                    <span className="font-medium text-gray-900 dark:text-dark-50">
                      {new Intl.NumberFormat("vi-VN", {
                        style: "currency",
                        currency: "VND"
                      }).format(margin.profit)}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm border-t border-gray-200 dark:border-dark-500 pt-2">
                    <span className="text-gray-600 dark:text-dark-300">Tỷ suất lợi nhuận:</span>
                    <span className="font-medium text-gray-900 dark:text-dark-50">
                      {margin.margin.toFixed(2)}%
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
                    <span className="opacity-70">Loại:&nbsp;</span>
                    {form.watch("type") || "consu"}
                  </div>
                  <div>
                    <span className="opacity-70">Trạng thái:&nbsp;</span>
                    {form.watch("active") ? "Hoạt động" : "Không hoạt động"}
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

