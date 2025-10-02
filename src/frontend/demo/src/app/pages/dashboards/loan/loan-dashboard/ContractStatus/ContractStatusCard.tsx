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
  count,
}: Project) {
  const progressParts = progress.toFixed(2).toString().split(".");
  
  // Format số lượng hợp đồng
  const formatCount = (num: number) => {
    return new Intl.NumberFormat("vi-VN").format(num);
  };

  // Tạo progress bar color dựa trên category
  const getProgressBarColor = () => {
    switch (color) {
      case "success": return "bg-green-500";
      case "error": return "bg-red-500";
      case "warning": return "bg-yellow-500";
      case "info": return "bg-blue-500";
      default: return "bg-gray-500";
    }
  };

  return (
    <Box className="relative flex flex-col justify-between min-h-[240px] overflow-hidden">
      {/* Thanh màu bên trái kéo dài toàn bộ chiều cao của Box */}
      <div 
        className={clsx(
          `this:${color}`,
          "absolute left-0 top-0 bottom-0 w-1 bg-this dark:bg-this-light"
        )}
      />
      
      <div className="pl-6 pr-4 py-4 flex flex-col justify-between h-full">
        {/* Header Section */}
        <div>
          <div className="flex items-center justify-between mb-2">
            <p className="dark:text-dark-100 text-base font-medium text-gray-800">
              {name}
            </p>
            <Badge color={color} variant="outlined" className="text-xs">
              {category}
            </Badge>
          </div>
          <p className="dark:text-dark-300 text-sm text-gray-500 mb-3">
            {description}
          </p>
          
          {/* Count Display */}
          <div className="flex items-center gap-2 mb-3">
            <div className={clsx(
              "w-3 h-3 rounded-full",
              color === "success" ? "bg-green-100 dark:bg-green-900" :
              color === "error" ? "bg-red-100 dark:bg-red-900" :
              color === "warning" ? "bg-yellow-100 dark:bg-yellow-900" :
              "bg-blue-100 dark:bg-blue-900"
            )}>
              <div className={clsx(
                "w-2 h-2 rounded-full m-0.5",
                color === "success" ? "bg-green-500" :
                color === "error" ? "bg-red-500" :
                color === "warning" ? "bg-yellow-500" :
                "bg-blue-500"
              )} />
            </div>
            <span className="text-sm font-medium dark:text-dark-200 text-gray-700">
              {formatCount(count || 0)} hợp đồng
            </span>
          </div>
        </div>

        {/* Progress Section */}
        <div className="mt-4">
          <div className="mb-2">
            <p>
              <span className="dark:text-dark-100 text-2xl font-medium text-gray-800">
                %{progressParts[0]}.
              </span>
              <span className="text-xs">{progressParts[1]}</span>
            </p>
          </div>
          
          {/* Progress Bar */}
          <div className="w-full bg-gray-200 dark:bg-dark-600 rounded-full h-2 mb-2">
            <div 
              className={clsx("h-2 rounded-full transition-all duration-300", getProgressBarColor())}
              style={{ width: `${Math.min(progress, 100)}%` }}
            />
          </div>
          
          <p className="text-xs dark:text-dark-300 text-gray-500">
            {created_at}
          </p>
        </div>

        {/* Action Section */}
        <div className="mt-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            {/* Status Indicator */}
            <div className={clsx(
              "px-2 py-1 rounded-full text-xs font-medium",
              color === "success" ? "bg-green-50 text-green-700 dark:bg-green-900/20 dark:text-green-400" :
              color === "error" ? "bg-red-50 text-red-700 dark:bg-red-900/20 dark:text-red-400" :
              color === "warning" ? "bg-yellow-50 text-yellow-700 dark:bg-yellow-900/20 dark:text-yellow-400" :
              "bg-blue-50 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400"
            )}>
              {progress >= 80 ? "Tốt" : progress >= 50 ? "Trung bình" : "Cần cải thiện"}
            </div>
          </div>

          <Button
            className="size-8 rounded-full"
            isIcon
            variant="flat"
            color={color}
          >
            <Cog6ToothIcon className="size-4" />
          </Button>
        </div>
      </div>
    </Box>
  );
}
