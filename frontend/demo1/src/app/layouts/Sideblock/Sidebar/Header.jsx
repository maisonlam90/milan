// Import Dependencies
import { Link } from "react-router-dom";
import { ChevronLeftIcon } from "@heroicons/react/24/outline";

// Local Imports
import Logo from "assets/appLogo.svg?react";
import { Button } from "components/ui";
import { useSidebarContext } from "app/contexts/sidebar/context";

// ----------------------------------------------------------------------

export function Header() {
  const { close } = useSidebarContext();
  return (
    <header className="relative flex h-[61px] shrink-0 items-center justify-center ltr:pl-6 ltr:pr-3 rtl:pl-3 rtl:pr-6">
      <div className="flex items-center justify-start gap-4 pt-3">
        <Link to="/">
          <Logo className="size-30 text-primary-600 dark:text-primary-400" />
        </Link>    
      </div>
      <div className="pt-5 xl:hidden">
        <Button
          onClick={close}
          variant="flat"
          isIcon
          className="size-6 rounded-full"
        >
          <ChevronLeftIcon className="size-5 rtl:rotate-180" />
        </Button>
      </div>
    </header>
  );
}
