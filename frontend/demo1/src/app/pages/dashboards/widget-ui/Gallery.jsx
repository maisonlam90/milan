// Local Imports
import { Card } from "components/ui";

// ----------------------------------------------------------------------

export function Gallery() {
  return (
    <Card className="p-3">
      <div className="grid grid-cols-3 gap-3">
        <img
          src="/images/800x600.png"
          className="rounded-lg object-cover object-center"
          alt="galley item"
        />
        <img
          src="/images/800x600.png"
          className="rounded-lg object-cover object-center"
          alt="galley item"
        />
        <img
          src="/images/800x600.png"
          className="rounded-lg object-cover object-center"
          alt="galley item"
        />
        <img
          src="/images/800x600.png"
          className="rounded-lg object-cover object-center"
          alt="galley item"
        />
        <img
          src="/images/800x600.png"
          className="rounded-lg object-cover object-center"
          alt="galley item"
        />
        <img
          src="/images/800x600.png"
          className="rounded-lg object-cover object-center"
          alt="galley item"
        />
      </div>
    </Card>
  );
}
