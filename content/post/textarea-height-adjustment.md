---
title: "テキストエリアの高さを内容に合わせて自動でリサイズするおそらくベストな方法"
date: 2024-05-18T17:10:09+09:00
publishDate: 2024-05-18
draft: false
---

### 2024-05-23追記

最近のChromeでは、`field-sizing: content`というCSSだけでこの機能を実現できるようです。ほかのブラウザではまだ使えないようですが。

[CSS のフィールド サイズ設定  |  Chrome for Developers](https://developer.chrome.com/docs/css-ui/css-field-sizing?hl=ja)

--- 

### 本文

この間テキストエリアの高さを内容に合わせて自動でリサイズしたい、という要件があり実装したのですが、いまいちうまく実装できませんでした。ので、もう少し調査・実験してみて、おそらくベストかなと思える方法に辿り着きました。

サンプルコードを見ていただければわかるように、実はとてもシンプルに実装できます。

肝は2点、

1. 内容の高さ + `padding`の高さは`scrollHeight`として取得できるので、それと内容以外の高さを計算して`textarea`の`height`を設定すれば、適切な高さになる。
2. `height`として設定すべき値は`border-box`であれば「内容の高さ + `padding`の高さ + `border`の高さ」、`content-box`であれば「内容の高さ」となる。

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
      const getTextAreaHeightForBorderBox = (textarea) => {
        const style = getComputedStyle(textarea)

        // border-boxの高さは、内容の高さ + paddingの高さ + borderの高さ
        // scrollHeightは内容の高さ + paddingの高さなので、
        return parseInt(textarea.scrollHeight) + parseInt(style.borderTopWidth) + parseInt(style.borderBottomWidth)
      }

      const getTextAreaHeightForContentBox = (textarea) => {
        const style = getComputedStyle(textarea)

        // content-boxの高さは、内容の高さ
        // scrollHeightは内容の高さ + paddingの高さなので、
        return parseInt(textarea.scrollHeight) - (parseInt(style.paddingTop) + parseInt(style.paddingBottom))
      }

      const adjustTextAreaHeight = (textarea) => {
        // 一度リセットしないと、scrollHeightが縮まない
        textarea.style.height = 0

        // テキストエリアの隠れている部分も含めた高さを取得・設定する
        textarea.style.height = (
          textarea.style.boxSizing === 'border-box'
            ? getTextAreaHeightForBorderBox(textarea)
            : getTextAreaHeightForContentBox(textarea)
        ) + 'px'
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

なおこのサンプルコードは`box-sizing`がどちらでも自動で対応しますが、通常はどちらかで固定にしていることが多いと思われ、その場合はさらにシンプルな実装になるかと思われます。


{{< license >}}


