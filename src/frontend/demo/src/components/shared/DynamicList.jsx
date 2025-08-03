import { ArrowPathIcon } from "@heroicons/react/24/outline";
import {
  flexRender,
  getCoreRowModel,
  getFacetedRowModel,
  getFacetedUniqueValues,
  getFilteredRowModel,
  getSortedRowModel,
  getPaginationRowModel,
  useReactTable,
} from "@tanstack/react-table";
import { useDeferredValue, useState } from "react";
import PropTypes from "prop-types";
import { rankItem } from "@tanstack/match-sorter-utils";

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

const fuzzyFilter = (row, columnId, value, addMeta) => {
  const itemRank = rankItem(row.getValue(columnId), value);
  addMeta({ itemRank });
  return itemRank.passed;
};

export default function DynamicList({ columns, data, onRowClick }) {
  const [sorting, setSorting] = useState([]);
  const [globalFilter, setGlobalFilter] = useState("");
  const [columnFilters, setColumnFilters] = useState([]);
  const deferredGlobalFilter = useDeferredValue(globalFilter);

  // Map columns từ metadata sang format React Table
  const tableColumns = columns.map((col) => ({
    accessorKey: col.key,
    header: col.label,
    filterFn: fuzzyFilter,
  }));

  const table = useReactTable({
    data,
    columns: tableColumns,
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
    getPaginationRowModel: getPaginationRowModel(),
    globalFilterFn: fuzzyFilter,
    getCoreRowModel: getCoreRowModel(),
    initialState: {
      pagination: { pageSize: 20 }, // Mặc định 20 dòng/trang
    },
  });

  return (
    <div>
      {/* Search */}
      <div className="flex items-center justify-between">
        <h2 className="truncate text-base font-medium tracking-wide text-gray-800 dark:text-dark-100">
          Tìm kiếm
        </h2>
        <div className="flex">
          <CollapsibleSearch
            placeholder="Nhập từ khóa..."
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

      {/* Table */}
      <Card className="mt-3">
        {data.length === 0 ? (
          <p className="p-4 text-gray-500">Không có dữ liệu</p>
        ) : (
          <>
            <div className="min-w-full overflow-x-auto">
              <Table hoverable className="w-full text-left rtl:text-right">
                <THead>
                  {table.getHeaderGroups().map((headerGroup) => (
                    <Tr key={headerGroup.id}>
                      {headerGroup.headers.map((header) => (
                        <Th
                          key={header.id}
                          className="bg-gray-200 pb-2 font-semibold uppercase text-gray-800 dark:bg-dark-800 dark:text-dark-100"
                        >
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
                    <Tr
                      key={row.id}
                      className="cursor-pointer hover:bg-gray-100"
                      onClick={() => onRowClick && onRowClick(row.original)}
                    >
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

            {/* Pagination */}
            <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200 dark:border-dark-700">
              {/* Chọn số dòng/trang */}
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-700 dark:text-gray-300">
                  Hiển thị:
                </span>
                <select
                  className="border rounded-md px-2 py-1 text-sm"
                  value={table.getState().pagination.pageSize}
                  onChange={(e) =>
                    table.setPageSize(Number(e.target.value))
                  }
                >
                  {[20, 50, 100, 500, 1000].map((size) => (
                    <option key={size} value={size}>
                      {size} dòng
                    </option>
                  ))}
                </select>
              </div>

              {/* Thông tin trang */}
              <span className="text-sm text-gray-700 dark:text-gray-300">
                Trang <b>{table.getState().pagination.pageIndex + 1}</b> /{" "}
                <b>{table.getPageCount()}</b>
              </span>

              {/* Nút phân trang */}
              <div className="space-x-2">
                <Button
                  variant="outlined"
                  size="sm"
                  disabled={!table.getCanPreviousPage()}
                  onClick={() => table.previousPage()}
                >
                  Previous
                </Button>
                <Button
                  variant="outlined"
                  size="sm"
                  disabled={!table.getCanNextPage()}
                  onClick={() => table.nextPage()}
                >
                  Next
                </Button>
              </div>
            </div>
          </>
        )}
      </Card>
    </div>
  );
}

DynamicList.propTypes = {
  columns: PropTypes.array.isRequired,
  data: PropTypes.array.isRequired,
  onRowClick: PropTypes.func, // callback khi bấm vào dòng
};

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
