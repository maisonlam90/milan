// Local Imports
import { ProductCard } from "./ProductCard";

// ----------------------------------------------------------------------

const products = [
  {
    uid: "1",
    image: "/images/800x600.png",
    name: "Duck Salad",
    category: "Pizza",
    price: "35.00",
  },
  {
    uid: "2",
    image: "/images/800x600.png",
    name: "Breakfast board",
    category: "Taco",
    price: "14.00",
  },
  {
    uid: "3",
    image: "/images/800x600.png",
    name: "Hummus",
    category: "Sandwich",
    price: "24.00",
  },
  {
    uid: "4",
    image: "/images/800x600.png",
    name: "Roast beef",
    category: "Kebab",
    price: "17.50",
  },
  {
    uid: "5",
    image: "/images/800x600.png",
    name: "Tuna salad",
    category: "Popcorn",
    price: "35.00",
  },
  {
    uid: "6",
    image: "/images/800x600.png",
    name: "Salmon",
    category: "Burger",
    price: "48.00",
  },
  {
    uid: "7",
    image: "/images/800x600.png",
    name: "California roll",
    category: "Taco",
    price: "74.00",
  },
  {
    uid: "8",
    image: "/images/800x600.png",
    name: "Sashimi",
    category: "Burrito",
    price: "74.00",
  },
  {
    uid: "9",
    image: "/images/800x600.png",
    name: "Pub salad",
    category: "Salad",
    price: "62.00",
  },
  {
    uid: "10",
    image: "/images/800x600.png",
    name: "Duck carpaccio",
    category: "Popcorn",
    price: "16.00",
  },
  {
    uid: "11",
    image: "/images/800x600.png",
    name: "Maui food",
    category: "Hot Dog",
    price: "32.00",
  },
  {
    uid: "12",
    image: "/images/800x600.png",
    name: "Scottish salmon",
    category: "Burger",
    price: "36.00",
  },
];

export function Products() {
  return (
    <div className="mt-4 grid grid-cols-2 gap-4 sm:mt-5 sm:gap-5 lg:mt-6 lg:grid-cols-3 xl:grid-cols-4">
      {products.map((product) => (
        <ProductCard key={product.uid} {...product} />
      ))}
    </div>
  );
}
