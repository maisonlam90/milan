import { Avatar } from "components/ui";

const Square = () => {
  return (
    <div className="inline-space">
      <Avatar
        size={8}
        src="/images/200x200.png"
        classNames={{ display: "rounded-lg" }}
      />
      <Avatar
        size={10}
        src="/images/200x200.png"
        classNames={{ display: "rounded-lg" }}
      />

      <Avatar
        src="/images/200x200.png"
        classNames={{ display: "rounded-lg" }}
      />
      <Avatar
        size={16}
        src="/images/200x200.png"
        classNames={{ display: "rounded-lg" }}
      />
      <Avatar
        size={20}
        src="/images/200x200.png"
        classNames={{ display: "rounded-lg" }}
      />
      <Avatar
        size={24}
        src="/images/200x200.png"
        classNames={{ display: "rounded-lg" }}
      />
    </div>
  );
};

export { Square };
