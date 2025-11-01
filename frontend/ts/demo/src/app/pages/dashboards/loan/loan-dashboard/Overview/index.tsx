// /home/milan/milan/src/frontend/ts/demo/src/app/pages/dashboards/loan/loan-dashboard/Overview/index.tsx
import { Radio, RadioGroup } from "@headlessui/react";
import clsx from "clsx";
import { useEffect, useMemo, useState } from "react";
import axios from "axios";

import { Box } from "@/components/ui";
import { Info } from "./Info";
import { SalesChart } from "./SalesChart";
import { JWT_HOST_API } from "@/configs/auth";

type Range = "monthly" | "yearly";
type SeriesItem = { name: string; data: number[] };

// ✅ Chuẩn hoá categories thành number[] hoặc string[]
function toAxisCategories(input: unknown): number[] | string[] {
  if (!Array.isArray(input)) return [];
  const arr = input.filter((v) => v !== null && v !== undefined);
  const allNumbers = arr.every((v) => typeof v === "number");
  if (allNumbers) return arr as number[];
  return arr.map(String);
}

export function Overview() {
  const [activeRange, setActiveRange] = useState<Range>("monthly");
  // ❗ Quan trọng: state là number[] | string[] (không phải (string|number)[])
  const [categories, setCategories] = useState<number[] | string[]>([]);
  const [series, setSeries] = useState<SeriesItem[]>([
    { name: "Loan Issued", data: [] },
    { name: "Loan Repaid", data: [] },
  ]);
  const [loading, setLoading] = useState(false);

  const token =
    typeof window !== "undefined" ? localStorage.getItem("authToken") : null;

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        setLoading(true);

        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth() + 1;

        const params =
          activeRange === "monthly"
            ? { year, range: "monthly", month }
            : { year, range: "yearly" };

        const baseUrl = JWT_HOST_API.endsWith("/")
          ? JWT_HOST_API
          : `${JWT_HOST_API}/`;
        const url = `${baseUrl}loan/stats`;

        const res = await axios.get(url, {
          headers: token ? { Authorization: `Bearer ${token}` } : {},
          params,
        });

        if (!mounted) return;

        const payload = res.data ?? {};
        // ✅ ép về number[] | string[] để khớp props của SalesChart
        setCategories(toAxisCategories(payload.categories));

        setSeries(
          Array.isArray(payload.series) && payload.series.length > 0
            ? payload.series
            : [
                { name: "Loan Issued", data: [] },
                { name: "Loan Repaid", data: [] },
              ]
        );
      } catch (err) {
        if (!mounted) return;
        console.error("❌ Lỗi lấy thống kê Overview:", err);
        setCategories([]);
        setSeries([
          { name: "Loan Issued", data: [] },
          { name: "Loan Repaid", data: [] },
        ]);
      } finally {
        if (mounted) setLoading(false);
      }
    })();
    return () => {
      mounted = false;
    };
  }, [activeRange, token]);

  const memoSeries = useMemo(() => series, [series]);
  const memoCategories = useMemo(() => categories, [categories]);

  return (
    <Box className="col-span-12 lg:col-span-8">
      <div className="flex min-w-0 items-center justify-between gap-2">
        <h2 className="truncate text-base font-medium tracking-wide text-gray-800 dark:text-dark-100">
          Sales Overview
        </h2>

        <RadioGroup
          name="options"
          value={activeRange}
          onChange={setActiveRange}
          className="flex rounded-lg bg-gray-200 p-1 text-gray-600 dark:bg-dark-800 dark:text-dark-200"
        >
          <Radio
            value="monthly"
            className={({ checked }) =>
              clsx(
                "shrink-0 cursor-pointer rounded-lg px-3 py-1 text-xs-plus font-medium outline-hidden",
                checked
                  ? "bg-white shadow-sm dark:bg-dark-500 dark:text-gray-100"
                  : "hover:text-gray-800 focus:text-gray-800 dark:hover:text-dark-100 dark:focus:text-dark-100"
              )
            }
          >
            Last Month
          </Radio>
          <Radio
            value="yearly"
            className={({ checked }) =>
              clsx(
                "shrink-0 cursor-pointer rounded-lg px-3 py-1 text-xs-plus font-medium outline-hidden",
                checked
                  ? "bg-white shadow-sm dark:bg-dark-500 dark:text-gray-100"
                  : "hover:text-gray-800 focus:text-gray-800 dark:hover:text-dark-100 dark:focus:text-dark-100"
              )
            }
          >
            Last Year
          </Radio>
        </RadioGroup>
      </div>

      <div className="flex flex-col sm:flex-row sm:gap-7">
        <Info />
        {/* 👉 đổi key theo range để Apex animate lại khi chuyển phạm vi */}
        <SalesChart key={activeRange} series={memoSeries} categories={memoCategories} />
      </div>

      {loading && (
        <p className="mt-2 text-xs text-gray-500 dark:text-dark-300">
          Đang tải dữ liệu…
        </p>
      )}
    </Box>
  );
}
