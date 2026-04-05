#!/usr/bin/env python3
"""
Gemini Image Generation — テキストから画像を生成する

使い方:
  python3 generate_image.py "プロンプト" [出力ファイル名] [オプション...]

オプション:
  --model <model_id>           モデルID（デフォルト: gemini-3-pro-image-preview）
  --aspect-ratio <ratio>       アスペクト比（例: 16:9, 1:1, 9:16）
  --image-size <size>          画像サイズ（例: 1K, 2K, 4K）
"""

import argparse
import os
import sys

from google import genai
from google.genai import types


def load_env():
    """プロジェクトルートの .env を読み込む（1Password Environments の FIFO 対応）"""
    if os.environ.get("GEMINI_API_KEY"):
        return
    from dotenv import load_dotenv
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_file = os.path.normpath(os.path.join(script_dir, "..", "..", "..", "..", ".env"))
    load_dotenv(env_file)


def main():
    parser = argparse.ArgumentParser(description="Gemini 画像生成（text-to-image）")
    parser.add_argument("prompt", help="画像生成プロンプト")
    parser.add_argument("output", nargs="?", default="generated_image.png", help="出力ファイル名")
    parser.add_argument("--model", default="gemini-3-pro-image-preview", help="モデルID")
    parser.add_argument("--aspect-ratio", default=None, help="アスペクト比（例: 16:9, 1:1, 9:16）")
    parser.add_argument("--image-size", default=None, help="画像サイズ（例: 1K, 2K, 4K）")
    args = parser.parse_args()

    load_env()

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("エラー: GEMINI_API_KEY が設定されていません。", file=sys.stderr)
        sys.exit(1)

    client = genai.Client(api_key=api_key)

    print("🍌 Nano Banana 画像生成中...")
    print(f"   モデル: {args.model}")
    print(f"   プロンプト: {args.prompt}")

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
            contents=args.prompt,
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
            print(f"\n✅ 画像を保存しました: {args.output}")

    if not image_saved:
        print("\n⚠️  画像が生成されませんでした。テキストのみのレスポンスです。", file=sys.stderr)
        print("   プロンプトを調整するか、モデルを変更してみてください。", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
