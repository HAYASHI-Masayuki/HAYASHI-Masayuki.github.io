---
title: "Firefoxはiframeを二回初期化するため、contentDocumentを触る場合は待つ必要がある"
date: 2024-05-23T20:41:11+09:00
draft: false
---

あるHTMLドキュメント上に、隔離された別のHTMLドキュメントを生成したい場合に、iframeを使うことがあります。最近は、Shadow DOMでも実現できそうですが。

以下のHTMLを開くと、iframeと、その中に赤い背景のdiv要素が描画されます。

```html
<!DOCTYPE html>
<html>
  <head>
    <script>
      const createRedDiv = () => {
        const div = document.createElement('div')
        div.style.backgroundColor = 'red'
        div.style.height = '100%'

        return div
      }

      window.addEventListener('DOMContentLoaded', () => {
        document.querySelector('#iframe').contentDocument.querySelector('body').appendChild(createRedDiv())
      })
    </script>
  </head>
  <body>
    <iframe id="iframe" />
  </body>
</html>
```

この単純なコードは、しかしFirefoxでは動作しません。何度もリロードしていると、一瞬赤い背景が見えたりはします。

この現象に遭遇したときは、このように最小化されていないもっと複雑なコードだったためか、場合によっては描画されることもありました。どうもタイミングの問題のようでした。

四苦八苦した後、以下のサイトの情報から、これがFirefoxのバグであることを知りました。どうも15年ほど修正されていないようです。

[Iframe immediately recreated | Firefox サポートフォーラム | Mozilla サポート](https://support.mozilla.org/ja/questions/1285797)

[543435 - (sync-about-blank) Make initial about:blank loading into iframe not get overwritten by an async channel load](https://bugzilla.mozilla.org/show_bug.cgi?id=543435)

原因はわかったものの、対策方法は見つかりません。そこで、調査中に見つけていた以下の別の情報をヒントに回避策を無理矢理実装してみました。

[ウィンドウを跨いだやり取り - 現代の JavaScript チュートリアル](https://ja.javascript.info/cross-window-communication#ref-468)

```html
<!DOCTYPE html>
<html>
  <head>
    <script>
      const createRedDiv = () => {
        const div = document.createElement('div')
        div.style.backgroundColor = 'red'
        div.style.height = '100%'

        return div
      }

      window.addEventListener('DOMContentLoaded', () => {
        const iframeOldDocument = document.querySelector('#iframe').contentDocument

        const appendDivToIframe = () => {
          const iframeDocument = document.querySelector('#iframe').contentDocument

          if (iframeDocument !== iframeOldDocument) {
            iframeDocument.querySelector('body').appendChild(createRedDiv())

            return
          }

          setTimeout(appendDivToIframe, 0)
        }
        appendDivToIframe()
      })
    </script>
  </head>
  <body>
    <iframe id="iframe" />
  </body>
</html>
```

やっていることは単純です。早い段階で、最初の初期化後のiframeを取得し変数に保存した上で、あとは`setTimeout`でiframeが変わって、最初の初期化後と等しくなくなるのを待ってから、処理を行うようにした、だけです。

なおこの回避策は、二回初期化するバグのない環境では無限にリトライされます。実際に使用する場合はなんらかの方法(一番単純なのはブラウザがFirefoxかを確認することでしょう)でバグのない環境では回避策を行わないようにする必要があります。


{{< license >}}


