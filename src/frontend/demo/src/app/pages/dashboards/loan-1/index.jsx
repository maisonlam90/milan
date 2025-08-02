import { useEffect, useState, useCallback } from "react";
import { Page } from "components/shared/Page";
import { Card } from "components/ui";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import DynamicList from "components/shared/DynamicList";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function LoanListPage() {
  const [contracts, setContracts] = useState([]);
  const [metadata, setMetadata] = useState(null);
  const token = localStorage.getItem("authToken");

  /** Lấy metadata (cấu hình cột hiển thị) */
  const fetchMetadata = useCallback(async () => {
    try {
      const res = await api.get("/loan/metadata");
      setMetadata(res.data);
    } catch (err) {
      console.error("❌ Lỗi load metadata:", err);
    }
  }, []);

  /** Lấy danh sách hợp đồng vay */
  const fetchContracts = useCallback(async () => {
    try {
      const res = await api.get("/loan/list", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setContracts(res.data);
    } catch (err) {
      console.error("❌ Lỗi lấy danh sách hợp đồng:", err);
    }
  }, [token]);

  useEffect(() => {
    fetchMetadata();
    fetchContracts();
  }, [fetchMetadata, fetchContracts]);

  return (
    <Page title="📋 Danh sách hợp đồng vay">
      <main className="p-6">
        <Card className="p-6 w-full">
          <h2 className="text-lg font-semibold mb-4">Danh sách hợp đồng vay</h2>
          {metadata && metadata.list ? (
            <DynamicList columns={metadata.list.columns} data={contracts} />
          ) : (
            <p>Đang tải danh sách...</p>
          )}
        </Card>
      </main>
    </Page>
  );
}
