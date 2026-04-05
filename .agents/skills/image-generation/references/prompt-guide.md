# Nano Banana Pro プロンプトガイド

画像生成プロンプトの詳細な書き方と用途別テンプレート集。
**プロンプトは英語で書くこと**（英語の方が生成精度が高い）。

---

## 基本原則

### 1. 具体的かつ詳細に書く

曖昧な指示は曖昧な結果を生む。以下の要素を意識して含める:

- **被写体**: 何を描くか（人物、物、風景、抽象）
- **構図**: カメラアングル、距離感、フレーミング
- **スタイル**: 写真風、イラスト、水彩画、3Dレンダリング等
- **色調・雰囲気**: 暖色系、クール、ミニマル、レトロ等
- **テキスト**: 画像内に入れたい文字（ある場合）

悪い例:
```
A stylish cafe image
```

良い例:
```
Interior photo of a Scandinavian-style cafe with natural light streaming in.
White walls and wooden tables. A latte with latte art and a croissant
placed on a window-side seat. Shallow depth of field with blurred background.
Warm color tones.
```

### 2. カメラ・写真用語を活用する

Nano Banana Proは写真用語への反応が特に良い:

| カテゴリ | 有効な用語例 |
|---------|-------------|
| アングル | low angle, high angle, bird's eye view, eye level, dutch angle |
| レンズ | wide-angle lens, telephoto lens, macro lens, fisheye lens, 35mm, 85mm |
| 被写界深度 | shallow depth of field, bokeh, deep focus, blurred background |
| ライティング | natural light, golden hour, backlight, rim light, studio lighting |
| 質感 | matte finish, glossy, metallic, textured, glass-like |

### 3. スタイル指定のパターン

```
# Photographic
"Photo taken with a DSLR camera. Natural light, shallow depth of field."

# Illustration
"Flat design vector illustration. Pastel colors. No outlines."

# 3D Rendering
"3D rendered isometric illustration. Soft shadows. Miniature style."

# Watercolor
"Landscape painted in transparent watercolor. Composition utilizing bleeding and white space."

# Manga / Anime
"Japanese anime style. Cel shading. Vivid colors."
```

---

## 写真風画像の生成

写真品質の画像を生成する際のテンプレート:

```
[Detailed description of the subject].
[Camera settings: lens, angle, depth of field].
[Lighting: type and direction of light source].
[Color tone and mood].
[Additional instructions: no text, no watermark, etc.]
```

例:
```
Night view of Tokyo Shibuya Scramble Crossing. Neon lights reflecting
on the rain-soaked road surface. Slightly elevated angle. 35mm lens.
Long exposure with pedestrians creating motion blur trails.
Cyan and magenta color tones. Cinematic atmosphere.
```

---

## 日本語テキスト入り画像

Nano Banana Proの最大の強みの一つが日本語テキストの高精度レンダリング。

### テキスト指示の書き方

1. **テキスト内容は引用符で明確に囲む**
2. **フォントスタイルを指定する**（Gothic, Mincho, handwritten等）
3. **配置を指定する**（top center, bottom left, full screen等）
4. **サイズ感を指示する**（large, small, 1/3 of the screen等）

良い例:
```
Place "春の特別セール" in large white Gothic bold text at the top center of the image.
Add a subtle drop shadow to the text for better readability.
Below it, add "3/1〜3/31 全品20%OFF" in smaller text.
```

悪い例:
```
Add some sale text
```

### 日本語テキストの精度を上げるコツ

- 1つの画像に入れるテキスト量は少なめにする（多すぎると崩れやすい）
- 長い文章より短いキャッチコピーの方が精度が高い
- フォントの種類を指定すると安定する
- テキストの色と背景のコントラストを指示に含める
- 文字数が多い場合は "Render this text exactly as written" と強調する

---

## ビジネス用途別テンプレート

### サムネイル / アイキャッチ

```
Landscape image for YouTube thumbnail (16:9).
[Description of person/object] on the left side.
"[Title text]" in large bold Gothic font on the right side.
White text color with semi-transparent black gradient behind the text.
Background is a [color/pattern] gradient.
High-impact design that is readable even at small sizes.
```

### 商品モックアップ

```
Professional product photography. Studio shot on white background.
[Detailed description of the product] centered in the frame.
Soft studio lighting. Natural and soft product shadows.
Product label with "[Brand name / Product name]" text.
High resolution, catalog-quality image.
```

### インフォグラフィック / 図解

```
Business infographic. White background.
Title "[Title]" placed prominently at the top.
[Number] key points arranged vertically, each with
an icon and a short description.
Color scheme based on [brand colors].
Flat design. Clean and professional layout.
```

### 不動産・物件広告

```
Luxurious real estate advertisement image.
[Description of building exterior/interior] displayed prominently.
Semi-transparent banner at the bottom of the image with
"[Property name]" and "[Catchphrase]" in white text.
"[Company name / Logo]" placed small in the bottom right corner.
Professional photographer quality.
```

### SNS投稿用バナー

```
Square image for Instagram post (1:1).
[Description of product/service photo].
"[Main copy]" placed large at the top of the image.
"[Sub copy / CTA]" placed smaller at the bottom.
Brand color [color] used as accent.
Stylish and sophisticated design.
```

### 飲食店メニュー

```
Restaurant menu photo.
[Dish name] as the main subject. Slightly angled overhead shot.
"[Menu item name]" and "[Price]" placed next to the dish
in a handwritten-style font.
Wooden table as background with warm color tones.
Appetizing natural light photography.
```

---

## 画像編集のプロンプト

画像編集（`image_to_image.py`）で使う場合の指示パターン:

### 背景の変更
```
Keep the subject of this image as is, and change only the background to [description of new background].
Blend the edges of the subject naturally with the new background.
```

### テキストの追加
```
Add "[Text content]" in [font style] at the [position: top/bottom/center] of this image.
Text color is [color], with [shadow/outline/decoration].
Preserve the original mood of the image.
```

### スタイル変換
```
Convert this photo to [style: watercolor / anime / pop art] style.
Maintain the subject's features and composition.
```

### 部分的な編集
```
Change [specific part] of this image to [description of change].
Do not modify any other part of the image.
```

---

## よくある失敗と対策

### 日本語テキストが崩れる

対策:
- テキスト量を減らす（1画像につき2〜3フレーズまで）
- "Render this text exactly as written, character by character" と強調する
- フォントの種類を明示する
- Nano Banana Pro（gemini-3-pro-image-preview）の方が日本語精度が高い

### 意図と違う画像が生成される

対策:
- プロンプトの各要素を改行で区切り、構造化する
- "not X, but Y" のネガティブ指示を活用する
- 参考画像がある場合は `image_to_image.py` で参照させる

### 人物がリアルすぎる / 不気味の谷

対策:
- "illustration style" や "3D rendered style" などスタイルを指定する
- 人物が不要な場合は "no people" と明記する

### 画像サイズ・アスペクト比が合わない

対策:
- プロンプトに明示する: "landscape 16:9", "square 1:1", "portrait 9:16"
- 用途を書く: "for YouTube thumbnail", "for Instagram Story"
