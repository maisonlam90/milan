import Chart from "react-apexcharts";
import { Radio, RadioGroup } from "@headlessui/react";
import { clsx } from "clsx";
import { useEffect, useMemo, useState } from "react";
import axios from "axios";
import { Card, Button } from "components/ui";
import { JWT_HOST_API } from "configs/auth.config";

const BASE_OPTIONS = {
  colors: ["#4C4EE7", "#0EA5E9"],
  chart: {
    toolbar: { show: false },
    // ✅ Bật lại animation “dâng cột”
    animations: {
      enabled: true,
      easing: "easeinout",
      speed: 800,
      animateGradually: { enabled: true, delay: 120 },
      dynamicAnimation: { enabled: true, speed: 350 },
    },
  },
  dataLabels: { enabled: false },
  plotOptions: {
    bar: { borderRadius: 5, barHeight: "90%", columnWidth: "40%" },
  },
  legend: { show: false },
  xaxis: {
    categories: [],
    axisBorder: { show: false },
    axisTicks: { show: false },
    tooltip: { enabled: false },
  },
  grid: { padding: { left: -8, right: -8, top: 0, bottom: -6 } },
  yaxis: {
    axisBorder: { show: false },
    axisTicks: { show: false },
    labels: { show: false },
  },
};

export function SalesReport() {
  const [range, setRange] = useState("monthly"); // daily | monthly | yearly
  const [categories, setCategories] = useState([]);
  const [series, setSeries] = useState([
    { name: "Loan Issued", data: [] },
    { name: "Loan Repaid", data: [] },
  ]);
  const token = localStorage.getItem("authToken");

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth() + 1;
        const day = now.getDate();

        // ✅ monthly/yearly không gửi month; daily mới gửi month(+day)
        const params = { year, range, ...(range === "daily" && { month, day }) };

        const baseUrl = JWT_HOST_API.endsWith("/") ? JWT_HOST_API : JWT_HOST_API + "/";
        const url = baseUrl + "loan/stats";

        const res = await axios.get(url, {
          headers: token ? { Authorization: `Bearer ${token}` } : {},
          params,
        });

        const payload = res.data || {};
        if (!mounted) return;

        setCategories(payload.categories || []);
        setSeries(payload.series || [
          { name: "Loan Issued", data: [] },
          { name: "Loan Repaid", data: [] },
        ]);
      } catch (e) {
        if (!mounted) return;
        console.error("❌ Lỗi lấy thống kê:", e);
        setCategories([]);
        setSeries([
          { name: "Loan Issued", data: [] },
          { name: "Loan Repaid", data: [] },
        ]);
      }
    })();
    return () => { mounted = false; };
  }, [range, token]);

  // Giữ options ổn định, chỉ thay categories
  const options = useMemo(() => {
    return {
      ...BASE_OPTIONS,
      xaxis: { ...BASE_OPTIONS.xaxis, categories },
    };
  }, [categories]);

  return (
    <Card className="col-span-12 sm:col-span-6 lg:col-span-7 xl:col-span-8">
      <div className="mt-3 flex flex-col justify-between gap-2 px-4 sm:flex-row sm:items-center sm:px-5">
        <div className="flex flex-1 items-center justify-between space-x-2 sm:flex-initial ">
          <h2 className="text-sm-plus font-medium tracking-wide text-gray-800 dark:text-dark-100">
            Báo cáo vay vốn
          </h2>
        </div>

        {/* ✅ Nút giữ đúng style bản gốc */}
        <RadioGroup
          name="options"
          value={range}
          onChange={setRange}
          className="flex flex-wrap -space-x-px "
        >
          <Radio
            as={Button}
            unstyled={true}
            value="daily"
            className={({ checked }) =>
              clsx(
                "h-8 border border-gray-300 px-3 text-xs-plus text-gray-800 dark:border-dark-450 dark:text-dark-100 first:ltr:rounded-l-lg last:ltr:rounded-r-lg first:rtl:rounded-r-lg last:rtl:rounded-l-lg",
                checked && "bg-gray-200 dark:bg-surface-2",
              )
            }
          >
            Daily
          </Radio>
          <Radio
            as={Button}
            unstyled={true}
            value="monthly"
            className={({ checked }) =>
              clsx(
                "h-8 border border-gray-300 px-3 text-xs-plus text-gray-800 dark:border-dark-450 dark:text-dark-100 first:ltr:rounded-l-lg last:ltr:rounded-r-lg first:rtl:rounded-r-lg last:rtl:rounded-l-lg",
                checked && "bg-gray-200 dark:bg-surface-2",
              )
            }
          >
            Monthly
          </Radio>
          <Radio
            as={Button}
            unstyled={true}
            value="yearly"
            className={({ checked }) =>
              clsx(
                "h-8 border border-gray-300 px-3 text-xs-plus text-gray-800 dark:border-dark-450 dark:text-dark-100 first:ltr:rounded-l-lg last:ltr:rounded-r-lg first:rtl:rounded-r-lg last:rtl:rounded-l-lg",
                checked && "bg-gray-200 dark:bg-surface-2",
              )
            }
          >
            Yearly
          </Radio>
        </RadioGroup>
      </div>

      <div className="ax-transparent-gridline pr-2">
        {/* 👉 key={range} để đảm bảo animate mỗi khi đổi range */}
        <Chart key={range} type="bar" height="260" options={options} series={series} />
      </div>
    </Card>
  );
}
