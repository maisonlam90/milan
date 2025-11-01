```jsx
// Import Dependencies
import { register } from "swiper/element/bundle";

// Local Imports
import { randomId } from "utils/randomId";
import { useLocaleContext } from "app/contexts/locale/context";

// ----------------------------------------------------------------------

register();

const images = [
  { id: randomId(), img: "/images/800x600.png" },
  { id: randomId(), img: "/images/800x600.png" },
  { id: randomId(), img: "/images/800x600.png" },
  { id: randomId(), img: "/images/800x600.png" },
];

export function Card() {
  const { direction } = useLocaleContext();

  return (
    <div className="w-10/12 max-w-md">
      <swiper-container
        effect="cards"
        navigation="true"
        grabCursor="true"
        slides-per-view="1"
        dir={direction}
      >
        {images.map(({ img, id }) => (
          <swiper-slide key={id}>
            <img
              className="h-full w-full rounded-lg object-cover"
              src={img}
              alt="object"
              loading="lazy"
            />
          </swiper-slide>
        ))}
      </swiper-container>
    </div>
  );
}
```