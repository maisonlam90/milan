```jsx
import { Avatar } from "components/ui";
import { randomId } from "utils/randomId";

const group = [
  {
    uid: randomId(),
    name: "Konnor Guzman",
    avatar: "/images/200x200.png",
  },
  {
    uid: randomId(),
    name: "Travis Fuller",
    avatar: "/images/200x200.png",
  },
  {
    uid: randomId(),
    name: "Alfredo Elliott",
    avatar: null,
  },
  {
    uid: randomId(),
    name: "Derrick Simmons",
    avatar: "/images/200x200.png",
  },
  {
    uid: randomId(),
    name: "Katrina West",
    avatar: "/images/200x200.png",
  },
  {
    uid: randomId(),
    name: "Henry Curtis",
    avatar: "/images/200x200.png",
  },
];

const AvatarGroup = () => {
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap -space-x-2 ">
        {group.map((item) => (
          <Avatar
            key={item.uid}
            data-tooltip
            data-tooltip-content={item.name}
            size={8}
            name={item.name}
            src={item.avatar}
            classNames={{
              root: "origin-bottom transition-transform hover:z-10 hover:scale-125",
              display: "rounded-xl ring ring-white dark:ring-dark-700",
            }}
          />
        ))}
      </div>

      <div className="flex flex-wrap -space-x-2 ">
        {group.map((item) => (
          <Avatar
            key={item.uid}
            data-tooltip
            data-tooltip-content={item.name}
            size={8}
            name={item.name}
            src={item.avatar}
            classNames={{
              root: "origin-bottom transition-transform hover:z-10 hover:scale-125",
              display: "rounded-full ring ring-white dark:ring-dark-700",
            }}
          />
        ))}
      </div>
    </div>
  );
};

export { AvatarGroup };

```