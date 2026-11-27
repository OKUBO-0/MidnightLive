# 素材と生成条件

## 茶の間

- 使用ファイル：`assets/textures/1989_room.png`。
- 生成方法：組み込み `image_gen.imagegen`（CLI/APIの代替経路は不使用）。
- 用途：タイトル背景、ブラウン管内の1989年の茶の間。
- 原寸画像を保持し、UI表示時のUVで縦横比を保って切り抜く。
- 資料の画像は企画確認用にのみ保存。ゲーム美術として流用していない。

生成プロンプト全文：

```
Use case: historical-scene. Asset type: background image for the interactive CRT television feed in a Japanese psychological horror game titled 深夜0時の生中継. Create a cinematic, realistic empty Japanese grandmother's tatami living room on a winter night in 1989. Composition: fixed camera at seated eye level facing into the room, 4:3 composition within a landscape image, a low dark wooden chabudai table toward the left foreground, a black rotary telephone on a small wooden stand on the right midground, shoji paper screens on the left, a dark open doorway at the center rear and a narrow kitchen doorway at the far right rear; period appropriate modest furniture, calendar on wall with no legible text. Leave open tatami floor space in center foreground and in front of the telephone so game character silhouettes can be overlaid. Lighting: muted sickly sage-green tungsten light, deep dark brown shadows, quiet disturbing absence, restrained desaturated analogue-film photographic realism with subtle grain; room must remain readable. No people, no ghosts, no gore. No television frame, no TV set, no screen border, no UI, no letters, no watermark. Detailed material textures, eerie beautiful composition, late night Japanese domestic realism. Output a single room image.
```

## 電話・人物・画面

黒電話、CRTの木枠、二人の子ども、走査線、紙のメモ、ボタン、字幕は、
`tools/build_game.mjs` から生成する編集可能なネイティブUI。
状態変化とLuaのUIアニメーションを使用しており、UI全体を画像に焼き込んだものではない。

## 音

`tools/make_audio.py` で生成した27種類のWAV。乱数シード19891224。
数字別の回転ダイヤル10種、受話器、切断音、発信音、呼出音、話中音、ベル、番組予告等。
実物の録音ではなく、ばね・接点・ベルの共鳴を近似した合成音。
ダイヤルは10パルス毎秒・0は10パルス。短縮版でも音程は変えない。
発信音は400Hz、呼出音は400Hzの変調を1秒ON/2秒OFF、話中音は0.5秒ON/0.5秒OFF。
可聴音の参考資料： [NTT西日本・電話サービスのインタフェース第6.2版、表3.3.8](https://www.ntt-west.co.jp/gisanshi/analog/pdf/analog_gisanshi_06_02.pdf#page=21)。

日本語台詞はWindowsのインストール済み音声 Microsoft Haruka / Ichiro / Sayaka を使った
試作用の合成音声。`tools/make_voices.ps1`、台詞対応表は `docs/generated/dialogues.json`。
動的な時刻や一部の短い台詞は字幕のみ。

## フォント

Noto Sans JP Regular。既存Uno Engine配布物の同名フォントをコピー。
ライセンス文を `assets/fonts/OFL.txt` に同梱。
公式のライセンス文： https://github.com/google/fonts/blob/main/ofl/notosansjp/OFL.txt

## 実行環境

既存Uno Engine v2.6.1 / DirectX 12 の配布ランタイムを利用。
エンジン本体と依存DLLはこのプロジェクトで新規開発したものではない。
