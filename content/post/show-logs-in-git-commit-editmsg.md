---
title: "Gitのコミットメッセージ編集ファイルに最近のコミットメッセージを表示する"
date: 2024-07-07T16:32:45+09:00
draft: true
---

`git commit`時に、エディタで開かれたコミットメッセージ編集ファイル[^commit-editmsg]には`git status`で取得できるのと同等の情報が表示されます。`-v`オプションをつけてコミットした場合には、`git diff`相当の差分情報も表示されます。

これは非常に便利なのですが、私はここに最近のコミットメッセージも表示したいと思いました。今回のコミットメッセージを考えるのに、参考にすることがあるためです。よく`Ctrl+Z`でVimをバックグラウンドに移動して、`git log -3`とかすることがありました。[^git-log]

ChatGPTに聞いてみるとやり方はすぐわかりました。`prepare-commit-msg`というフックファイルには、編集ファイルのパスが渡されるので、それを編集すればよさそうです。

つまり残念ながら、編集ファイルのテンプレートのようなものはないようです。コミットメッセージ部分(つまりファイルの最上部)であれば、コミットメッセージのテンプレートは設定できますが、今回の目的とは微妙にマッチしません。

ファイルをプログラマブルに編集するとなると、`sed`や`awk`の出番です。いろいろがんばった結果、以下のようなフックスクリプトでやりたいことが実現できました。

```sh
#!/bin/sh
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# -m, -Fの場合はなにもしない
if [ "$COMMIT_SOURCE" = "message" ]; then
    exit 0
fi

LOGS=$(cat <<LOGS
# Latest commits:
$(git log -10 --pretty=format:"%ai:%d %s" | sed 's/^/#\t/')
#\n
LOGS
)

awk -v var="$LOGS" '{ sub(/(# -{24} >8 -{24})/, var $0); print }' "$COMMIT_MSG_FILE" > "$COMMIT_MSG_FILE".tmp
mv "$COMMIT_MSG_FILE".tmp "$COMMIT_MSG_FILE"
```

`COMMIT_EDITMSG`ファイルの中身もいい感じです。`git status`相当の情報の下に、自然に最近のコミットメッセージが表示されています。

```

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Your branch is up to date with 'origin/main'.
#
# Changes to be committed:
#	modified:   src/App.svelte
#	modified:   svelte.config.js
#
# Untracked files:
#	.editorconfig
#
# Latest commits:
#	2024-06-27 19:58:50 +0900: (HEAD -> main, origin/main) 開発サーバ起動時にもCSSクラスが消えていた
#	2024-06-25 20:59:41 +0900: ビルドすると、SvelteのSFC内で定義されたCSSクラスが消えていた件に対応
#	2024-06-25 20:59:25 +0900: Tailwind CSS側も適切にパージされているかのマーカを追加
#	2024-06-25 20:35:44 +0900: SCSSで直接書いたCSSにもPurgeCSSをかけるように
#	2024-06-25 20:16:22 +0900: pnpm add -D @fullhuman/postcss-purgecss postcss
#	2024-06-25 20:03:33 +0900: SCSSに対応
#	2024-06-25 20:03:26 +0900: pnpm add -D sass
#	2024-06-25 20:00:54 +0900: リセットCSSは外した
#	2024-06-11 21:10:37 +0900: テストを書いてみた
#	2024-06-11 21:09:52 +0900: Vitestでテストできるように
#
# ------------------------ >8 ------------------------
# Do not modify or remove the line above.
# Everything below it will be ignored.
diff --git a/src/App.svelte b/src/App.svelte
...
```

しかしこのスクリプトに1つ、できていないことがありました。`-v`をつけない場合には最近のコミットメッセージを表示できないのです。

`awk`は`\z`ないっぽいんですよね……。いずれにしても私の`awk`力だとあまり複雑なコー	
ドは難しい。

あきらめて、`perl`を使うことにしました。

```sh
#!/bin/sh
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# -m, -Fの場合はなにもしない
if [ "$COMMIT_SOURCE" = "message" ]; then
    exit 0
fi

cat <<'PERL' | perl -i - "$COMMIT_MSG_FILE"
$/ = undef;
$_ = <>;
($logs = `git log -10 --pretty=format:"%ai:%d %s"`) =~ s/^/#\t/gm;
s/(?=# -{24} >8 -{24})|\z/# Latest commits:\n$logs\n#\n/;
print;
PERL
```

`-v`をつけない場合も、しっかり表示されています。

```

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Your branch is up to date with 'origin/main'.
#
# Changes to be committed:
#	modified:   src/App.svelte
#	modified:   svelte.config.js
#
# Untracked files:
#	.editorconfig
#
# Latest commits:
#	2024-06-27 19:58:50 +0900: (HEAD -> main, origin/main) 開発サーバ起動時にもCSSクラスが消えていた
#	2024-06-25 20:59:41 +0900: ビルドすると、SvelteのSFC内で定義されたCSSクラスが消えていた件に対応
#	2024-06-25 20:59:25 +0900: Tailwind CSS側も適切にパージされているかのマーカを追加
#	2024-06-25 20:35:44 +0900: SCSSで直接書いたCSSにもPurgeCSSをかけるように
#	2024-06-25 20:16:22 +0900: pnpm add -D @fullhuman/postcss-purgecss postcss
#	2024-06-25 20:03:33 +0900: SCSSに対応
#	2024-06-25 20:03:26 +0900: pnpm add -D sass
#	2024-06-25 20:00:54 +0900: リセットCSSは外した
#	2024-06-11 21:10:37 +0900: テストを書いてみた
#	2024-06-11 21:09:52 +0900: Vitestでテストできるように
#
```

`perl`は便利です。


{{< license >}}


[^commit-editmsg]: このファイルはなんて呼べばいいんでしょう？　いろいろ調べたのですが見つかりませんでした。個人的には「コミットメッセージ編集ファイル」と呼ぼうかと思いますが、長い。

[^git-log]: 今思ったんですが、Vimから`:!git log -3`してもよかったですね。
