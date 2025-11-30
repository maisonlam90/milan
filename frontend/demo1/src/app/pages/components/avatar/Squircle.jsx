import { Avatar } from "components/ui";

const Squircle = () => {
  return (
    <div className="inline-space">
      <Avatar
        size={8}
        src="/images/200x200.png"
        classNames={{ display: "mask is-squircle rounded-none" }}
      />
      <Avatar
        size={10}
        src="/images/200x200.png"
        classNames={{ display: "mask is-squircle rounded-none" }}
      />

      <Avatar
        src="/images/200x200.png"
        classNames={{ display: "mask is-squircle rounded-none" }}
      />
      <Avatar
        size={16}
        src="/images/200x200.png"
        classNames={{ display: "mask is-squircle rounded-none" }}
      />
      <Avatar
        size={20}
        src="/images/200x200.png"
        classNames={{ display: "mask is-squircle rounded-none" }}
      />
      <Avatar
        size={24}
        src="/images/200x200.png"
        classNames={{ display: "mask is-squircle rounded-none" }}
      />
    </div>
  );
};

export { Squircle };
