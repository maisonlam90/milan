// Local Imports
import Logo from "assets/appLogo.svg?react";
import { Progress } from "components/ui";

// ----------------------------------------------------------------------

export function SplashScreen() {
  const hasMetadataCache = !!localStorage.getItem("loanMetadata");

  // Nếu metadata đã cache → không hiện splash nữa
  if (hasMetadataCache) return null;

  return (
    <div className="fixed inset-0 z-50 grid place-content-center bg-white dark:bg-dark-900">
      <Logo className="size-28" />
      <Progress
        color="primary"
        isIndeterminate
        animationDuration="1s"
        className="mt-2 h-1"
      />
    </div>
  );
}
