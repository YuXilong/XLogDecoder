#!/bin/bash

# XLog Decoder - App Icon Generator
# 从1024x1024的源图标生成所有macOS所需尺寸

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
SOURCE_ICON="icon_1024x1024.png"
OUTPUT_DIR="AppIcon.appiconset"

echo "🎨 XLog Decoder App Icon Generator"
echo "=================================="
echo ""

# 检查源文件
if [ ! -f "$SOURCE_ICON" ]; then
    echo -e "${RED}❌ 错误: 找不到源图标文件 $SOURCE_ICON${NC}"
    echo "请将1024x1024的PNG图标命名为 icon_1024x1024.png 并放在当前目录"
    exit 1
fi

echo -e "${GREEN}✓${NC} 找到源图标: $SOURCE_ICON"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
echo -e "${GREEN}✓${NC} 创建输出目录: $OUTPUT_DIR"
echo ""

# 生成各种尺寸
echo "📐 生成图标尺寸..."

declare -a sizes=(
    "16:icon_16x16.png"
    "32:icon_16x16@2x.png"
    "32:icon_32x32.png"
    "64:icon_32x32@2x.png"
    "128:icon_128x128.png"
    "256:icon_128x128@2x.png"
    "256:icon_256x256.png"
    "512:icon_256x256@2x.png"
    "512:icon_512x512.png"
    "1024:icon_512x512@2x.png"
)

for item in "${sizes[@]}"; do
    IFS=':' read -r size filename <<< "$item"
    echo "  生成 ${size}x${size} → $filename"
    sips -z $size $size "$SOURCE_ICON" --out "$OUTPUT_DIR/$filename" > /dev/null 2>&1
done

echo ""
echo -e "${GREEN}✓${NC} 所有尺寸生成完成!"
echo ""

# 生成Contents.json
echo "📝 生成 Contents.json..."

cat > "$OUTPUT_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo -e "${GREEN}✓${NC} Contents.json 创建完成"
echo ""

# 统计信息
file_count=$(ls -1 "$OUTPUT_DIR"/*.png 2>/dev/null | wc -l)
total_size=$(du -sh "$OUTPUT_DIR" | cut -f1)

echo "📊 统计信息:"
echo "  图标文件数: $file_count"
echo "  总大小: $total_size"
echo ""

# 生成.icns文件
echo "🔨 生成 .icns 文件..."
if iconutil -c icns "$OUTPUT_DIR" -o AppIcon.icns 2>/dev/null; then
    echo -e "${GREEN}✓${NC} AppIcon.icns 创建成功"
else
    echo -e "${YELLOW}⚠${NC}  iconutil 失败,跳过 .icns 生成"
fi

echo ""
echo "=================================="
echo -e "${GREEN}🎉 图标生成完成!${NC}"
echo ""
echo "📁 输出文件:"
echo "  - $OUTPUT_DIR/ (包含所有PNG文件)"
echo "  - AppIcon.icns (可选)"
echo ""
echo "📌 下一步:"
echo "  1. 将 $OUTPUT_DIR 文件夹复制到 Xcode 项目的 Assets.xcassets/"
echo "  2. 或者使用 AppIcon.icns 文件"
echo ""
