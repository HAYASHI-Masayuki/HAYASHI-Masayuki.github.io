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


### 特定のテーブル、あるいはその中の特定の行の表現

* の前に、Eloquentの基本的な使い方をおさらいします。
* Eloquentはクラスとして扱う場合は特定のテーブルを、インスタンスとして扱う場合はその中の特定の行を表現している。
* DBファサードから使うクエリビルダ、Illuminate\Database\Query\Builder(以下Query\Builder)が単純に一つのSQLクエリを表現しているのに対して、Eloquentのモデルは、上記の通り、特定のテーブルや特定の行を表現する。
* 事例として、User::whereと$user->whereについて。後者はインスタンスの内容とは無関係であることを。


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


