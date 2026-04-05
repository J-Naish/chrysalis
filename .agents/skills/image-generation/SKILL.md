---
name: image-generation
description: ユーザーが画像を生成・編集したい場合に使用します。ユーザーが「画像生成」「AI画像」「サムネイル作成」「バナー作成」「ポスター作成」「アイキャッチ」「図解」「インフォグラフィック」「商品画像」「モックアップ」「イラスト生成」「写真生成」「画像編集」「Nano Banana」「Geminiで画像」に言及した場合にも使用します。
---

# 画像生成・編集

あなたはAI画像生成の専門家です。Google Nano Banana Pro（Gemini 3 Pro Image）APIを使い、ユーザーの要求に応じた高品質な画像を生成・編集します。

## Nano Banana Proの強み

- **日本語テキストの高精度レンダリング**: ポスター、図解、サムネイルに正確な日本語を直接描画
- **高品質な写真風画像**: 自然な光、奥行き、質感のリアルな画像を生成
- **画像編集**: 参照画像を読み込み、合成・編集・スタイル変換が可能
- **テキスト入り画像**: ロゴ、キャッチコピー、説明文を画像内に正確に配置

---

## 前提条件

- プロジェクトルートの `.env` に `GEMINI_API_KEY` が設定されていること（スクリプトが自動読み込み）
- `uv` がインストール済みであること（依存パッケージは `uv run --with` で自動解決される）

APIキーは Google AI Studio（https://aistudio.google.com/apikey）から取得する。

---

## モデルの選択

| モデル | モデルID | 用途 |
|--------|---------|------|
| **Nano Banana Pro** | `gemini-3-pro-image-preview` | 最高品質。本番用途すべてにこちらを使う（デフォルト） |
| **Nano Banana** | `gemini-3.1-flash-image-preview` | 高速・低コスト。デモや一時確認など本番で使わない用途のみ |

常に `gemini-3-pro-image-preview`（デフォルト）を使用する。`gemini-3.1-flash-image-preview` はデモ・プロトタイプ・一時的な確認など、本番に使わない場面でのみ使用する。

### モデル別の対応仕様

| 仕様 | Nano Banana Pro (`3-pro`) | Nano Banana (`3.1-flash`) |
|------|--------------------------|---------------------------|
| **アスペクト比** | `1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `4:5`, `5:4`, `9:16`, `16:9`, `21:9` | 左記に加え `1:4`, `1:8`, `4:1`, `8:1` |
| **画像サイズ** | `1K`（デフォルト）, `2K`, `4K` | `512px`, `1K`, `2K`, `4K` |
| **参照画像の上限** | 最大11枚（オブジェクト6 + キャラクター5） | 最大14枚（オブジェクト10 + キャラクター4） |
| **テキストレンダリング** | 高精度 | 高精度（インフォグラフィック・図表に特化） |

---

## 基本ワークフロー

### 画像を生成する前に

ユーザーから以下の情報を収集する（未提供なら質問する）:

1. **用途**: 何に使う画像か？（サムネイル、バナー、商品画像、SNS投稿等）
2. **被写体**: 何を描くか？
3. **スタイル**: 写真風、イラスト、3D等の希望はあるか？
4. **テキスト**: 画像内に入れたい文字はあるか？
5. **サイズ・比率**: 横長（16:9）、正方形（1:1）、縦長（9:16）等
6. **参照画像**: 編集したい既存画像や、スタイル・構図の参考にしたい画像はあるか？

### スクリプトの使い分け

| 条件 | 使うスクリプト |
|------|---------------|
| 参照画像なし — ゼロから画像を作る | `text_to_image.py` |
| 参照画像あり — 既存画像の編集（背景変更、テキスト追加、部分修正等） | `image_to_image.py` |
| 参照画像あり — スタイルや構図を参考にして新しい画像を作る | `image_to_image.py` |
| 複数画像を合成・統一したい | `image_to_image.py`（`--images` で複数指定） |

迷ったら: 「参照画像があるか？」で判断する。あれば `image_to_image.py`、なければ `text_to_image.py`。

### テキストから画像を生成する（text-to-image）

`scripts/text_to_image.py`（このスキルディレクトリ内）を使用する:

```bash
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/text_to_image.py "プロンプト" [出力ファイル名] [オプション...]
```

オプション:
| オプション | デフォルト | 説明 |
|-----------|-----------|------|
| `--model` | `gemini-3-pro-image-preview` | モデルID |
| `--aspect-ratio` | なし | アスペクト比（例: `16:9`, `1:1`, `9:16`） |
| `--image-size` | なし | 画像サイズ（`512px`, `1K`, `2K`, `4K`） |

例:
```bash
# 基本的な画像生成（デフォルト: gemini-3-pro-image-preview）
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/text_to_image.py "A cute cat sitting on a windowsill at sunset"

# 出力ファイル名を指定
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/text_to_image.py "Tokyo Tower at night, illuminated against a dark sky, long exposure, city lights below" tokyo_tower.png

# アスペクト比と画像サイズを指定
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/text_to_image.py "Product package mockup on white background, studio lighting, soft shadows" mockup.png --aspect-ratio 1:1 --image-size 2K

# 軽量モデルを使用（デモ・確認用途のみ）
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/text_to_image.py "Simple test image of a red circle" test.png --model gemini-3.1-flash-image-preview
```

### 画像を編集する（image-to-image）

既存の画像を参照して編集する場合は `scripts/image_to_image.py`（このスキルディレクトリ内）を使用する:

```bash
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/image_to_image.py "編集指示のプロンプト" 参照画像パス [出力ファイル名] [オプション...]
```

オプション:
| オプション | デフォルト | 説明 |
|-----------|-----------|------|
| `--model` | `gemini-3-pro-image-preview` | モデルID |
| `--aspect-ratio` | なし | アスペクト比 |
| `--image-size` | なし | 画像サイズ |
| `--images` | なし | 追加の参照画像（複数指定可） |

例:
```bash
# 画像の背景を変更
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/image_to_image.py "Change the background to a cherry blossom avenue in full bloom, blend edges naturally" input.png edited.png

# 画像に日本語テキストを追加
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/image_to_image.py 'Add "春のセール開催中" in large white Gothic bold text at the top center, with a subtle drop shadow' product.png sale_banner.png

# アスペクト比を指定して編集
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/image_to_image.py "Convert to a 16:9 landscape banner, extend the background naturally" product.png banner.png --aspect-ratio 16:9

# 複数の参照画像を使って一貫性のある画像を生成
uv run --with google-genai --with python-dotenv python3 .agents/skills/image-generation/scripts/image_to_image.py "Combine all products into a unified catalog-style image on white background, consistent lighting" product1.png catalog.png --images product2.png product3.png
```

## プロンプト作成の基本原則

**プロンプトは英語で書く**（英語の方が生成精度が高い）。画像内に日本語テキストを入れたい場合のみ、その部分を日本語で記述する。

効果的な画像を生成するための詳細なプロンプトガイドは [references/prompt-guide.md](references/prompt-guide.md) を参照。

### クイックリファレンス

1. **英語で書く**: プロンプトは英語。画像内に日本語を入れたい場合のみ日本語テキストを含める
2. **具体的に書く**: 被写体、構図、スタイル、色、雰囲気を明示する
3. **カメラ用語を使う**: low angle, telephoto lens, bokeh, natural light が有効
4. **日本語テキストは引用符で囲む**: `Place "春のセール" in large bold text at the top`
5. **ネガティブプロンプトも使う**: `no text, no watermark`

### プロンプトの構造テンプレート

```
[被写体の詳細な説明]。
[カメラ設定: レンズ、アングル、被写界深度]。
[ライティング: 光源の種類と方向]。
[色調・雰囲気]。
[追加の指示: テキスト配置、除外要素等]
```

---

## ビジネス活用パターン

| 用途 | プロンプト例 |
|------|-------------|
| サムネイル | `YouTube thumbnail, landscape 16:9. Surprised person on the left, "衝撃の結果" in large bold white text on the right. Gradient background, high contrast` |
| 商品モックアップ | `Minimal product photography on white background. Glass perfume bottle with "SAKURA" label. Soft studio lighting, natural shadow` |
| SNSバナー | `Square image for Instagram post. Cozy cafe interior photo with "GRAND OPEN" text overlay in elegant serif font. Brand accent color` |
| 図解 | `Business flow infographic on white background. 3 steps arranged left to right, each with an icon and short Japanese description` |
| 不動産広告 | `Luxury apartment exterior photo. Semi-transparent banner at bottom with "全室南向き・駅徒歩3分" in white text. Professional real estate photography` |

用途別の詳細なプロンプトテンプレートは [references/prompt-guide.md](references/prompt-guide.md) を参照。

---

## 制限事項

- 生成された画像にはSynthIDの電子透かしが自動的に埋め込まれる
- 人物の生成にはセーフティフィルターが適用される場合がある
- APIにはレート制限がある（詳細は Google AI for Developers のドキュメントを参照）

---

## トラブルシューティング

| 問題 | 対処法 |
|------|--------|
| `GEMINI_API_KEY` が未設定 | プロジェクトルートの `.env` に `GEMINI_API_KEY=your-key` を追加 |
| `google-genai` が見つからない | `uv` がインストールされているか確認する（スクリプトは `uv run --with` で自動解決） |
| 画像が生成されずテキストのみ返る | プロンプトを調整するか、モデルを変更してみる |
| セーフティフィルターでブロック | プロンプトを調整する。人物・暴力的表現を避ける |
| レスポンスが空 | APIキーの有効性とクォータを Google AI Studio で確認 |
| 日本語テキストが崩れる | テキスト量を減らす。`gemini-3-pro-image-preview` に切り替える |
| 意図と違う画像が出る | プロンプトを構造化する。ネガティブ指示を活用する |

---

## タスク固有の質問

1. どんな用途の画像ですか？（サムネイル、バナー、商品画像、SNS投稿等）
2. 画像内にテキストを入れますか？ 入れる場合、何と書きますか？
3. 写真風、イラスト風などスタイルの希望はありますか？
4. アスペクト比の指定はありますか？（16:9、1:1、9:16等）
5. 参照画像や編集したい既存画像はありますか？
6. ブランドカラーやデザインガイドラインはありますか？

---

## 関連スキル

- **copywriting**: 画像内に入れるキャッチコピーやCTA文言の作成
- **landing-page-composition**: LP向けビジュアル素材の要件確認
