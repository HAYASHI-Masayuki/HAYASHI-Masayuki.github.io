---
title: "VS CodeのMarkdown PDF拡張で、2カラムのPDFを出力する"
date: 2023-01-02T17:23:51+09:00
publishDate: 2023-01-02
draft: false
---

VS Codeにはお手軽な操作でMarkdownで書いた文書をPDF等に出力できる、[Markdown PDF](https://marketplace.visualstudio.com/items?itemName=yzane.markdown-pdf)という拡張機能があります。

便利な拡張機能なのですが、flex等で2カラムで出力しようとしても、HTMLまではうまく2カラムになるのですが、その後のChromium/Chromeの印刷機能を使ったPDF化の時点で、レイアウトが保持されず、1カラムになってしまいました。

参考にした[この記事](https://qiita.com/ossyaritoori/items/9f38113847ee65e68e76)にあるように、HTMLで出力した上で、手動で印刷機能でPDF化(なぜか手動の場合はカラムが保持される)するしかないか、と思ったのですが、いろいろ探したところ、[`column-count`というCSSプロパティを使用すると、Markdown PDFで直接2カラムにできるという情報を見つけました。](https://github.com/yzane/vscode-markdown-pdf/issues/159#issuecomment-1086914415)

```css
body {
  column-count: 2;
}
```

実際にこの方法で、今のところ問題なく2カラム化できそうです。

[`column-count`](https://developer.mozilla.org/ja/docs/Web/CSS/column-count)というプロパティは初めて知りました。フレックスボックスと機能が被りそうですが、簡単なことは`column-count`などの[段組みレイアウト](https://developer.mozilla.org/ja/docs/Learn/CSS/CSS_layout/Multiple-column_Layout)を、複雑なことはフレックスボックスを使う、というような形がよさそうです。 [^1]


{{< license >}}


[^1]: この辺あまり情報がないが、[ここ](https://stackoverflow.com/questions/39082551/responsive-design-columns-vs-flexbox#answer-61870780)など。

