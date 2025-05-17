// Local Imports
import { ItemCard } from "./ItemCard";

// ----------------------------------------------------------------------

const items = [
  {
    uid: "1",
    cover: "/images/800x600.png",
    name: "The Runner #265",
    expirySeconds: 33153,
    highestBid: 1.49,
    isLiked: false,
    artist: {
      name: "Travis Fuller",
      avatar: "/images/200x200.png",
      itemsCount: 1259,
    },
  },
  {
    uid: "2",
    cover: "/images/800x600.png",
    name: "Punkiber #015",
    expirySeconds: 10098,
    highestBid: 11.06,
    isLiked: true,
    artist: {
      name: "Katrina West",
      avatar: "/images/200x200.png",
      itemsCount: 965,
    },
  },
  {
    uid: "3",
    cover: "/images/800x600.png",
    name: "Cube Store #015",
    expirySeconds: 108960,
    highestBid: 7.23,
    isLiked: false,
    artist: {
      name: "Raul Bradley",
      avatar: "/images/200x200.png",
      itemsCount: 1269,
    },
  },
  {
    uid: "4",
    cover: "/images/800x600.png",
    name: "Abstraktio #699",
    expirySeconds: 190320,
    highestBid: 3.09,
    isLiked: false,
    artist: {
      name: "Henry Curtis",
      avatar: "/images/200x200.png",
      itemsCount: 163,
    },
  },
  {
    uid: "5",
    cover: "/images/800x600.png",
    name: "Galaxy #236",
    expirySeconds: 363780,
    highestBid: 1.17,
    isLiked: true,
    artist: {
      name: "Lance Tucker",
      avatar: null,
      itemsCount: 533,
    },
  },
  {
    uid: "6",
    cover: "/images/800x600.png",
    name: "Avrang #965",
    expirySeconds: 526260,
    highestBid: 23.67,
    isLiked: false,
    artist: {
      name: "Henry Curtis",
      avatar: "/images/200x200.png",
      itemsCount: 669,
    },
  },
];

export function Feeds() {
  return (
    <div>
      <div className="flex min-w-0 items-center justify-between">
        <h3 className="min-w-0 text-xl font-medium text-gray-800 dark:text-dark-50">
          Feed
        </h3>
        <a
          href="##"
          className="border-b border-dotted border-current pb-0.5 text-xs-plus font-medium text-primary-600 outline-hidden transition-colors duration-300 hover:text-primary-600/70 focus:text-primary-600/70 dark:text-primary-400 dark:hover:text-primary-400/70 dark:focus:text-primary-400/70"
        >
          View All
        </a>
      </div>
      <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:grid-cols-3 lg:gap-6">
        {items.map((item) => (
          <ItemCard key={item.uid} {...item} />
        ))}
      </div>
    </div>
  );
}
