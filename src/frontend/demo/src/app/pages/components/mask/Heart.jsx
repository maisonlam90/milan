import { Avatar } from "components/ui";

const Heart = () => {
  return (
    <Avatar
      size={24}
      src="/images/200x200.png"
      classNames={{ display: "mask is-heart rounded-none" }}
    />
  );
};

export { Heart };
