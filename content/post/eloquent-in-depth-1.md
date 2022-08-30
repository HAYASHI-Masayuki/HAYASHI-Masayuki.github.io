---
title: "Eloquentを深く理解する (1) 全体像の把握"
date: 2022-08-25T19:24:51+09:00
draft: true
---

## はじめに

* これから、Eloquentを深く理解するための記事を書いていくよ。
* 対象読者は、普段Laravel, Eloquentを普通に使っているが、いざドキュメントにないこと、その他ややこしいことを調べようとすると、なかなかスムーズに行かない、くらいのレベルの人。
* 1回目は全体像から。Eloquentは巨大なモジュールだから、まず大まかに全体像を把握してからじゃないと大変かと。
* その後、クエリビルダ、アトリビュート、リレーション、などなど、重要な機能を一つずつ見ていくよ。


### 深く学ぶ動機

* Eloquentは巨大だが、それほど難しいわけではない。むしろ気軽に使えるからこそ強力な機能になっている。
* それをなぜ深く学ぶのか。気軽には使えるが、しっかり使いこなすには複雑だから。
* ドキュメント通りに使う分には簡単でも、そこから一歩突っ込んでみると、すぐにはわからないことが出てきたり。
* そういうときのために、深く学んで、しっかり使いこなせるようにする。


### Eloquentとはなにか

* さてそもそもEloquentってなんだろう。Laravelの機能の一つ、データベース操作のためのものだ。
* Eloquentとは別に、DBファサードから使うクエリビルダもある。なにが違うか？
* クエリビルダはSQLクエリの組み立て(と実行)だけを行う、責務がはっきりしたモジュール。対してEloquentは、ORMで、「モデル」を通してデータベース処理を行う。
* 別の視点では、LaravelはRuby on Railsから強く影響を受けており、Eloquentは、RailsのORMであるActive Recordの影響を受けたものだ。[^laravel-inspired-by]
* Active Recordは、PoEAAにある同名パターンを元にしている。[^active-record-implements-the-patteren]


## Eloquentの全体像

* 全体像の把握から始めるのは、ある程度の道筋がないと、巨大なEloquentを理解するのは難しいから。
* 単純に構成要素を把握することだけでも意味があるが、それを頭の中に系統立てて保持しておけば、さらに効果があるはず。
* なおここでEloquentと呼ぶものは基本的には、Eloquent\Modelを継承したクラスを中心として、主にIlluminate\Database\Eloquent以下の名前空間にあるクラス・トレイトによって実装されているもの。
* またEloquent\Modelを継承したクラスのことを、(Eloquentの)モデルを呼ぶ。


### Eloquentは特定のテーブルや行の表現

以下は、Eloquentの基本的な使い方の例です。

```php
<?php

// 1
$user = User::find(1);

// 2
$users = User::where('email', 'like', '%@example.com')->get();

// 3
echo $user->name;

// 4
foreach ($user->posts as $post) {
    echo $post->title;
}
```

1では、主キーを指定してユーザを取得しています。2では、特定のパターンにマッチするメールアドレスのユーザをすべて取得しています。

3では、ユーザの名前を出力しています。4では、ユーザと関連する投稿を`foreach`でループしています。

1と2の`User`, 3と4の`$user`がそれぞれ、Eloquentのモデルです。前者はクラスとして使用しており、後者はインスタンスとして使用しています。

これら2つ、クラス`User`とインスタンス`$user`では、表現しているものが違います。クラス`User`は`users`テーブルを表現しています。1も2も、`users`テーブルから条件を指定して、行を取得しているわけです。そして、`$user`が表現しているのは、`users`テーブルから取得した、主キーが`1`である行です。

**Eloquentのモデルは、クラスとして扱う場合は特定のテーブルを、インスタンスとして扱う場合は、その中の特定の行を表現しているというわけです。**

これは重要です。同じデータベースを扱う機能でも、主にDBファサードから使うクエリビルダ、Illuminate\Database\Query\Builder(以下Query\Builder)は単純に一つのSQLクエリを表現しています。

たとえば以下のコードは、`select * from users where id = 1`というSQLクエリをほぼ直接表現していると考えてよいでしょう。

```php
<?php

DB::table('users')->find(1);
```

一方で`User::find(1)`は、基本的には同じクエリが発行されますが、以下の点がQuery\Builderのコードと違います。

1. `User`モデルは自身と対応するテーブルの名前を知っています。
2. `User`モデルはまた、そのテーブルの主キーの名前を知っています。

これにより、Eloquentのモデルは、テーブル名を指定しなくても対応するテーブルに対するクエリを実行できますし、主キーが`'id'`以外の場合も`find`を使えます。[^query-builder-find-uses-only-id]

とはいえこれがEloquentの利点というわけではありません。単純にQuery\BuilderとEloquentのモデルでは、表現するものが違うというだけの話です。

この違いを知ることが、Eloquentの深い理解の第一歩です。


### 具体的な構成要素

* 特定のテーブルとしてのモデルからは、クエリビルダを使ったSQL処理ができる。モデルから組み立てていくSQLクエリは、デフォルトでテーブルが設定されている。User::whereとDB::table('users')->whereで例。
* またSQL処理に関連して、データベース接続情報や、テーブル名、主キー名などが保持されている。
* 特定の行としてのモデルは、それぞれ対応する行と同じカラム(＝アトリビュート)を持つ。が、オブジェクトの世界とデータベースの世界はリアルタイムで同期しておらず、その差を埋めるためにオブジェクト上にライフサイクルがある。
* アトリビュートの付加的な機能として、アクセサ・ミューテタ、キャストがある。基本的にはアクセサ・ミューテタを合わせたものとキャストは、使い方以外同じものである。これらは、オブジェクトの世界とデータベースの世界での型の違いを吸収したり、その仕組みで行える別の用途を持つ。
* 複数の行はEloquent\Collectionというコレクションクラスで保持される。これはLaravelのデフォルトのコレクションクラスに、Eloquent向けの機能追加をしたもの。
* グローバルスコープという、モデルのすべてのクエリに自動で追加の制約をかける機能がある。
* リレーションという、行から、関連した別のモデルの行にアクセスする手段がある。
* その他細かい要素として、
  * ブート処理。
  * シリアライズ。
  * 入出力セキュリティ。
  * ページネーション。
  * などなど、がある。


### 物理的な構成

* すでに話したように、モデルはEloquent\Modelを継承する。このEloquent\Modelが最も基本的な要素。
* Eloquent\Modelは、マジックメソッドを使った委譲によって、Eloquent\Builder, そこからさらに委譲されるQuery\Builderによって、SQL処理を行う。
* Eloquent\BuilderはQuery\Builderにモデルのテーブルを設定して、使う。
* その他の機能の多くはEloquent\Model本体と、そこから使用されるトレイトに実装されている。
* HasAttributesがアトリビュート、アクセサ・ミューテタ、キャストを、
* HasRelationshipsと、そこで実装されているメソッドから生成される、Eloquent\Relations\Relationを継承した各クラスがリレーションを、
* その他あれこれ。
* なお、物理的な構成はバージョンによって大きく変わるので注意。


## 目次

1. [クエリビルダ](../eloquent-in-depth-2/)
2. [アトリビュート](../eloquent-in-depth-3/)
3. [リレーション](../eloquent-in-depth-4/)
4. [その他の機能](../eloquent-in-depth-5/)


{{< license >}}


[^laravel-inspired-by]: 以下の記述や、Active Record, Eloquentそれぞれの機能より。
  "I just wrote the framework I wanted in order to quickly build some business ideas I had. Many of the ideas were a combination of things I picked up from .NET (auto-wiring, reflection based IoC), Sinatra (routing), and Rails (ORM)."
  [Community Hoops. In this post, I want to reflect a bit… | by Taylor Otwell | Medium](https://medium.com/@taylorotwell/community-hoops-37bd3633114)

[^active-record-implements-the-patteren]: 以下や、前後の記述より。
  "It is an implementation of the Active Record pattern ..."
  [Active Record Basics — Ruby on Rails Guides](https://guides.rubyonrails.org/v7.0/active_record_basics.html)

[^query-builder-find-uses-only-id]: Query\Builderの`find`は、主キーを決め打ちしているため、主キーの名前が`'id'`以外のテーブルでは使えません。
  [framework/Builder.php at 9.x · laravel/framework](https://github.com/laravel/framework/blob/a3c3ed5e8af02e81756b7e51a1a60ad23a600a23/src/Illuminate/Database/Query/Builder.php#L2554)


