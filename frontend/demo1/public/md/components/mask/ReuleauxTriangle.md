```jsx
import { Avatar } from "components/ui";

const ReuleauxTriangle = () => {
  return (
    <Avatar
      size={24}
      src="/images/200x200.png"
      classNames={{ display: "mask is-reuleaux-triangle rounded-none" }}
    />
  );
};

export { ReuleauxTriangle };
```