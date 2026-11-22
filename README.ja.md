# OWASP NodeGoatのコンテナイメージ：わざと脆弱にしたNode.jsアプリを、ソースからビルド

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

**OWASP NodeGoat** のマルチアーキテクチャのDockerイメージです。NodeGoatは、わざと安全でなく作られたNode.jsとExpressのWebアプリケーションで、Node.jsのコードを使ってOWASP Top 10を学べます。サーバーサイドJavaScriptインジェクション、MongoDBへのNoSQLインジェクション、認証とセッションの不備、クロスサイトスクリプティング、安全でない直接オブジェクト参照、アクセス制御の欠如、CSRF、脆弱なコンポーネント、オープンリダイレクト、ReDoSを扱います。**`ghcr.io/mitsurutech/owasp-nodegoat`** として `linux/amd64` と `linux/arm64` 向けに公開しています。

> **NodeGoatは設計上、脆弱です。** 自分が管理するマシンとネットワークだけで動かし、ポートをインターネットに公開せず、本物のデータは決して入れないでください。

OWASPプロジェクトはNodeGoatをDockerfile付きのソースコードとして公開していますが、イメージは公開していません。そこで、このリポジトリで誰でも見られる形でイメージを作っています。

- **上流のソースを1つのコミットに固定。** Dockerfileは [OWASP/NodeGoat](https://github.com/OWASP/NodeGoat) のコミット `c5cb68a7084e4ae7dcc60e6a98768720a81841e8` のGitHubアーカイブをダウンロードし、展開する前に [`SHA256SUMS`](SHA256SUMS) で確認します。NodeGoatには一切手を加えません。弱点こそが学ぶ対象だからです。
- **依存関係はイメージのビルド時にインストール。** `npm ci --omit=dev` が、プロジェクト自身の `package-lock.json` にあるものだけを、インストールスクリプトを実行せずに入れます。そのため、イメージから起動したコンテナはネットワークをまったく必要としません。
- **起動時に初期データを投入。** エントリーポイントの [`nodegoat-start`](nodegoat-start) がMongoDBを待ち、NodeGoat自身の `artifacts/db-reset.js` で初期アカウントを読み込み（プロジェクトのcomposeファイルと同じやり方です）、ポート4000でサイトを起動します。
- **権限なし。** Alpine上の公式Node.jsイメージにある `node` アカウントで動きます。

NodeGoatには **MongoDB 4.4** が必要です。データベースドライバー（`mongodb` 2.2）が使うワイヤープロトコルを、新しいサーバーはもう受け付けないからです。公式の `mongo:4.4` イメージで動きます。

```sh
docker network create nodegoat
docker run -d --name mongo --network nodegoat mongo:4.4.29
docker run -d --name nodegoat --network nodegoat -p 127.0.0.1:4000:4000 ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a
```

そのあと http://127.0.0.1:4000/ を開き、`user1`、パスワード `User1_123` でサインインします（または `admin` / `Admin_123`）。どちらもNodeGoatに最初から入っている初期アカウントです。`MONGODB_URI`（既定値 `mongodb://mongo:27017/nodegoat`）と `PORT`（既定値 `4000`）で、接続先と待ち受けるポートを変えられます。ラボのcomposeファイルなど、大事なところではイメージをdigestで固定してください：`ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a@sha256:<digest>`。

## 使われている場所

MitsuruTechの教育プラットフォームのコンテナラボ、[NodeGoatラボ](https://github.com/mitsurutech/lab-nodegoat-lab)で使うアプリケーションです。このラボでは、学生一人ひとりがインターネットに出られない自分専用のコピーを攻撃し、そのあとソースの中で各弱点の横にある修正を読みます。ヘルプマニュアルの[このラボのページ](https://mitsurutech.co.uk/ja/help/lab-nodegoat-lab)に何を学べるかが、[コンテナラボのガイド](https://mitsurutech.co.uk/ja/help/labs)に学校での動かし方が書いてあります。先生方は[学習プラットフォーム](https://mitsurutech.co.uk/ja/learning)の説明を読んだり、[料金](https://mitsurutech.co.uk/ja/pricing)を見たり、[登録](https://mitsurutech.co.uk/ja/signup)したりできます。

## 新しいNodeGoatのコミットに更新する

1. `Dockerfile` の `ARG NODEGOAT_COMMIT` を変えます（`package.json` が変わっていれば `ARG NODEGOAT_VERSION` も）。
2. `SHA256SUMS` の行を、`https://github.com/OWASP/NodeGoat/archive/<commit>.tar.gz` のSHA-256に置き換えます。名前は `NodeGoat-<commit>.tar.gz` にします。
3. `main` にpushします。ワークフローが両方のアーキテクチャをビルドして新しいタグを公開します。既存のタグには手を付けません。

## ライセンス

NodeGoatはOWASP NodeGoatプロジェクトによりApache-2.0でライセンスされています。ライセンスはイメージ内の `/home/node/app/LICENSE` に入っていて、[`LICENSE`](LICENSE) にもあります。このリポジトリのDockerfile、エントリーポイント、ワークフローも同じ条件で提供します。このイメージはOWASPが作ったものでも、推奨しているものでもありません。

## このイメージに含まれるサードパーティのソフトウェア

NodeGoatのほかに、イメージには次のものが入っています。

- **Node.js 24.22.3**：公式の `node:24.22.3-alpine3.23` イメージから（[`Dockerfile`](Dockerfile) でdigestを固定）。MITライセンスで、同梱するライブラリのライセンスは[Node.js自身のLICENSE](https://github.com/nodejs/node/blob/v24.22.3/LICENSE)に一覧があります。
- **NodeGoatの本番用npm依存関係**：`/home/node/app/node_modules` の下に400近いパッケージのフォルダがあり、`package-lock.json` が固定したとおりのもので、それぞれのフォルダに自分のライセンスファイルがあります。ほとんどがMITかISCで、例外はわずかです。Apache-2.0（`mongodb`、`mongodb-core`、`bson`、`require_optional`、`revalidator`）、BSD-3-Clause（`qs`、`source-map`）、BSD（`uglify-js`）、MIT OR Apache-2.0（`atob`）、BSD-3-Clause OR MIT（`amdefine`）、パブリックドメイン（`jsonify`）。いくつかはわざと古いもので、プロジェクトの「脆弱なコンポーネント」の教材になっています。
- **Node.jsベースのAlpine Linux 3.23パッケージ**（変更なし）：`alpine-baselayout`、`alpine-keys`、`alpine-release`、`apk-tools`、`busybox`（GPL-2.0）、`ca-certificates-bundle`、`libatomic`、`libgcc` と `libstdc++`（GCC、GPL-3.0とGCC Runtime Library Exception）、`libcrypto3` と `libssl3`（OpenSSL、Apache-2.0）、`musl`（MIT）、`scanelf`、`ssl_client`、`zlib`。GPLのパッケージも含め、ソースは3.23ブランチの[Alpineのaports](https://gitlab.alpinelinux.org/alpine/aports/-/tree/3.23-stable)にあります。もしリンクが使えなくなったら、このリポジトリにissueを立ててください。受け取ったイメージに入っているバージョンのソースをお渡しします。

## このイメージについて

[Mitsuru Technologies](https://mitsurutech.co.uk/ja)がメンテナンスしています。ブラウザでのコーディング、コンテナラボ、仮想マシンを備えた、学校向けの教育プラットフォームを作っている会社です。
