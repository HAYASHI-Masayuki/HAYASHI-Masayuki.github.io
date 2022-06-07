---
title: "Laravelのデータベースのchunk()の罠"
date: 2021-09-21T10:15:14+09:00
draft: false
---

## クエリビルダのchunk()は便利だが罠があるのでchunkById()を使おう

基本的にMySQLでの話です。とはいえ、ほかのRDBMSでも大きくは変わらないかと。


### chunk()とはなにか

Laravelでデータベースにある大量の行を処理する場合、すべての行を一度に取得しようとすると大量のメモリが必要になります。場合によってはメモリ不足で処理自体できないかもしれません。

そのようなことを防ぐために、Laravelにクエリビルダには一定の行数ごとに取得する`chunk()`というメソッドがあります。たとえば10万行あるデータを取得する際に、1000行ごとに100回取得・処理するという感じです。

`chunk()`は便利なメソッドですが、いくつかの場合に罠があるため、代わりに`chunkById()`を使おう、というのがこの記事の主旨です。

なお、データベースのカーソル機能を使う`cursor()`[^cursor]というメソッドもありますが、この記事では取り扱いません。


### どういう罠があるのか

具体的にどういう罠があるかですが、まず公式ドキュメントにも書かれているように、取得しつつ更新する場合に、想定した行を処理できない罠があります。

[データベース：クエリビルダ 9.x Laravel](https://readouble.com/laravel/9.x/ja/queries.html#chunking-results)

もう一つ、処理対象をロックせずに処理している場合に、別のトランザクションからの更新等によって、一つ目の罠同様に想定した行を処理できなかったり、さらには同じ行を複数回処理してしまうという場合があります。

ロックすれば防げるのですが、`chunk()`を使いたいほどの大量の行の処理では、ロックしてしまうとかなり長い時間テーブルにまったく触れなくなってしまうため、意図的にロックせずに処理したいという場合もあると思います。

この2つの罠は、`chunk()`ではなく`chunkById()`を使えばほぼ回避できます。


## なぜchunkById()なら大丈夫なのか

`chunk()`では駄目で`chunkById()`であれば大丈夫なのはなぜでしょうか。まず、そもそもどうして上記のような罠が起きるかを見ていきます。

`chunk()`は一定行数ごとに取得してくれるのですが、その取得方法が、クエリビルダで渡したソート方法でソートした状態で、単純に`OFFSET`, `LIMIT`で分けて取得する、となっています。

```php
User::chunk(1000, function () {  })
```

Eloquentでこのように実行すると、SQLは以下のようになります。

```sql
select * from `users` order by `users`.`id` asc limit 1000 offset 0
```

この場合、処理の途中で取得対象となる行が変わってしまうと、ずれが生じます。

`chunkById()`の場合、`OFFSET`を使わずid, あるいは指定したカラムを基準に次のチャンクを取得するため、ロックする場合は取得しつつ処理してもずれなくなり、ロックしない場合も、複数回処理してしまうような大きな問題は防げます。


### 罠1: 取得しつつ更新する場合

<table>
  <tr>
    <th style="width: 25%">id</th>
    <th style="width: 15%">1</th>
    <th style="width: 15%">2</th>
    <th style="width: 15%">3</th>
    <th style="width: 15%">4</th>
    <th style="width: 15%">5</th>
  </tr>
  <tr>
    <td style="text-align: center">取得対象か</td>
    <td style="text-align: center">○</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">○</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">○</td>
  </tr>
</table>
<!--
| id         | 1   | 2   | 3   | 4   | 5   |
| :-:        | :-: | :-: | :-: | :-: | :-: |
| 取得対象か | ○  | ×  | ○  | ×  | ○  |
-->

上記のようなデータがある場合に、取得対象のものを2つずつ処理するとします。順当に行けば最初に1, 3を、次に5が処理されて完了となります。

<table>
  <tr>
    <th style="width: 25%">id</th>
    <th style="width: 15%">1</th>
    <th style="width: 15%">2</th>
    <th style="width: 15%">3</th>
    <th style="width: 15%">4</th>
    <th style="width: 15%">5</th>
  </tr>
  <tr>
    <td style="text-align: center">何回目に取得されるか</td>
    <td style="text-align: center">1</td>
    <td style="text-align: center">-</td>
    <td style="text-align: center">1</td>
    <td style="text-align: center">-</td>
    <td style="text-align: center">2</td>
  </tr>
</table>
<!--
| id                   | 1   | 2   | 3   | 4   | 5   |
| :-:                  | :-: | :-: | :-: | :-: | :-: |
| 何回目に取得されるか | 1   | -   | 1   | -   | 2   |
-->

しかし、1, 3を取得した後に、これらが取得対象とならなくなるような変更を行った場合はどうなるでしょうか。

<table>
  <tr>
    <th style="width: 25%">id</th>
    <th style="width: 15%">1</th>
    <th style="width: 15%">2</th>
    <th style="width: 15%">3</th>
    <th style="width: 15%">4</th>
    <th style="width: 15%">5</th>
  </tr>
  <tr>
    <td style="text-align: center">取得対象か</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">○</td>
  </tr>
</table>
<!--
| id         | 1   | 2   | 3   | 4   | 5   |
| :-:        | :-: | :-: | :-: | :-: | :-: |
| 取得対象か | ×  | ×  | ×  |× | ○  |
-->

2回目の処理では、`OFFSET 2`, `LIMIT 2`として処理されるため、`id = 5`は取得されないまま処理全体が終了してしまいます。

`chunkById()`を使った場合、`OFFSET`で2回目の処理対象の先頭を判断する代わりに、

1. `id`で昇順ソートしつつつ、
2. 1回目の処理の最後の`id`(つまり3)を覚えておいて、それより大きい`id`(4以上)の行だけ選択することにより、

1, 3が取得対象とならなくなっても、`id > 3`の行のうち、取得対象のものを2つ(今回は5のみのため、実際には1つしか取得しないが)取得されるため、`chunk()`の場合に起きていた問題は起きません。

```php
User::chunkById(1000, function () {  })
```

上記のように`chunkById()`を使った場合のクエリは、以下のようになります。

```sql
-- 1回目は、
select * from `users` order by `id` asc limit 1000;

-- 2回目は、
select * from `users` where `id` > 1000 order by `id` asc limit 1000;
```


### 罠2: ロックせず処理する場合

`lockForUpdate()`等で排他ロックした上で`chunk()`を実行する場合、罠1のように自身のトランザクションで取得対象が変わるような変更を行なわない限り、最初の`SELECT`時点で取得対象となるすべての行を適切に取得・処理できます。

ただし、その処理が完了するまでの間は当然`INSERT`, `UPDATE`, `DELETE`はまったくできなくなります。`chunk()`を使いたいほど多くのデータを処理する場合、その時間は許容できないほど長くなる可能性もあります。

排他ロックされる時間が許容できない場合、ロックせずに処理するしかないですが、これが2つ目の罠となります。

ロックせずにチャンクの処理をすると、各チャンクの処理の間に、取得対象の行が増減する可能性があります。それにより、全処理の間に同じ行が2回取得されたり、逆にずっと取得対象だったのに一度も取得されない、ということがありえます。

<table>
  <tr>
    <th style="width: 25%">id</th>
    <th style="width: 15%">1</th>
    <th style="width: 15%">2</th>
    <th style="width: 15%">3</th>
    <th style="width: 15%">4</th>
    <th style="width: 15%">5</th>
  </tr>
  <tr>
    <td style="text-align: center">取得対象か</td>
    <td style="text-align: center">○</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">○</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">○</td>
  </tr>
  <tr>
    <td style="text-align: center">何回目に取得されるか</td>
    <td style="text-align: center">1</td>
    <td style="text-align: center">-</td>
    <td style="text-align: center">1</td>
    <td style="text-align: center">-</td>
    <td style="text-align: center">2(予定)</td>
  </tr>
</table>
<!--
| id                   | 1   | 2   | 3   | 4   | 5       |
| :-:                  | :-: | :-: | :-: | :-: | :-:     |
| 取得対象か           | ○  | ×  | ○  | ×  | ○      |
| 何回目に取得されるか | 1   | -   | 1   | -   | 2(予定) |
-->

1, 3が取得された後、2が別のトランザクションから取得対象になるような変更をされた場合、

<table>
  <tr>
    <th style="width: 25%">id</th>
    <th style="width: 15%">1</th>
    <th style="width: 15%">2</th>
    <th style="width: 15%">3</th>
    <th style="width: 15%">4</th>
    <th style="width: 15%">5</th>
  </tr>
  <tr>
    <td style="text-align: center">取得対象か</td>
    <td style="text-align: center">○</td>
    <td style="text-align: center">○</td>
    <td style="text-align: center">○</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">○</td>
  </tr>
  <tr>
    <td style="text-align: center">何回目に取得されるか</td>
    <td style="text-align: center">1</td>
    <td style="text-align: center">1(実際は取得されていない)</td>
    <td style="text-align: center">2</td>
    <td style="text-align: center">-</td>
    <td style="text-align: center">2</td>
  </tr>
</table>
<!--
| id                   | 1   | 2                         | 3   | 4   | 5   |
| :-:                  | :-: | :-:                       | :-: | :-: | :-: |
| 取得対象か           | ○  | ○                        | ○  | ×  | ○  |
| 何回目に取得されるか | 1   | 1(実際は取得されていない) | 2   | -   | 2   |
-->

3が、1回目と2回目のどちらでも取得されることになります。

あるいは1, 3が取得された後、1が別のトランザクションから取得対象にならないような変更をされた場合、

<table>
  <tr>
    <th style="width: 25%">id</th>
    <th style="width: 15%">1</th>
    <th style="width: 15%">2</th>
    <th style="width: 15%">3</th>
    <th style="width: 15%">4</th>
    <th style="width: 15%">5</th>
  </tr>
  <tr>
    <td style="text-align: center">取得対象か</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">○</td>
    <td style="text-align: center">×</td>
    <td style="text-align: center">○</td>
  </tr>
  <tr>
    <td style="text-align: center">何回目に取得されるか</td>
    <td style="text-align: center">-</td>
    <td style="text-align: center">-</td>
    <td style="text-align: center">1</td>
    <td style="text-align: center">-</td>
    <td style="text-align: center">1(実際は取得されていない)</td>
  </tr>
</table>
<!--
| id                   | 1   | 2   | 3   | 4   | 5                         |
| :-:                  | :-: | :-: | :-: | :-: | :-:                       |
| 取得対象か           | ×  | ×  | ○  | ×  | ○                        |
| 何回目に取得されるか | -   | -   | 1   | -   | 1(実際は取得されていない) |
-->

となり、5は1回目の取得済みと判断され、2回目に取得されません。

ロックせず処理する場合、以下の4パターンの問題が起こり得ます。

1. 途中で取得対象になった行が取得されてしまう場合がある。
2. 途中で取得対象でなくなった行が取得されなくなってしまう場合がある。
3. 途中で変更されていない行が、2回取得・処理されてしまう場合がある。
4. 途中で変更されていない行が、取得・処理されない場合がある。

1, 2については`chunkById()`でも対処できませんが、これは許容できる場合も多いかと思います。

問題は3, 4で、特に4が許容できる場合はあまりないかと思います。`chunkById()`を使えば、`OFFSET`を基準にすることが原因で起こるこれら2つの問題は起きなくなります。


### それでもchunk()の方が適切な場合

基本的には常に`chunkById()`を使うべきだと思うのですが、「ユニークなカラムで昇順」以外の順番で処理したい場合、そのときだけは`chunk()`を使うしかありません。

`chunkById()`は、カラム名は指定できますが、ユニークなカラムでなければ正しく処理できない可能性があり、また処理順は昇順で固定です。そのため、この場合は`chunk()`を使い、ロックした上で、更新しないように気をつけるしかありません。


## 関連メソッドについて

`chunk()`や`chunkById()`には関連するメソッドがいくつかあります。簡単にご紹介します。


### each(), eachById()

`each()`, `eachById()`は、それぞれ`chunk()`, `chunkById()`内で単純に`foreach`でチャンクを処理するパターンのシンタックスシュガー的なメソッドです。以下の2つの処理は、ほぼ同等となります。

```php
User::where(...)->chunkById(1000, function ($users) {
    foreach ($users as $user) {
        $user->update(...);
    }
});
```

```php
User::where(...)->eachById(function (User $user) {
    $user->update(...);
});
```

このようなシンプルな処理の場合、`eachById()`を使う方があきらかにわかりやすく書けるため、おすすめです。

ただし`eachById()`が内部的に`chunkById()`を使うことを知らない人には一行ずつ処理しているように見えること、また、`each()`についてはコレクション(`Illuminate\Support\Collection`)の`each()`と混同される可能性がある点には注意が必要かもしれません。

なおコレクションにも`chunk()`がありますが、こちらは引数がまったく違うため、あまり混同することはないと思います。


### chunkMap()

`chunkMap()`は、`chunk()`内で取得したデータを元にコレクションを作るメソッドです。対応する`chunkMapById()`はありません。機能の用途的に取得しつつ更新することはないと思われますが、ロックしない場合は`chunk()`同様にずれる可能性はあるはずです。


### lazy(), lazyById(), lazyByIdDesc()

私はまだ試していないのですが、Laravel 8からは`lazy()`, `lazyById()`, また`lazyByIdDesc()`というメソッドも追加されたようです。

これらはPHPのジェネレータを使うようになった`chunk()`と考えるのがよさそうです。`LazyCollection`を返すので、`chunk()`や`each()`よりも、さらにシンプルにコードが書けるかもしれません。

```php
foreach (User::where(...)->lazyById() as $user) {
    $user->update(...);
}
```

また、`chunk()`系にはなかった、id降順で取得する`lazyByIdDesc()`も場合によっては便利そうです。


## 別解: バルクアップデートする

取得するだけの場合には使えませんが、取得したデータを変更等した上で保存するような使い方の場合、バルクアップデートの方が向いていて、かつ高速かもしれません。

`chunk()`を使うのは、アプリケーション側でデータを処理する必要があるためです。すべてをデータベース側で処理できるのであれば、必要はありません。

[Laravelで気軽にバルクアップデートしたい - Qiita](https://qiita.com/HAYASHI-Masayuki/items/eec7e85eb8835ee8c96f)


[^cursor]: `cursor()`は単純にジェネレータで`PDOStatement::fetch()`しているだけのようで、実際には分割されておらずメモリ消費があまり減らなかったり、それを防ぐために設定を変えた場合は処理が終了するまで同じコネクションで別のクエリを実行できなかったり、癖が強いようなので私は使用していません。
参考: [Laravelのcursorとchunkの違いとバッファクエリの対処法 - honeplusのメモ帳](http://honeplus.blog50.fc2.com/blog-entry-219.html)


