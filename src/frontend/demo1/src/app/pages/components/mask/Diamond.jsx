import { Avatar } from "components/ui";

const Diamond = () => {
  return (
    <Avatar
      size={24}
      src="/images/200x200.png"
      classNames={{ display: "mask is-diamond rounded-none" }}
    />
  );
};

export { Diamond };
