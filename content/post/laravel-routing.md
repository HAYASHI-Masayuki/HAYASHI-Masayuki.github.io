---
title: "Laravelのルーティングをしっかり理解する"
date: 2022-06-14T17:01:35+09:00
draft: true
---

Laravelのルーティングは基本的な機能で、Eloquentなどと比べるととても小さく、あまり意識せずに使っている人も多いのではないか。しかし実は中心的なRouteファサードが備えるメソッドは40以上と、数あるファサードの中でもトップクラスに多い上、そのほとんどがチェーンして使う形になっているため、意外と複雑だ。

そこでこの記事では、そもそもルーティングとはなにかを考えるところから始めて、Laravelのルート設定のパターンをしっかり把握した上で、具体的な設定機能を理解していく、という流れで説明する。


## 基本的な使い方

まずは基本的な使い方を簡単に紹介します。ルートは、デフォルトでは`routes/web.php`に設定します。設定には`Route`ファサードを使います。

一番単純な設定方法では、HTTPメソッドと同じ名前のメソッドを使い、URL(パス)のパターンと、そのパスにアクセスされた場合に行う処理をそれぞれ引数として設定します。

また、以下のように、メソッドチェーンでつなげて`name()`メソッドを呼び出すこともよく行われます。これにより、ルートに名前がつけられ、後でその名前からURLを生成することができます。

```php
<?php

use App\Http\Controllers\UserController;

// GETで/user/createにアクセスされた場合に、App\Http\Controllers\UserControllerのcreateメソッドを実行する
Route::get('user/create', [UserController::class, 'create'])->name('users.create');

// POSTで/userにアクセスされた場合に……
Route::post('user', [UserController::class, 'store'])->name('users.store');

// GETで/user/1などにアクセスされた場合に……
Route::get('user/{user}', [UserController::class, 'show'])->name('users.show');
```

単純なCRUDを実装する場合には、`resource()`でリソースルートを設定することもできます。CRUDに対応した複数のルート[^crud]を簡単に、一括で登録できます。

`only()`や`except()`で必要なルートのみ設定したり、不要なルートを除外することもできます。

```php
<?php

use App\Http\Controllers\UserController;

Route::resource('user', UserController::class)->only(['create', 'store', 'show']);
```

複数のルートをグループとしてまとめて設定することもできます。グループ内で設定する各ルートにパスや名前の共通のプレフィックスを指定したり、共通のミドルウェアを指定したりできます。

```php
<?php

use App\Http\Controllers\UserController;

Route::prefix('user')->name('users.')->group(function () {
  Route::get('create', [UserController::class, 'create'])->name('create');
  Route::post('', [UserController::class, 'store'])->name('store');
  Route::get('{user}', [UserController::class, 'show'])->name('show');
});
```

上記の3つのサンプルコードは、すべてまったく同じルートを設定します。


## ルーティングとはなにか

* よりよく使えるように、まずルーティングとはなにか、基本的なところからしっかり理解したい。
* URL(パス)と、アプリケーション内部の機能をつなぐ。
* ほかのフレームワークであるようなパターンの説明も？
* パラメータで、同じ機能への複数のパスを一度で定義できるようにする。
* 名前をつけることで、アプリケーション内部からただのパスのパターンとしてではなく、「ルート」として扱えるように。それにより、URL生成を簡単にできる。


## ルートはアプリケーションにどう登録されるか、そしてどうマッチングされるか

設定したルートはどうアプリケーションに登録されて、どうマッチングされるか、その流れを見ていきます。


### どう登録されるか

* routes/web.phpに設定することはわかっている。では、routes/web.phpというファイル名は固定なのか？
* 実はフレームワーク内にはない。
* App\Services\RouteServiceProviderで設定されている。
* (フレームワーク側の)RouteServiceProvider::routes()


### どうマッチングされるか

* ルーティングはHTTP側の機能。
* HTTPカーネルの流れをざっと紹介。
* そして、ルーティングはHTTPカーネルでの中心的な機能であることも。

<!-- コラム: routes/console.phpはルートではない -->


## ルートに関連するクラスを把握する

* ここまでで、ルーティングの大まかなところは把握できたかと。
* 最後に全体をしっかり理解していくが、その前に……。
* Routeファサードから、routerサービス、そしてRouterクラスが実体。またRoutingServiceProviderで設定。
* ファサードのPHPDocなり、Routerクラスの公開メソッドなりを数えるとわかるが、Routeファサードは40以上の機能を持つ。これらをただぜんぶ覚えるのは大変だ。簡単に把握する方法はないだろうか。
* ルートの設定方法は大きく分けて3つあった。
* 3つそれぞれで戻り値が違い、戻り値を元に機能を大きく3つに分けて把握することができる。
* 重複する機能の話。
* どのパターンの設定方法で、どの属性を設定できるか、表。


## ルーティングに関係する機能を把握する

ここまでの流れで、全体像としてはどう把握すればいいか理解できているはず。ここからは、具体的な機能を確認していく。


### ルートの設定

#### ルートが持つ属性

### リソースルート

### ルートグループ

### リダイレクトルート、ビュールート

### フォールバックルート

### 現在のルートの確認

### ルーティングのパフォーマンス

### ルーティングのデバッグ

* ルートの設定で複雑なバグが出ることはまれだが、マッチングの項で書いたように、初心者は同じパスのパターンの複数ルートがあるときに混乱するかもしれない。
* また、自分で設定したルートはともかく、外部パッケージのどこか奥の方で設定されたルートを把握するのは、簡単ではない。


{{< license >}}


[^crud]: 具体的にどのようなルートが設定されるかはこちら [コントローラ 9.x Laravel#リソースコントローラにより処理されるアクション](https://readouble.com/laravel/9.x/ja/controllers.html#actions-handled-by-resource-controller)

