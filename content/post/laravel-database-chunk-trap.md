---
title: "Laravelのデータベースのchunk()の罠"
date: 2021-09-21T10:15:14+09:00
draft: false
---

## クエリビルダのchunk()は便利だが罠があるのでchunkById()を使おう

### chunk()とはなにか

### どういう罠があるのか

## なぜchunkById()なら大丈夫なのか

### 罠1: 取得しつつ更新する場合

### 罠2: ロックせず処理する場合

### それでもchunk()の方が適切な場合

## 関連メソッドについて

### each(), eachById()

### chunkMap()

### lazy(), lazyById(), lazyByIdDesc()



## chunk()のメリットと罠

Laravelでデータベースにある大量の行を処理したい場合、すべての行を一度に取得する	
とメモリ不足になって処理できなかったり、遅くなってしまうため、`chunk()`や`	
cursor()`[^cursor]で分割して処理をすることになります。




## 問題の原因


## 問題を回避するには


[^cursor]: `cursor()`は単純にジェネレータで`PDOStatement::fetch()`しているだけの	
ようで、実際には分割されておらずメモリ消費があまり減らなかったり、それを防ぐため	
に設定を変えた場合は処理が終了するまで同じコネクションで別のクエリを実行できなかっ	
たり、癖が強いようなので私は使用していません。
参考: [Laravelのcursorとchunkの違いとバッファクエリの対処法 - honeplusのメモ帳]	
(http://honeplus.blog50.fc2.com/blog-entry-219.html)

