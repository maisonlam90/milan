// Import Dependencies
import { Link } from "react-router-dom";

// Local Imports
import { Avatar, AvatarDot } from "components/ui";

// ----------------------------------------------------------------------

const Polymorphic = () => {
  return (
    <Avatar
      component={Link}
      to="/settings/general"
      src="/images/200x200.png"
      indicator={<AvatarDot className="right-0" color="error" />}
    />
  );
};

export { Polymorphic };
