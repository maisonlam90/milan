import { useState, useEffect, useCallback } from "react";
import { Page } from "components/shared/Page";
import { Card, Button } from "components/ui";
import axios from "axios";
import { JWT_HOST_API } from "configs/auth.config";
import { Table } from "antd";

const api = axios.create({ baseURL: JWT_HOST_API });

export default function LoanReportPage() {
  const [pivot, setPivot] = useState([]);
  const [loading, setLoading] = useState(false);
  const token = localStorage.getItem("authToken");

  const fetchPivot = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get("/loan/report", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setPivot(res.data || []);
    } catch (err) {
      console.error("❌ Pivot API error:", err);
      alert("❌ Lỗi khi tải báo cáo pivot.");
    } finally {
      setLoading(false);
    }
  }, [token]);

  const handlePivotNow = async () => {
    setLoading(true);
    try {
      await api.post("/loan/report/pivot-now", null, {
        headers: { Authorization: `Bearer ${token}` },
      });
      await fetchPivot();
    } catch {
      alert("❌ Lỗi khi tính toán lãi và tạo báo cáo.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPivot();
  }, [fetchPivot]);

  const columns = [
    { title: "Contract ID", dataIndex: "contract_id", key: "contract_id" },
    { title: "Date", dataIndex: "date", key: "date" },
    { title: "Principal", dataIndex: "current_principal", key: "current_principal" },
    { title: "Interest", dataIndex: "current_interest", key: "current_interest" },
    { title: "Accumulated", dataIndex: "accumulated_interest", key: "accumulated_interest" },
    { title: "Paid Interest", dataIndex: "total_paid_interest", key: "total_paid_interest" },
    { title: "Paid Principal", dataIndex: "total_paid_principal", key: "total_paid_principal" },
    { title: "Payoff Due", dataIndex: "payoff_due", key: "payoff_due" },
    { title: "State", dataIndex: "state", key: "state" },
  ];

  return (
    <Page title="📊 Báo cáo Pivot">
      <div className="px-4 py-6 space-y-6">
        <Button onClick={handlePivotNow} disabled={loading}>
          🔄 Tính lãi & tạo báo cáo
        </Button>

        <Card>
          <Table
            columns={columns}
            dataSource={pivot}
            rowKey={(r) => `${r.contract_id}-${r.date}`}
            loading={loading}
            pagination={false}
            scroll={{ x: true }}
          />
        </Card>
      </div>
    </Page>
  );
}
