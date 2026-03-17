#!/bin/bash
# Post-build script to fix URL-encoded filenames in Flutter web builds
# This fixes issues where Flutter URL-encodes filenames with spaces or special characters

echo "🔧 Fixing URL-encoded filenames in build/web/assets..."

# Function to decode URL-encoded filenames
fix_encoded_names() {
    local dir="$1"
    if [ -d "$dir" ]; then
        cd "$dir" || return
        for file in *%*; do
            if [ -e "$file" ]; then
                decoded=$(python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" <<< "$file")
                if [ "$file" != "$decoded" ]; then
                    mv "$file" "$decoded"
                    echo "  ✓ Renamed: $file → $decoded"
                fi
            fi
        done
        cd - > /dev/null || return
    fi
}

# Fix all asset directories
fix_encoded_names "build/web/assets/assets/svg"
fix_encoded_names "build/web/assets/assets/icon"
fix_encoded_names "build/web/assets/assets/images"
fix_encoded_names "build/web/assets/packages/mediku/assets/svg"
fix_encoded_names "build/web/assets/packages/mediku/assets/icon"
fix_encoded_names "build/web/assets/packages/mediku/assets/images"

echo "✅ Done fixing filenames!"
