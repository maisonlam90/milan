// Import Dependencies
import { Cog6ToothIcon } from "@heroicons/react/24/outline";
import clsx from "clsx";

// Local Imports
import { Avatar, Badge, Box, Button } from "@/components/ui";
import { Project } from "./index";

// ----------------------------------------------------------------------

export function ContractStatusCard({
  name,
  description,
  color,
  category,
  progress,
  teamMembers,
  created_at,
}: Project) {
  const progressParts = progress.toFixed(2).toString().split(".");
  return (
    <Box className="relative flex flex-col justify-between min-h-[200px] overflow-hidden">
      {/* Thanh màu bên trái kéo dài toàn bộ chiều cao của Box */}
      <div 
        className={clsx(
          `this:${color}`,
          "absolute left-0 top-0 bottom-0 w-1 bg-this dark:bg-this-light"
        )}
      />
      
      <div className="pl-6 pr-4 py-4 flex flex-col justify-between h-full">
        <div>
          <p className="dark:text-dark-100 text-base font-medium text-gray-800">
            {name}
          </p>
          <p className="dark:text-dark-300 text-xs text-gray-400">
            {description}
          </p>
          <Badge color={color} variant="outlined" className="mt-2">
            {category}
          </Badge>
        </div>
        <div className="mt-8">
          <div>
            <p>
              <span className="dark:text-dark-100 text-2xl font-medium text-gray-800">
                %{progressParts[0]}.
              </span>
              <span className="text-xs">{progressParts[1]}</span>
            </p>
            <p className="mt-1 text-xs">{created_at}</p>
          </div>
        </div>
        <div className="mt-8 flex items-center justify-between gap-2">
          <div className="flex -space-x-2.5">
            {teamMembers.map((member) => (
              <Avatar
                key={member.id}
                src={member.avatar}
                name={member.name}
                size={7}
                classNames={{
                  root: "origin-bottom transition-transform hover:z-10 hover:scale-125",
                  display: "dark:ring-dark-700 text-xs ring-2 ring-white",
                }}
                initialColor="auto"
              />
            ))}
          </div>

          <Button
            className="size-7 rounded-full ltr:-mr-1.5 rtl:-ml-1.5"
            isIcon
            variant="flat"
          >
            <Cog6ToothIcon className="size-5" />
          </Button>
        </div>
      </div>
    </Box>
  );
}
