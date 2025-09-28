```jsx
// Import Dependencies
import { register } from "swiper/element/bundle";
import { useRef } from "react";
import invariant from "tiny-invariant";

// Local Imports
import { randomId } from "utils/randomId";
import { useThemeContext } from "app/contexts/theme/context";
import { useLocaleContext } from "app/contexts/locale/context";
import { useIsomorphicEffect } from "hooks";

// ----------------------------------------------------------------------

register();

const images = [
  { id: randomId(), img: "/images/800x600.png" },
  { id: randomId(), img: "/images/800x600.png" },
  { id: randomId(), img: "/images/800x600.png" },
  { id: randomId(), img: "/images/800x600.png" },
];

export function WithScrollbar() {
  const { direction } = useLocaleContext();

  const carouselRef = useRef(null);

  useIsomorphicEffect(() => {
    invariant(carouselRef.current, "carouselRef is null");
    const params = {
      scrollbar: {
        draggable: true,
      },
    };

    Object.assign(carouselRef.current, params);

    setTimeout(() => {
      carouselRef.current.initialize();
    });
  }, []);

  return (
    <div className="max-w-md">
      <swiper-container
        ref={carouselRef}
        init="false"
        space-between="16"
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