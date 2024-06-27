---
title: "Svelte + Vite環境でPurgeCSSを使う方法"
date: 2024-06-27T20:15:00+09:00
draft: false
---

## 結論

1. ViteはPostCSSと連携してくれるので、基本的には`postcss.config.js`で`postcss-purgecss`プラグインを指定するだけ。
2. 追加で`safelist`として、`[/^svelte-/, /^s-[0-9A-Za-z_-]{12}$/]`を渡す。


## 経緯

Svelte + Vite + Tailwind CSSの場合、`pnpm exec tailwindcss init -p`[^tailwindcss-init]とかするだけで、Tailwind CSSが定義するCSSに関しては自動でいい感じにパージしてくれます。

`tailwindcss init -p`するとTailwind CSSが生成するCSSをパージする設定の`postcss.config.js`が生成され、またViteはPostCSSを自動で処理してくれる[^vite-postcss]からです。

しかし、`.svelte`内や、`.scss`内で`@for`とかして生成した大量のCSSはこれだけではパージされません。

Tailwind CSSがやっているように、PostCSSでPurgeCSSを使えばなんとかできそうなのでやってみました。

```javascript
// postcss.config.js
export default {
  plugins: {
    '@fullhuman/postcss-purgecss': {
      content: [
        './src/**/*.svelte',
      ],
    },
  },
}
```

(設定ファイルは一般的な配列形式でなく、オブジェクト形式です。`tailwindcss init -p`が生成するのがそちらだったので。どちらでも大丈夫です。)

これでパージ自体は動きました。`@for`で大量のCSSを生成しても、使用しているもの以外はビルド時にパージされ、ファイルサイズが抑えられます。

しかし代わりに、Svelteのコンポーネント内で定義したCSSが削除されるという事象が発生しました。

調べてみたところ、CSSの適用をコンポーネント内に抑えるための、`.svelte-xxxxxxxx`のようなセレクタのCSS定義が削除されているようです。

これは、PurgeCSSの設定でこのようなセレクタを`safelist`に入れてしまえばOKです。

```javascript
// postcss.config.js
export default {
  plugins: {
    '@fullhuman/postcss-purgecss': {
      content: [
        './src/**/*.svelte',
      ],
      safelist: [
        /^svelte-/,
      ],
    },
  },
}
```

ちなみにこの`svelte-xxxxxxxx`のような形式は、Svelteの`cssHash`[^svelte-csshash]という名前のコンパイルオプションで変更可能なため、`cssHash`を設定している場合は適宜調整する必要があります。

また、この修正を行った後も、Viteの開発サーバでの動作時にはまだCSS定義が削除されていました。

開発サーバでの動作時は、なぜか`svelte-xxxxxxxx`のような形式ではなく、`s-xxxxxx`のような形式になっていました。

`svelte-xxxxxxxx`に比べ短い上に誤爆しやすい接頭辞のため、`cssHash`で変更できないか試してみましたが、なぜかできません。

`s-`という文字列で元凶を探してみたところ、`vite-plugin-svelte`内にありました。`vite-plugin-svelte`では、開発サーバで動作させる際のコンパイルオプションの調整が行われているようなのですが、そこでなぜか設定として渡した`cssHash`を無視して、自前の、`s-xxxxxx`形式のセレクタを生成する処理が設定されていました。

最終的に`/^s-[0-9A-Za-z_-]{12}$/`のような正規表現で、できる限り誤爆を抑えつつパージされないようにしました。

```javascript
// postcss.config.js
export default {
  plugins: {
    '@fullhuman/postcss-purgecss': {
      content: [
        './src/**/*.svelte',
      ],
      safelist: [
        /^svelte-/,
        /^s-[0-9A-Za-z_-]{12}$/,
      ],
    },
  },
}
```

開発サーバで`cssHash`を設定できないことにはどうも理由があるようなので、これは修正されないでしょう。

[vite-plugin-svelte/docs/faq.md at main · sveltejs/vite-plugin-svelte](https://github.com/sveltejs/vite-plugin-svelte/blob/main/docs/faq.md#why-cant-csshash-be-set-in-development-mode)

[Option to disable scoped CSS class hash in dev mode · Issue #872 · sveltejs/vite-plugin-svelte](https://github.com/sveltejs/vite-plugin-svelte/issues/872#issuecomment-1995587037)

下の方、なんか不穏なことも書いてますね。

> Note that svelte5 is going to have integrated support for hmr and changes how css scoping works.

あるいは、開発サーバでの動作時はPurgeCSSを無効にするという方法も考えられます。個人的には開発サーバと本番ビルドでの差異はできるだけ小さくしたいため、今回は選択しませんでしたが。


{{< license >}}


[^tailwindcss-init]: https://tailwindcss.com/docs/configuration#generating-a-post-css-configuration-file

[^vite-postcss]: https://ja.vitejs.dev/guide/features#postcss

[^svelte-csshash]: https://svelte.jp/docs/svelte-compiler#types

