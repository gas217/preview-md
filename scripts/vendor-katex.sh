#!/bin/sh
# Vendor KaTeX for PreviewMD — downloads JS, CSS, and inlines fonts as data: URIs.
# Produces: Resources/katex.min.js, Resources/katex-auto-render.min.js, Resources/katex.min.css
set -e

VERSION="${1:-0.16.21}"
BASE_URL="https://unpkg.com/katex@$VERSION/dist"
DST="Resources"

echo "==> Fetching KaTeX@$VERSION..."

# JS files (small, no patching needed — KaTeX is CSP-safe)
curl -fsSL "$BASE_URL/katex.min.js" -o "$DST/katex.min.js"
curl -fsSL "$BASE_URL/contrib/auto-render.min.js" -o "$DST/katex-auto-render.min.js"

echo "    katex.min.js: $(wc -c < "$DST/katex.min.js" | tr -d ' ') bytes"
echo "    auto-render.min.js: $(wc -c < "$DST/katex-auto-render.min.js" | tr -d ' ') bytes"

# CSS — download and inline font references as data: URIs
curl -fsSL "$BASE_URL/katex.min.css" -o /tmp/katex-raw.css

# Download all referenced fonts and inline them
mkdir -p /tmp/katex-fonts
echo "    Downloading fonts..."
FONT_COUNT=0
cp /tmp/katex-raw.css /tmp/katex-inlined.css

# Extract font URLs from CSS, download each, base64-encode, replace in CSS
grep -oE 'url\(fonts/[^)]+\)' /tmp/katex-raw.css | sort -u | while read -r url_expr; do
    # Extract path: fonts/KaTeX_Main-Regular.woff2
    font_path=$(echo "$url_expr" | sed 's/url(//;s/)//')
    font_file=$(basename "$font_path")
    font_url="$BASE_URL/$font_path"

    curl -fsSL "$font_url" -o "/tmp/katex-fonts/$font_file" 2>/dev/null || continue

    # Detect format from extension
    ext="${font_file##*.}"
    case "$ext" in
        woff2) mime="font/woff2" ;;
        woff)  mime="font/woff" ;;
        ttf)   mime="font/ttf" ;;
        *)     mime="application/octet-stream" ;;
    esac

    # Base64 encode and replace in CSS
    b64=$(base64 < "/tmp/katex-fonts/$font_file" | tr -d '\n')
    # Escape the font_path for sed (forward slashes)
    escaped_path=$(echo "$font_path" | sed 's/\//\\\//g')
    sed -i '' "s|url($font_path)|url(data:$mime;base64,$b64)|g" /tmp/katex-inlined.css
    FONT_COUNT=$((FONT_COUNT + 1))
done

cp /tmp/katex-inlined.css "$DST/katex.min.css"

echo "    katex.min.css (fonts inlined): $(wc -c < "$DST/katex.min.css" | tr -d ' ') bytes"
echo "==> Done. Files in $DST/"

# Cleanup
rm -rf /tmp/katex-raw.css /tmp/katex-inlined.css /tmp/katex-fonts
