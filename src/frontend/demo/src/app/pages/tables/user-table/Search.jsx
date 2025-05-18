// Import Dependencies
import { ArrowPathIcon } from "@heroicons/react/24/outline";
import { rankItem } from "@tanstack/match-sorter-utils";
import {
  flexRender,
  getCoreRowModel,
  getFacetedRowModel,
  getFacetedUniqueValues,
  getFilteredRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import { useDeferredValue, useEffect, useMemo, useState } from "react";
import axios from "axios";
import PropTypes from "prop-types";

// Local Imports
import { CollapsibleSearch } from "components/shared/CollapsibleSearch";
import { TableSortIcon } from "components/shared/table/TableSortIcon";
import { ColumnFilter } from "components/shared/table/ColumnFilter";
import {
  Button,
  Card,
  Table,
  THead,
  TBody,
  Th,
  Tr,
  Td,
} from "components/ui";
import { JWT_HOST_API } from "configs/auth.config";

// ----------------------------------------------------------------------

const api = axios.create({ baseURL: JWT_HOST_API });

const fuzzyFilter = (row, columnId, value, addMeta) => {
  const itemRank = rankItem(row.getValue(columnId), value);
  addMeta({ itemRank });
  return itemRank.passed;
};

export function Search() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  const [sorting, setSorting] = useState([]);
  const [globalFilter, setGlobalFilter] = useState("");
  const [columnFilters, setColumnFilters] = useState([]);

  const deferredGlobalFilter = useDeferredValue(globalFilter);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const token = localStorage.getItem("authToken"); // ✅ đúng key bạn đang dùng
        const res = await api.get("/user/users", {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });
        setUsers(res.data || []);
      } catch (err) {
        console.error("❌ Lỗi lấy danh sách user:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchUsers();
  }, []);

  const data = useMemo(() => [...users], [users]);

  const columns = useMemo(
    () => [
      {
        accessorKey: "user_id",
        header: "ID",
        filterFn: fuzzyFilter,
      },
      {
        accessorKey: "name",
        header: "Tên",
        filterFn: fuzzyFilter,
      },
      {
        accessorKey: "email",
        header: "Email",
        filterFn: fuzzyFilter,
      },
      {
        accessorKey: "created_at",
        header: "Ngày tạo",
        cell: (info) =>
          new Date(info.getValue()).toLocaleDateString("vi-VN"),
      },
    ],
    []
  );

  const table = useReactTable({
    data,
    columns,
    state: {
      sorting,
      columnFilters,
      globalFilter: deferredGlobalFilter,
    },
    filterFns: { fuzzy: fuzzyFilter },
    onSortingChange: setSorting,
    getSortedRowModel: getSortedRowModel(),
    onColumnFiltersChange: setColumnFilters,
    getFacetedRowModel: getFacetedRowModel(),
    getFacetedUniqueValues: getFacetedUniqueValues(),
    onGlobalFilterChange: setGlobalFilter,
    getFilteredRowModel: getFilteredRowModel(),
    globalFilterFn: fuzzyFilter,
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <div>
      <div className="flex items-center justify-between">
        <h2 className="truncate text-base font-medium tracking-wide text-gray-800 dark:text-dark-100">
          Column Search
        </h2>
        <div className="flex">
          <CollapsibleSearch
            placeholder="Search here..."
            value={globalFilter ?? ""}
            onChange={(e) => setGlobalFilter(e.target.value)}
          />
          <Button
            onClick={() => {
              table.resetColumnFilters();
              table.resetGlobalFilter();
              table.resetSorting();
            }}
            variant="flat"
            isIcon
            className="size-8 rounded-full"
          >
            <ArrowPathIcon className="size-4.5" />
          </Button>
        </div>
      </div>

      <Card className="mt-3">
        {loading ? (
          <p className="p-4 text-gray-500">⏳ Đang tải dữ liệu...</p>
        ) : (
          <div className="min-w-full overflow-x-auto">
            <Table hoverable className="w-full text-left rtl:text-right">
              <THead>
                {table.getHeaderGroups().map((headerGroup) => (
                  <Tr key={headerGroup.id}>
                    {headerGroup.headers.map((header) => (
                      <Th key={header.id} className="bg-gray-200 pb-2 font-semibold uppercase text-gray-800 dark:bg-dark-800 dark:text-dark-100">
                        {header.column.getCanSort() ? (
                          <HeaderSort header={header} />
                        ) : header.isPlaceholder ? null : (
                          flexRender(
                            header.column.columnDef.header,
                            header.getContext()
                          )
                        )}

                        {header.column.getCanFilter() ? (
                          <ColumnFilter column={header.column} />
                        ) : null}
                      </Th>
                    ))}
                  </Tr>
                ))}
              </THead>
              <TBody>
                {table.getRowModel().rows.map((row) => (
                  <Tr key={row.id}>
                    {row.getVisibleCells().map((cell) => (
                      <Td key={cell.id}>
                        {flexRender(
                          cell.column.columnDef.cell,
                          cell.getContext()
                        )}
                      </Td>
                    ))}
                  </Tr>
                ))}
              </TBody>
            </Table>
          </div>
        )}
      </Card>
    </div>
  );
}

function HeaderSort({ header }) {
  return (
    <div
      className="flex cursor-pointer select-none items-center space-x-2"
      onClick={header.column.getToggleSortingHandler()}
    >
      <span className="flex-1">
        {header.isPlaceholder
          ? null
          : flexRender(header.column.columnDef.header, header.getContext())}
      </span>
      <TableSortIcon sorted={header.column.getIsSorted()} />
    </div>
  );
}

HeaderSort.propTypes = {
  header: PropTypes.object,
};
