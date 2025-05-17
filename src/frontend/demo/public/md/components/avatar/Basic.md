```jsx
import { Avatar } from "components/ui";

const Basic = () => {
  return (
    <div className="inline-space">
      <Avatar size={8} src="/images/200x200.png" />
      <Avatar size={10} src="/images/200x200.png" />
      <Avatar src="/images/200x200.png" />
      <Avatar size={16} src="/images/200x200.png" />
      <Avatar size={20} src="/images/200x200.png" />
      <Avatar size={24} src="/images/200x200.png" />
    </div>
  );
};

export { Basic };
```