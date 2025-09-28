import { Avatar } from "components/ui";

const Squircle = () => {
  return (
    <Avatar
      size={24}
      src="/images/200x200.png"
      classNames={{ display: "mask is-squircle rounded-none" }}
    />
  );
};

export { Squircle };
