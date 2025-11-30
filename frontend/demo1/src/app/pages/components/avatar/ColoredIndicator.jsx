import { Avatar, AvatarDot } from "components/ui";

const ColoredIndicator = () => {
  return (
    <div className="inline-space">
      <Avatar
        src="/images/200x200.png"
        indicator={<AvatarDot className="right-0" />}
      />
      <Avatar
        src="/images/200x200.png"
        indicator={<AvatarDot color="primary" className="right-0" />}
      />
      <Avatar
        src="/images/200x200.png"
        indicator={<AvatarDot color="secondary" className="right-0" />}
      />
      <Avatar
        src="/images/200x200.png"
        indicator={<AvatarDot color="info" className="right-0" />}
      />
      <Avatar
        src="/images/200x200.png"
        indicator={<AvatarDot color="success" className="right-0" />}
      />
      <Avatar
        src="/images/200x200.png"
        indicator={<AvatarDot color="warning" className="right-0" />}
      />
      <Avatar
        src="/images/200x200.png"
        indicator={<AvatarDot color="error" className="right-0" />}
      />
    </div>
  );
};

export { ColoredIndicator };
