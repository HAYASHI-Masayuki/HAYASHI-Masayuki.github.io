---
title: "私のコミットメッセージの書き方"
date: 2023-09-21T10:55:22+09:00
publishDate: 2023-09-21
draft: false
---

1. とりあえず書く。
   ```
   管理画面のスクロールをいい感じにした
   ```

2. 管理画面のどこ？
   ```
   管理画面の通知一覧のスクロールをいい感じにした
   ```

3. スクロールをいい感じにってどういうこと？
   ```
   管理画面の通知一覧をキー操作でスクロールするとき、通知の高さによっては下部がスキップされていた
   ```

4. 書ききれなかったことは一行空けて詳細に。
   ```
   管理画面の通知一覧をキー操作でスクロールするとき、通知が表示領域以上の高さを持っ
   ていた場合、下部は見えず次の通知にスクロールされていた。
   
   これでは不便という意見をいただいたので、通知の一部が隠れている場合は次の通知に移
   動せず、通知内でスクロールするようにした。
   
   ほかの画面ではそもそもキー操作によるスクロールはないので、修正不要。
   ```

5. 詳細を書いて気付いたことをフィードバック。
   ```
   管理画面の通知一覧をキー操作でスクロールするとき、通知の一部が隠れている場合は通知内でスクロールするように
   ```

こんな感じです。それほど長くない(特に詳細がない場合)コミットメッセージですが、無限に推敲できてしまいますね。


{{< license >}}


