import { Avatar } from "components/ui";

const Octagon = () => {
  return (
    <Avatar
      size={24}
      src="/images/200x200.png"
      classNames={{ display: "mask is-octagon rounded-none" }}
    />
  );
};

export { Octagon };
