```jsx
import { Avatar, AvatarDot } from "components/ui";

const WithIndicator = () => {
  return (
    <div className="inline-space">
      <Avatar
        size={8}
        src="/images/200x200.png"
        indicator={<AvatarDot color="primary" className="right-0 size-2.5" />}
      />
      <Avatar
        size={10}
        src="/images/200x200.png"
        indicator={<AvatarDot color="primary" className="right-0 size-3" />}
      />
      <Avatar
        src="/images/200x200.png"
        indicator={<AvatarDot color="primary" className="right-0" />}
      />
      <Avatar
        size={16}
        src="/images/200x200.png"
        indicator={<AvatarDot color="primary" className="right-0 m-0.5" />}
      />
      <Avatar
        size={20}
        src="/images/200x200.png"
        indicator={<AvatarDot color="primary" className="right-0 m-1 size-4" />}
      />
      <Avatar
        size={24}
        src="/images/200x200.png"
        indicator={
          <AvatarDot color="primary" className="right-0 m-1.5 size-4" />
        }
      />
    </div>
  );
};

export { WithIndicator };
```