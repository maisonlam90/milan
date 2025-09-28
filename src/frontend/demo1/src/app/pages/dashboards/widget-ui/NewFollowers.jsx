// Local Imports
import { Avatar, Card } from "components/ui";

// ----------------------------------------------------------------------

const users = [
  {
    uid: "5",
    name: "Katrina West",
    avatar: "/images/200x200.png",
  },
  {
    uid: "6",
    name: "Henry Curtis",
    avatar: "/images/200x200.png",
  },
  {
    uid: "7",
    name: "Raul Bradley",
    avatar: "/images/200x200.png",
  },
  {
    uid: "8",
    name: "Samantha Shelton",
    avatar: null,
  },
  {
    uid: "9",
    name: "Corey Evans",
    avatar: "/images/200x200.png",
  },
  {
    uid: "10",
    name: "Lance Tucker",
    avatar: null,
  },
  {
    uid: "11",
    name: "Anthony Jensen",
    avatar: "/images/200x200.png",
  },
  {
    uid: "12",
    name: "Anthony Jensen",
    avatar: "/images/200x200.png",
  },
];

export function NewFollowers() {
  return (
    <Card>
      <div className="flex h-14 items-center justify-between px-4 py-3">
        <h2 className="truncate text-sm-plus font-medium tracking-wide text-gray-800 dark:text-dark-100">
          New Followers
        </h2>
      </div>
      <div className="flex gap-x-4 overflow-x-auto px-4 pb-4 text-center">
        {users.map((user) => (
          <div className="text-center" key={user.uid}>
            <Avatar
              size={10}
              src={user.avatar}
              name={user.name}
              color="auto"
              className="align-middle"
            />

            <p className="mt-1.5 w-12 truncate text-xs text-gray-800 dark:text-dark-100">
              {user.name}
            </p>
          </div>
        ))}
      </div>
    </Card>
  );
}
