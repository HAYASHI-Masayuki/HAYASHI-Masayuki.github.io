---
title: "長期間(6以前から)運用されているLaravelシステムがあるなら、ジョブのコードを一度確認した方がいいかもしれない"
date: 2024-09-05T20:45:11+09:00
draft: true
---

## Laravelのジョブクラスの`failed`メソッドの実行に失敗する

Laravelのジョブクラスには、`failed`というメソッドを実装することで、失敗時の処理を定義できます。

```php
<?php

namespace App\Jobs;

// ...

class FooJob implements ShouldQueue
{
    // ...

    /**
     * The job failed to process.
     *
     * @param  Exception  $exception
     * @return void
     */
    public function failed(Exception $exception)
    {
        // 失敗時に実行される
    }
}
```

最近、この`failed`メソッドの実行自体がエラーになることがありました。

```
Argument #1 ($exception) must be of type Exception, TypeError given, ...
```

確認すると、原因は単なる引数の型の間違えでした。上記のように`Exception`を受け取っていたのですが、実際に渡されたのは`TypeError`でした。

ご存知のように、PHPの例外は以下のようなツリー構造になっています。

```
- Throwable
  - Error
    - TypeError
    ...
  - Exception
    ...
```

`TypeError`は`Error`のサブクラスであり、`Exception`のサブクラスではないので、`failed`の実行が失敗するのは当然です。


## 原因究明

しかしさて、なぜ`failed`の第1引数を`Exception`として実装してしまったのでしょうか。原因を探ってみました。

1. まず、この`failed`は、`artisan make:job`で用意されるものではなさそうでした。
2. その他、コード内のなにかを元にしたわけではなさそうでした。Laravelのジョブクラスは親クラスを継承して作るような仕様ではないので、親クラスの`failed`を持って来た、という可能性はありません。
3. 元々`failed`は`Exception`を受け取る仕様であり、途中でそれが変わった可能性を考え、コミットログやアップグレードガイドをざっと見ましたが、その限りでは元々`Throwable`を受け取る仕様だったようです。
4. 公式ドキュメントに`failed`の実装例はありました。が、型は正しく`Throwable`でした。

とりあえずここまで来て思い付くことがあり、古いバージョンのドキュメントを確認すると、そこには第1引数が`Exception`になっている実装例がありました。これをコピペしたのが原因と考えてよさそうです。

```php
<?php
 
namespace App\Jobs;
 
use Exception;
use App\Podcast;
use App\AudioProcessor;
use Illuminate\Bus\Queueable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;
 
class ProcessPodcast implements ShouldQueue
{
    use InteractsWithQueue, Queueable, SerializesModels;
 
    protected $podcast;
 
    /**
     * Create a new job instance.
     *
     * @param  Podcast  $podcast
     * @return void
     */
    public function __construct(Podcast $podcast)
    {
        $this->podcast = $podcast;
    }
 
    /**
     * Execute the job.
     *
     * @param  AudioProcessor  $processor
     * @return void
     */
    public function handle(AudioProcessor $processor)
    {
        // Process uploaded podcast...
    }
 
    /**
     * The job failed to process.
     *
     * @param  Exception  $exception
     * @return void
     */
    public function failed(Exception $exception)
    {
        // Send user notification of failure, etc...
    }
}
```

[Queues - Laravel 5.3 - The PHP Framework For Web Artisans](https://laravel.com/docs/5.3/queues#cleaning-up-after-failed-jobs)


## 原因は公式ドキュメントの間違えを、そのままコピペしたため

公式ドキュメントの`failed`の実装例は何度か修正されており、5.3で引数を受け取るようになってから6までの間は、間違った`Exception`を受け取っていました。これは、以下のPRで修正され、7以降のドキュメントでは`Throwable`になっています。

[[7.x] Use Throwable instead of Exception in failed() methods in code examples by LeoNguyenHQ · Pull Request #6253 · laravel/docs](https://github.com/laravel/docs/pull/6253)

さらに10で、引数がnullableに修正されています。

[[10.x] Nullable `failed` method by timacdonald · Pull Request #9445 · laravel/docs](https://github.com/laravel/docs/pull/9445)


## まとめ

ドキュメントの変更履歴がこうして残っているのは、やはり便利です。変更履歴や、そもそも古いバージョンのドキュメントが残っていなければ、原因究明は難しかったでしょう。

一方、コードであれば重要な修正はそれ自体がドキュメントにされやすいですが、ドキュメントの重要な修正がドキュメントにされるようなことはあまりなさそうで、ここは改善の余地がありそうです。

古くからあるジョブクラスの`failed`メソッドの引数の型は、一度確認してみてもいいかもしれません。


{{< license >}}


