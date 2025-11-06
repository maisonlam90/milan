// /home/milan/milan/src/frontend/demo/src/app/pages/dashboards/invoice/invoice-create/InvoiceCreate.tsx
import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import {
  PlusIcon,
  TrashIcon,
  DocumentArrowDownIcon,
} from "@heroicons/react/24/outline";

import { Box } from "@/components/ui";
import { Page } from "@/components/shared/Page";
import { JWT_HOST_API } from "@/configs/auth";

interface InvoiceLine {
  id: string;
  name: string;
  product_id?: string;
  account_id: string;
  quantity: number;
  price_unit: number;
  discount: number;
  tax_ids: string[];
}

// ✅ Updated interface to match API response
interface Partner {
  id: string;
  name: string;
  display_name?: string | null;
  email?: string;
  phone?: string;
  is_company?: boolean;
}

interface Journal {
  id: string;
  name: string;
  code: string;
}

// ✅ Create axios instance với baseURL (giống loan-create)
const api = axios.create({ baseURL: JWT_HOST_API });

export function InvoiceCreate() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [partners, setPartners] = useState<Partner[]>([]);
  const [journals, setJournals] = useState<Journal[]>([]);
  const [accounts, setAccounts] = useState<any[]>([]);
  const [, setTaxes] = useState<any[]>([]);

  const [formData, setFormData] = useState({
    move_type: "out_invoice",
    partner_id: "",
    invoice_date: new Date().toISOString().split("T")[0],
    invoice_date_due: "",
    ref: "",
    narration: "",
    journal_id: "",
    payment_term_id: "",
  });

  const [lines, setLines] = useState<InvoiceLine[]>([
    {
      id: "1",
      name: "",
      product_id: undefined,
      account_id: "",
      quantity: 1,
      price_unit: 0,
      discount: 0,
      tax_ids: [],
    },
  ]);

  const token =
    typeof window !== "undefined" ? localStorage.getItem("authToken") : null;

  const authHeader = token ? { Authorization: `Bearer ${token}` } : undefined;

  useEffect(() => {
    console.log("🎯 Component mounted, calling fetchMetadata...");
    fetchMetadata();
  }, []);

  const fetchMetadata = async () => {
    try {
      console.log("=".repeat(60));
      console.log("📡 Starting fetchMetadata...");
      console.log("🔐 Token from storage:", token ? `${token.substring(0, 20)}...` : "❌ NO TOKEN");
      console.log("🔐 AuthHeader:", authHeader ? "✅ SET" : "❌ NOT SET");
      console.log("API baseURL:", JWT_HOST_API);

      // ✅ Dùng api instance
      console.log("📤 Calling GET /contact/list...");
      const partnersRes = await api.get<Partner[]>("/contact/list", {
        headers: authHeader,
        params: { limit: 100, is_company: true },
      });

      console.log("✅ API call succeeded!");
      console.log("📊 Response status:", partnersRes.status);
      console.log("📊 Response data type:", typeof partnersRes.data);
      console.log("📊 Response data:", partnersRes.data);
      console.log("📊 Is array?", Array.isArray(partnersRes.data));
      console.log("📊 Length:", partnersRes.data?.length);

      const partnersData = Array.isArray(partnersRes.data) ? partnersRes.data : [];
      console.log("📦 Partners data to set:", partnersData);
      console.log("📦 Calling setPartners() with", partnersData.length, "items...");
      
      setPartners(partnersData);
      
      console.log("✅ setPartners() called! State should update soon...");

      // Fetch journals, accounts, taxes
      console.log("📤 Calling parallel APIs...");
      const [journalsRes, accountsRes, taxesRes] = await Promise.all([
        api.get("/invoice/metadata", { headers: authHeader }),
        api.get("/account/list", { headers: authHeader }),
        api.get("/tax/list", { headers: authHeader }),
      ]);

      console.log("✅ All parallel APIs called successfully");
      console.log("✅ Journals:", journalsRes.data);
      console.log("✅ Accounts:", accountsRes.data);

      setJournals(journalsRes.data.journals || []);
      setAccounts(accountsRes.data.data || []);
      setTaxes(taxesRes.data.data || []);

      console.log("✅ All state updated!");
      console.log("=".repeat(60));
    } catch (error: any) {
      console.error("=".repeat(60));
      console.error("❌ ERROR in fetchMetadata!");
      console.error("❌ Error message:", error.message);
      console.error("❌ Error response data:", error.response?.data);
      console.error("❌ Error response status:", error.response?.status);
      console.error("❌ Error config URL:", error.config?.url);
      console.error("❌ Error config baseURL:", error.config?.baseURL);
      console.error("❌ Full error:", error);
      console.error("=".repeat(60));
    }
  };

  const addLine = () => {
    const newLine: InvoiceLine = {
      id: Date.now().toString(),
      name: "",
      product_id: undefined,
      account_id: "",
      quantity: 1,
      price_unit: 0,
      discount: 0,
      tax_ids: [],
    };
    setLines([...lines, newLine]);
  };

  const removeLine = (id: string) => {
    if (lines.length > 1) {
      setLines(lines.filter((line) => line.id !== id));
    }
  };

  const updateLine = (id: string, field: keyof InvoiceLine, value: any) => {
    setLines(
      lines.map((line) =>
        line.id === id ? { ...line, [field]: value } : line
      )
    );
  };

  const calculateLineTotal = (line: InvoiceLine) => {
    const subtotal = line.quantity * line.price_unit;
    const discountAmount = (subtotal * line.discount) / 100;
    return subtotal - discountAmount;
  };

  const calculateTotal = () => {
    return lines.reduce((total, line) => total + calculateLineTotal(line), 0);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    console.log("📝 Form submitted");
    console.log("📝 Current partners state:", partners);
    console.log("📝 Selected partner_id:", formData.partner_id);

    // ✅ VALIDATE REQUIRED FIELDS
    if (!formData.partner_id) {
      alert("❌ Vui lòng chọn Partner");
      return;
    }

    if (!formData.journal_id) {
      alert("❌ Vui lòng chọn Journal");
      return;
    }

    if (!formData.invoice_date) {
      alert("❌ Vui lòng chọn Invoice Date");
      return;
    }

    // ✅ Check có dòng nào không?
    if (lines.length === 0) {
      alert("❌ Hóa đơn phải có ít nhất 1 dòng");
      return;
    }

    // ✅ Check tất cả dòng có account_id không?
    if (lines.some((line) => !line.account_id)) {
      alert("❌ Vui lòng chọn Account cho tất cả dòng");
      return;
    }

    // ✅ Check tất cả dòng có description không?
    if (lines.some((line) => !line.name)) {
      alert("❌ Vui lòng nhập Description cho tất cả dòng");
      return;
    }

    setLoading(true);

    try {
      const payload = {
        ...formData,
        partner_id: formData.partner_id ? formData.partner_id : null,
        lines: lines.map((line) => ({
          name: line.name,
          product_id: line.product_id || null,
          account_id: line.account_id,
          quantity: line.quantity || 1,
          price_unit: line.price_unit || 0,
          discount: line.discount || 0,
          tax_ids: line.tax_ids || [],
        })),
      };

      console.log("📤 Sending payload:", JSON.stringify(payload, null, 2));

      // ✅ Dùng api instance
      const response = await api.post("/invoice/create", payload, {
        headers: authHeader,
      });

      console.log("✅ Success! Response:", response.data);
      alert("✅ Hóa đơn đã được tạo thành công!");
      navigate("/dashboards/invoice/invoice-list");
    } catch (error: any) {
      console.error("❌ Error creating invoice:", error);
      const errorMessage =
        error.response?.data?.message ||
        error.response?.data?.error ||
        error.message ||
        "Unknown error";
      alert(`❌ Lỗi: ${errorMessage}`);
    } finally {
      setLoading(false);
    }
  };

  console.log("🔄 Component rendering, partners state:", partners);

  return (
    <Page title="Create Invoice">
      <div className="transition-content px-(--margin-x) pb-6">
        <div className="flex flex-col items-center justify-between space-y-4 py-5 sm:flex-row sm:space-y-0 lg:py-6">
          <div className="flex items-center gap-1">
            <h2 className="line-clamp-1 text-xl font-medium text-gray-700 dark:text-dark-50">
              Create Invoice
            </h2>
            {loading && (
              <span className="ml-3 text-xs text-gray-400">Đang tải dữ liệu…</span>
            )}
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => navigate("/dashboards/invoice/invoice-list")}
              className="min-w-[7rem] rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              form="invoice-form"
              disabled={loading}
              className="min-w-[7rem] inline-flex items-center rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
            >
              {loading ? (
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
              ) : (
                <>
                  <DocumentArrowDownIcon className="mr-2 h-4 w-4" />
                  Save Invoice
                </>
              )}
            </button>
          </div>
        </div>

        <form id="invoice-form" onSubmit={handleSubmit}>
          <div className="grid grid-cols-12 place-content-start gap-4 sm:gap-5 lg:gap-6">
            <div className="col-span-12 lg:col-span-8">
              {/* Basic Information */}
              <Box className="p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Basic Information
                </h3>
                <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Invoice Type
                    </label>
                    <select
                      value={formData.move_type}
                      onChange={(e) =>
                        setFormData({ ...formData, move_type: e.target.value })
                      }
                      className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    >
                      <option value="out_invoice">Customer Invoice</option>
                      <option value="in_invoice">Vendor Bill</option>
                      <option value="out_refund">Customer Credit Note</option>
                      <option value="in_refund">Vendor Credit Note</option>
                      <option value="entry">Journal Entry</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Partner <span className="text-red-500">*</span>
                    </label>
                    <select
                      value={formData.partner_id}
                      onChange={(e) => {
                        console.log("📝 Partner selected:", e.target.value);
                        setFormData({ ...formData, partner_id: e.target.value });
                      }}
                      className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    >
                      <option value="">
                        {partners.length === 0
                          ? "-- No partners available --"
                          : "-- Select Partner --"}
                      </option>
                      {partners.map((partner) => {
                        console.log("🔄 Rendering partner option:", partner.name);
                        return (
                          <option key={partner.id} value={partner.id}>
                            {partner.name}
                          </option>
                        );
                      })}
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Invoice Date <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="date"
                      value={formData.invoice_date}
                      onChange={(e) =>
                        setFormData({ ...formData, invoice_date: e.target.value })
                      }
                      className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Due Date
                    </label>
                    <input
                      type="date"
                      value={formData.invoice_date_due}
                      onChange={(e) =>
                        setFormData({ ...formData, invoice_date_due: e.target.value })
                      }
                      className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Reference
                    </label>
                    <input
                      type="text"
                      value={formData.ref}
                      onChange={(e) =>
                        setFormData({ ...formData, ref: e.target.value })
                      }
                      placeholder="Invoice reference number"
                      className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700">
                      Journal <span className="text-red-500">*</span>
                    </label>
                    <select
                      value={formData.journal_id}
                      onChange={(e) =>
                        setFormData({ ...formData, journal_id: e.target.value })
                      }
                      className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                    >
                      <option value="">
                        {journals.length === 0
                          ? "-- No journals available --"
                          : "-- Select Journal --"}
                      </option>
                      {journals.map((journal) => (
                        <option key={journal.id} value={journal.id}>
                          {journal.name} ({journal.code})
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="mt-4">
                  <label className="block text-sm font-medium text-gray-700">
                    Notes
                  </label>
                  <textarea
                    value={formData.narration}
                    onChange={(e) =>
                      setFormData({ ...formData, narration: e.target.value })
                    }
                    rows={3}
                    placeholder="Additional notes or terms"
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                  />
                </div>
              </Box>

              {/* Invoice Lines */}
              <Box className="p-6 mt-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-gray-900">
                    Invoice Lines <span className="text-red-500">*</span>
                  </h3>
                  <button
                    type="button"
                    onClick={addLine}
                    className="inline-flex items-center rounded-lg bg-green-600 px-3 py-2 text-sm font-medium text-white hover:bg-green-700"
                  >
                    <PlusIcon className="mr-2 h-4 w-4" />
                    Add Line
                  </button>
                </div>

                <div className="space-y-4">
                  {lines.map((line) => (
                    <div
                      key={line.id}
                      className="grid grid-cols-1 gap-4 rounded-lg border border-gray-200 p-4 sm:grid-cols-6"
                    >
                      <div className="sm:col-span-2">
                        <label className="block text-sm font-medium text-gray-700">
                          Description <span className="text-red-500">*</span>
                        </label>
                        <input
                          type="text"
                          value={line.name}
                          onChange={(e) =>
                            updateLine(line.id, "name", e.target.value)
                          }
                          placeholder="Product or service description"
                          className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700">
                          Account <span className="text-red-500">*</span>
                        </label>
                        <select
                          value={line.account_id}
                          onChange={(e) =>
                            updateLine(line.id, "account_id", e.target.value)
                          }
                          className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                        >
                          <option value="">
                            {accounts.length === 0
                              ? "-- No accounts --"
                              : "-- Select --"}
                          </option>
                          {accounts.map((account) => (
                            <option key={account.id} value={account.id}>
                              {account.name}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700">
                          Qty
                        </label>
                        <input
                          type="number"
                          value={line.quantity}
                          onChange={(e) =>
                            updateLine(line.id, "quantity", parseFloat(e.target.value) || 0)
                          }
                          min="0"
                          step="0.01"
                          className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700">
                          Unit Price
                        </label>
                        <input
                          type="number"
                          value={line.price_unit}
                          onChange={(e) =>
                            updateLine(line.id, "price_unit", parseFloat(e.target.value) || 0)
                          }
                          min="0"
                          step="0.01"
                          className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                        />
                      </div>

                      <div className="flex items-end gap-2">
                        <div className="flex-1">
                          <label className="block text-sm font-medium text-gray-700">
                            Discount %
                          </label>
                          <input
                            type="number"
                            value={line.discount}
                            onChange={(e) =>
                              updateLine(line.id, "discount", parseFloat(e.target.value) || 0)
                            }
                            min="0"
                            max="100"
                            step="0.01"
                            className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                          />
                        </div>
                        <button
                          type="button"
                          onClick={() => removeLine(line.id)}
                          disabled={lines.length === 1}
                          className="rounded-lg border border-red-300 p-2 text-red-600 hover:bg-red-50 disabled:opacity-50"
                        >
                          <TrashIcon className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>

                {/* Total */}
                <div className="mt-6 flex justify-end">
                  <div className="w-64">
                    <div className="flex justify-between text-lg font-semibold">
                      <span>Total:</span>
                      <span>
                        {new Intl.NumberFormat("vi-VN", {
                          style: "currency",
                          currency: "VND",
                        }).format(calculateTotal())}
                      </span>
                    </div>
                  </div>
                </div>
              </Box>
            </div>
          </div>
        </form>
      </div>
    </Page>
  );
}