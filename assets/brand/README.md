# Brand assets

- `luqma_light.png` — maroon/gold wordmark, used on light backgrounds.
- `luqma_dark.png` — cream/gold wordmark, used on dark backgrounds.
- `apple.svg`, `google.svg`, `facebook.svg` — social sign-in icons.

`AppLogo` (`lib/core/widgets/app_logo.dart`) picks the right wordmark for the
active theme and scales it to the screen. Asset paths live in `AppAssets`.
