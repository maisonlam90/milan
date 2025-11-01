// Import Dependencies
import { register } from "swiper/element/bundle";
import invariant from "tiny-invariant";
import { useRef } from "react";

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

export function PaginationExample() {
  const { primaryColorScheme: primary } = useThemeContext();
  const { direction } = useLocaleContext();

  const carouselRef = useRef(null);

  useIsomorphicEffect(() => {
    invariant(carouselRef.current, "carouselRef is null");
    const params = {
      pagination: {
        clickable: true,
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
        style={{
          "--swiper-theme-color": primary[400],
          "--swiper-pagination-color": primary[600],
        }}
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
