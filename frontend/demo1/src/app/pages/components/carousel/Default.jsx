// Import Dependencies
import { useRef } from "react";
import { register } from "swiper/element/bundle";
import invariant from "tiny-invariant";

// Local Imports
import { randomId } from "utils/randomId";
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

export function Default() {
  const { direction } = useLocaleContext();

  const carouselRef = useRef(null);

  useIsomorphicEffect(() => {
    invariant(carouselRef.current, "carouselRef is null");
    const params = {
      navigation: {
        size: 16,
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
        slides-per-view="1"
        dir={direction}
        space-between="16"
        style={{ "--swiper-navigation-size": "32px" }}
      >
        {images.map(({ img, id }) => (
          <swiper-slide key={id}>
            <img alt="object" src={img} loading="lazy" className="rounded-lg" />
          </swiper-slide>
        ))}
      </swiper-container>
    </div>
  );
}
