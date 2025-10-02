// Import Dependencies
import {
  Menu,
  MenuButton,
  MenuItem,
  MenuItems,
  Transition,
} from "@headlessui/react";
import { EllipsisHorizontalIcon } from "@heroicons/react/20/solid";
import clsx from "clsx";
import { Fragment, useEffect, useState, useMemo } from "react";
import axios from "axios";

// Local Imports
import { Button, Card } from "@/components/ui";
import { ContractStatusCard } from "./ContractStatusCard";
import { ColorType } from "@/constants/app";
import { JWT_HOST_API } from "@/configs/auth";

// ----------------------------------------------------------------------

interface TeamMember {
  id: string;
  name: string;
  avatar?: string;
}

export interface Project {
  id: number;
  name: string;
  description: string;
  color: ColorType;
  category: string;
  progress: number;
  created_at: string;
  count?: number;
  teamMembers: TeamMember[];
}

export function ContractStatus() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);

  const token = useMemo(
    () => (typeof window !== "undefined" ? localStorage.getItem("authToken") || "" : ""),
    []
  );

  const fetchContractStatus = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const res = await axios.get(`${JWT_HOST_API}/loan/contract-status`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setProjects(res.data || []);
    } catch (error) {
      console.error("Error fetching contract status:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchContractStatus();
  }, [token]);

  return (
    <Card className="col-span-12 lg:col-span-8">
      <div className="flex min-w-0 items-center justify-between px-4 py-3">
        <h2 className="dark:text-dark-100 min-w-0 font-medium tracking-wide text-gray-800">
          Trạng thái hợp đồng vay
        </h2>
        <ActionMenu onRefresh={fetchContractStatus} />
      </div>
      <div className="grid grid-cols-1 gap-y-4 pb-3 sm:grid-cols-3">
        {loading ? (
          // Loading skeleton
          Array.from({ length: 3 }).map((_, index) => (
            <div key={index} className="animate-pulse">
              <div className="h-32 bg-gray-200 dark:bg-dark-600 rounded-lg"></div>
            </div>
          ))
        ) : (
          projects.map((project) => (
            <ContractStatusCard key={project.id} {...project} />
          ))
        )}
      </div>
    </Card>
  );
}

function ActionMenu({ onRefresh }: { onRefresh: () => void }) {
  return (
    <Menu
      as="div"
      className="relative inline-block text-left ltr:-mr-1.5 rtl:-ml-1.5"
    >
      <MenuButton
        as={Button}
        variant="flat"
        isIcon
        className="size-8 rounded-full"
      >
        <EllipsisHorizontalIcon className="size-5" />
      </MenuButton>
      <Transition
        as={Fragment}
        enter="transition ease-out"
        enterFrom="opacity-0 translate-y-2"
        enterTo="opacity-100 translate-y-0"
        leave="transition ease-in"
        leaveFrom="opacity-100 translate-y-0"
        leaveTo="opacity-0 translate-y-2"
      >
        <MenuItems className="dark:border-dark-500 dark:bg-dark-700 absolute z-100 mt-1.5 min-w-[10rem] rounded-lg border border-gray-300 bg-white py-1 shadow-lg shadow-gray-200/50 outline-hidden focus-visible:outline-hidden ltr:right-0 rtl:left-0 dark:shadow-none">
          <MenuItem>
            {({ focus }) => (
              <button
                onClick={onRefresh}
                className={clsx(
                  "flex h-9 w-full items-center px-3 tracking-wide outline-hidden transition-colors",
                  focus &&
                    "dark:bg-dark-600 dark:text-dark-100 bg-gray-100 text-gray-800",
                )}
              >
                <span>Làm mới dữ liệu</span>
              </button>
            )}
          </MenuItem>
        </MenuItems>
      </Transition>
    </Menu>
  );
}
