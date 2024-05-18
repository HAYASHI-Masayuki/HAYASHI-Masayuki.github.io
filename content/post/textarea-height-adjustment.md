---
title: "テキストエリアの高さを内容に合わせて自動でリサイズするおそらくベストな方法"
date: 2024-05-18T17:10:09+09:00
publishDate: 2024-05-18
draft: false
---

この間テキストエリアの高さを内容に合わせて自動でリサイズしたい、という要件があり実装したのですが、いまいちうまく実装できませんでした。ので、もう少し調査・実験してみて、おそらくベストかなと思える方法に辿り着きました。

サンプルコードを見ていただければわかるように、実はとてもシンプルに実装できます。

肝は2点、

1. 内容の高さは`scrollHeight`として取得できるので、それと内容以外の高さを計算して`textarea`の`height`を設定すれば、適切な高さになる。
2. 内容以外の高さを計算するには、`box-sizing`次第で`border`か`padding`の高さを計算する必要がある。

たったこれだけの話だったのですが、答えに辿り着くまでに結構かかりました。HTML/CSS力がまだまだ足りません。


```html
<!DOCTYPE html>
<html>
  <head>
    <title>テキストエリアの高さを内容に合わせて自動でリサイズするサンプル</title>
    <style>
      #textarea {
        /* この3つの値をどのように変更しても、適切にリサイズされる */
        box-sizing: content-box;
        border-width: 4px;
        padding: 16px;
      }
    </style>
    <script>
      const getTextAreaOuterHeight = (textarea) => {
        const style = getComputedStyle(textarea)

        // ここが重要で、border-box(texteareaではデフォルト)の場合は「ちょうど」の
        // 高さは内容の高さ + ボーダーの高さだが、content-boxの場合は内容の高さ -
        // パディングの高さ、となる。
        return style.boxSizing === 'border-box'
          ? parseInt(style.borderTopWidth) + parseInt(style.borderBottomWidth)
          : - (parseInt(style.paddingTop) + parseInt(style.paddingBottom))
      }

      const adjustTextAreaHeight = (textarea) => {
        // 一度リセットしないと、scrollHeightが縮まない
        textarea.style.height = 0

        // テキストエリアの高さ = 内容の高さ + 内容以外の高さとする
        textarea.style.height = (parseInt(textarea.scrollHeight) + getTextAreaOuterHeight(textarea)) + 'px'
      }

      // 後は必要なタイミングで調整するよう設定する
      document.addEventListener('DOMContentLoaded', () => {
        const textarea = document.querySelector('#textarea')

        adjustTextAreaHeight(textarea)
        textarea.addEventListener('input', e => adjustTextAreaHeight(e.target))
      })
    </script>
  </head>
  <body>
    <textarea id="textarea"></textarea>
  </body>
</html>
```


{{< license >}}


