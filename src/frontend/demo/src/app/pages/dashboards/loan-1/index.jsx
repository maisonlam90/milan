import { useEffect, useState, useCallback } from "react";
import { Page } from "components/shared/Page";
import { Breadcrumbs } from "components/shared/Breadcrumbs";
import { Card } from "components/ui";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import DynamicList from "components/shared/DynamicList";

const breadcrumbs = [
  { title: "Hợp đồng vay", path: "/loans" },
  { title: "Danh sách" },
];

const api = axios.create({ baseURL: JWT_HOST_API });

export default function LoanListPage() {
  const [contracts, setContracts] = useState([]);
  const [metadata, setMetadata] = useState(null);
  const token = localStorage.getItem("authToken");

  const fetchMetadata = useCallback(async () => {
    const res = await api.get("/loan/metadata");
    setMetadata(res.data);
  }, []);

  const fetchContracts = useCallback(async () => {
    const res = await api.get("/loan/list", {
      headers: { Authorization: `Bearer ${token}` },
    });
    setContracts(res.data);
  }, [token]);

  useEffect(() => {
    fetchMetadata();
    fetchContracts();
  }, [fetchMetadata, fetchContracts]);

  return (
    <Page title="📋 Danh sách hợp đồng vay">
      <div className="transition-content w-full px-(--margin-x) pb-8">
        <div className="flex items-center space-x-4 py-5 lg:py-6 ">
          <h2 className="text-xl font-medium tracking-wide text-gray-800 dark:text-dark-50 lg:text-2xl">
            Danh sách hợp đồng vay
          </h2>
          <div className="hidden self-stretch py-1 sm:flex">
            <div className="h-full w-px bg-gray-300 dark:bg-dark-600"></div>
          </div>
          <Breadcrumbs items={breadcrumbs} className="max-sm:hidden" />
        </div>

        {metadata && metadata.list ? (
          <DynamicList columns={metadata.list.columns} data={contracts} />
        ) : (
          <Card className="p-6">Đang tải danh sách...</Card>
        )}
      </div>
    </Page>
  );
}
