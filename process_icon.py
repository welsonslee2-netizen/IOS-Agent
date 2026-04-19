from PIL import Image

img = Image.open('generated-images/Gemini_Generated_Image_ruvz8iruvz8iruvz.png')
w, h = img.size
print(f"原始尺寸: {w}x{h}")

target_size = 1024

# 简单方法：将图片缩放让较短边匹配1024，然后居中裁剪
scale = max(target_size / w, target_size / h)
new_w = int(w * scale)
new_h = int(h * scale)
print(f"缩放后: {new_w}x{new_h}")

resized = img.resize((new_w, new_h), Image.LANCZOS)

# 居中裁剪到 1024x1024
left = (new_w - target_size) // 2
top = (new_h - target_size) // 2
final = resized.crop((left, top, left + target_size, top + target_size))

print(f"最终尺寸: {final.size}")

# 确保是 RGBA 模式
if final.mode != 'RGBA':
    final = final.convert('RGBA')

# 保存
output_path = 'ios/iosagent/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
final.save(output_path, 'PNG')
print(f"DONE: 已保存到: {output_path}")

# 验证 - 检查中心区域（不是边缘）
verify = Image.open(output_path)
cx, cy = 512, 512
print(f"中心像素 ({cx},{cy}): {verify.getpixel((cx,cy))}")
print(f"中心+100 ({cx+100},{cy+100}): {verify.getpixel((cx+100,cy+100))}")
