---
title: Image Rendering Test
status: test
---

# Image rendering smoke test

## Relative path image

![Relative screenshot](./screenshot.png)

## Data URI image (tiny red dot)

![Red dot](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFklEQVQYV2P8z8BQz0BKYBw1cjgYCQBitAoLejsIPwAAAABJRU5ErkJggg==)

## Image with alt and title

![Alt text for image](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFklEQVQYV2P8z8BQz0BKYBw1cjgYCQBitAoLejsIPwAAAABJRU5ErkJggg== "Image title attribute")

## Remote image (should be blocked by CSP)

![Remote image](https://example.com/image.png)

## Regular text after images

Text after images should render normally.
