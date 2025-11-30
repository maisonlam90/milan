// Import Dependencies
import { Link } from "react-router-dom";

// Local Imports
import { Button } from "components/ui";

// ----------------------------------------------------------------------

const Polymorphic = () => {
  return (
    <Button component={Link} to="/elements/avatar" color="primary" isGlow>
      Primary
    </Button>
  );
};

export { Polymorphic };
