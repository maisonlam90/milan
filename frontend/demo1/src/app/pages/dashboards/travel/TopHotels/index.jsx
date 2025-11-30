// Local Imports
import { HotelCard } from "./HotelCard";

// ----------------------------------------------------------------------

const hotels = [
  {
    uid: 1,
    cover: "/images/800x600.png",
    name: "Emerald Bay Inn.",
    tag: "plus",
    price: 100,
    rating: 4.9,
    bedsCount: 3,
    adultCount: 3,
  },
  {
    uid: 2,
    cover: "/images/800x600.png",
    name: "Crowne Plaza.",
    tag: "lux",
    price: 80,
    rating: 4.8,
    bedsCount: 2,
    adultCount: 4,
  },
  {
    uid: 3,
    cover: "/images/800x600.png",
    name: "Sunset Lodge.",
    tag: "penthouse",
    price: 100,
    rating: 4.9,
    bedsCount: 3,
    adultCount: 3,
  },
  {
    uid: 4,
    cover: "/images/800x600.png",
    name: "Hotel Elite.",
    tag: "plus",
    price: 120,
    rating: 4.9,
    bedsCount: 1,
    adultCount: 2,
  },
  {
    uid: 5,
    cover: "/images/800x600.png",
    name: "Hotel Bliss.",
    tag: "lux",
    price: 90,
    rating: 4.5,
    bedsCount: 2,
    adultCount: 4,
  },
  {
    uid: 6,
    cover: "/images/800x600.png",
    name: "Emerald Bay Inn.",
    tag: "plus",
    price: 100,
    rating: 4.9,
    bedsCount: 3,
    adultCount: 3,
  },
  {
    uid: 7,
    cover: "/images/800x600.png",
    name: "Crowne Plaza.",
    tag: "lux",
    price: 80,
    rating: 4.8,
    bedsCount: 2,
    adultCount: 4,
  },
  {
    uid: 8,
    cover: "/images/800x600.png",
    name: "Sunset Lodge.",
    tag: "penthouse",
    price: 100,
    rating: 4.9,
    bedsCount: 3,
    adultCount: 3,
  },
  {
    uid: 9,
    cover: "/images/800x600.png",
    name: "Hotel Elite.",
    tag: "plus",
    price: 120,
    rating: 4.9,
    bedsCount: 1,
    adultCount: 2,
  },
  {
    uid: 10,
    cover: "/images/800x600.png",
    name: "Hotel Bliss.",
    tag: "lux",
    price: 90,
    rating: 4.5,
    bedsCount: 2,
    adultCount: 4,
  },
];

export function TopHotels() {
  return (
    <div className="transition-content mt-4 pl-(--margin-x) sm:mt-5 lg:mt-6">
      <div className="rounded-l-lg bg-gray-150 pb-1 pt-4 dark:bg-dark-800">
        <h2 className="truncate px-4 text-base font-medium tracking-wide text-gray-800 dark:text-dark-100 sm:px-5 lg:text-lg">
          Top Hotels
        </h2>
        <div
          className="custom-scrollbar mt-4 flex space-x-4 overflow-x-auto px-4 pb-4 sm:px-5 "
          style={{ "--margin-scroll": "1.25rem" }}
        >
          {hotels.map((hotel) => (
            <HotelCard
              key={hotel.uid}
              cover={hotel.cover}
              name={hotel.name}
              tag={hotel.tag}
              price={hotel.price}
              rating={hotel.rating}
              bedsCount={hotel.bedsCount}
              adultCount={hotel.adultCount}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
