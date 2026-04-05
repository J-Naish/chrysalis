#!/usr/bin/env python3
"""
Gemini Image Edit — 既存画像を参照して編集する

使い方:
  python3 edit_image.py "編集指示" 参照画像パス [出力ファイル名] [オプション...]

オプション:
  --model <model_id>           モデルID（デフォルト: gemini-3-pro-image-preview）
  --aspect-ratio <ratio>       アスペクト比（例: 16:9, 1:1, 9:16）
  --image-size <size>          画像サイズ（例: 1K, 2K, 4K）
  --images <path> [<path>...]  追加の参照画像（Pro: 最大10枚, Flash: 最大13枚）
"""

import argparse
import os
import sys

from google import genai
from google.genai import types


MIME_TYPES = {
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "webp": "image/webp",
    "gif": "image/gif",
}


def load_env():
    """プロジェクトルートの .env を読み込む（1Password Environments の FIFO 対応）"""
    if os.environ.get("GEMINI_API_KEY"):
        return
    from dotenv import load_dotenv
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_file = os.path.normpath(os.path.join(script_dir, "..", "..", "..", "..", ".env"))
    load_dotenv(env_file)


def load_image(path):
    """画像ファイルを読み込み、types.Part として返す"""
    ext = os.path.splitext(path)[1].lower().lstrip(".")
    mime_type = MIME_TYPES.get(ext)
    if not mime_type:
        print(f"エラー: 未対応の画像形式です: .{ext}", file=sys.stderr)
        print(f"  対応形式: {', '.join(MIME_TYPES.keys())}", file=sys.stderr)
        sys.exit(1)

    with open(path, "rb") as f:
        image_data = f.read()

    return types.Part(inline_data=types.Blob(data=image_data, mime_type=mime_type)), mime_type


def main():
    parser = argparse.ArgumentParser(description="Gemini 画像編集（image-to-image）")
    parser.add_argument("prompt", help="編集指示のプロンプト")
    parser.add_argument("image", help="参照画像のファイルパス")
    parser.add_argument("output", nargs="?", default="edited_image.png", help="出力ファイル名")
    parser.add_argument("--model", default="gemini-3-pro-image-preview", help="モデルID")
    parser.add_argument("--aspect-ratio", default=None, help="アスペクト比（例: 16:9, 1:1, 9:16）")
    parser.add_argument("--image-size", default=None, help="画像サイズ（例: 1K, 2K, 4K）")
    parser.add_argument("--images", nargs="+", default=[], help="追加の参照画像（複数可）")
    args = parser.parse_args()

    all_image_paths = [args.image] + args.images
    for img_path in all_image_paths:
        if not os.path.isfile(img_path):
            print(f"エラー: 参照画像が見つかりません: {img_path}", file=sys.stderr)
            sys.exit(1)

    load_env()

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("エラー: GEMINI_API_KEY が設定されていません。", file=sys.stderr)
        sys.exit(1)

    client = genai.Client(api_key=api_key)

    image_parts = []
    for img_path in all_image_paths:
        part, _ = load_image(img_path)
        image_parts.append(part)

    print("🍌 Nano Banana 画像編集中...")
    print(f"   モデル: {args.model}")
    print(f"   参照画像: {', '.join(all_image_paths)}（{len(all_image_paths)}枚）")
    print(f"   編集指示: {args.prompt}")

    image_config_kwargs = {}
    if args.aspect_ratio:
        image_config_kwargs["aspect_ratio"] = args.aspect_ratio
    if args.image_size:
        image_config_kwargs["image_size"] = args.image_size

    config = types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    )
    if image_config_kwargs:
        config.image_config = types.ImageConfig(**image_config_kwargs)

    try:
        response = client.models.generate_content(
            model=args.model,
            contents=[args.prompt] + image_parts,
            config=config,
        )
    except Exception as e:
        print(f"❌ APIエラー: {e}", file=sys.stderr)
        sys.exit(1)

    if not response.candidates or not response.candidates[0].content or not response.candidates[0].content.parts:
        print("❌ レスポンスにパーツが含まれていません。", file=sys.stderr)
        print("   セーフティフィルターでブロックされた可能性があります。", file=sys.stderr)
        sys.exit(1)

    image_saved = False
    for part in response.candidates[0].content.parts:
        if part.text:
            print(f"\n📝 モデルからのテキスト:")
            print(f"   {part.text}")
        elif part.inline_data:
            with open(args.output, "wb") as f:
                f.write(part.inline_data.data)
            image_saved = True
            print(f"\n✅ 編集画像を保存しました: {args.output}")

    if not image_saved:
        print("\n⚠️  画像が生成されませんでした。", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
