# OWASP NodeGoat container image: a deliberately vulnerable Node.js app, built from source

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

A multi-architecture Docker image of **OWASP NodeGoat**, the Node.js and Express web application that is insecure on purpose, for learning the OWASP Top 10 in a Node.js code base: server-side JavaScript injection, NoSQL injection in MongoDB, broken authentication and sessions, cross-site scripting, insecure direct object references, missing access control, CSRF, vulnerable components, an open redirect and ReDoS. It is published at **`ghcr.io/mitsurutech/owasp-nodegoat`** for `linux/amd64` and `linux/arm64`.

> **NodeGoat is vulnerable by design.** Run it only on a machine and a network you control, never publish its port to the internet, and never put real data in it.

The OWASP project publishes NodeGoat as source code with a Dockerfile, not as an image, so this repository builds one in the open:

- **Upstream source at one pinned commit.** The Dockerfile downloads GitHub's archive of [OWASP/NodeGoat](https://github.com/OWASP/NodeGoat) at commit `c5cb68a7084e4ae7dcc60e6a98768720a81841e8` and checks it against [`SHA256SUMS`](SHA256SUMS) before unpacking it. Nothing in NodeGoat is changed: its weaknesses are the point.
- **Dependencies installed when the image is built.** `npm ci --omit=dev` installs exactly what the project's own `package-lock.json` names, with no install scripts run, so a container started from the image needs no network at all.
- **Seed data at start.** The entrypoint, [`nodegoat-start`](nodegoat-start), waits for MongoDB, loads NodeGoat's own seed accounts with its `artifacts/db-reset.js` (as the project's compose file does) and starts the site on port 4000.
- **Unprivileged.** It runs as the `node` account of the official Node.js image on Alpine.

NodeGoat needs **MongoDB 4.4**: its database driver (`mongodb` 2.2) speaks a wire protocol newer servers no longer accept. The official `mongo:4.4` image works.

```sh
docker network create nodegoat
docker run -d --name mongo --network nodegoat mongo:4.4.29
docker run -d --name nodegoat --network nodegoat -p 127.0.0.1:4000:4000 ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a
```

Then open http://127.0.0.1:4000/ and sign in as `user1` with the password `User1_123` (or `admin` / `Admin_123`). `MONGODB_URI` (default `mongodb://mongo:27017/nodegoat`) and `PORT` (default `4000`) change where it looks and listens. Pin the image by digest in anything that matters, for example a lab's compose file: `ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a@sha256:<digest>`.

## Where it is used

It is the application in the [NodeGoat lab](https://github.com/mitsurutech/lab-nodegoat-lab), a container lab on MitsuruTech's teaching platform where each student attacks a private copy with no way out to the internet, then reads the fix beside each weakness in the source. The help manual's [page for that lab](https://mitsurutech.co.uk/help/lab-nodegoat-lab) says what it teaches, and the [guide to container labs](https://mitsurutech.co.uk/help/labs) says how a college runs one. Teachers can read about the [Learning Platform](https://mitsurutech.co.uk/learning), see [pricing](https://mitsurutech.co.uk/pricing) or [sign up](https://mitsurutech.co.uk/signup).

## Updating to a newer NodeGoat commit

1. Change `ARG NODEGOAT_COMMIT` (and `ARG NODEGOAT_VERSION` if `package.json` moved) in the `Dockerfile`.
2. Replace the line in `SHA256SUMS` with the SHA-256 of `https://github.com/OWASP/NodeGoat/archive/<commit>.tar.gz`, named `NodeGoat-<commit>.tar.gz`.
3. Push to `main`. The workflow builds both architectures and publishes the new tag; existing tags are left alone.

## Licence

NodeGoat is licensed Apache-2.0 by the OWASP NodeGoat project; its licence ships inside the image at `/home/node/app/LICENSE` and is in [`LICENSE`](LICENSE). The Dockerfile, entrypoint and workflow here are offered under the same terms. This image is not made or endorsed by OWASP.

## Third-party software in this image

Besides NodeGoat, the image holds:

- **Node.js 24.22.3** from the official `node:24.22.3-alpine3.23` image (pinned by digest in the [`Dockerfile`](Dockerfile)), MIT, with the licences of the libraries it bundles listed in [Node.js's own LICENSE](https://github.com/nodejs/node/blob/v24.22.3/LICENSE).
- **NodeGoat's production npm dependencies**, nearly 400 package folders under `/home/node/app/node_modules`, exactly as its `package-lock.json` pins them, each with its own licence file in its folder. They are MIT or ISC apart from a handful: Apache-2.0 (`mongodb`, `mongodb-core`, `bson`, `require_optional`, `revalidator`), BSD-3-Clause (`qs`, `source-map`), BSD (`uglify-js`), MIT OR Apache-2.0 (`atob`), BSD-3-Clause OR MIT (`amdefine`) and public domain (`jsonify`). Several are old on purpose, being the project's "vulnerable components" lesson.
- **The Alpine Linux 3.23 packages** of the Node.js base, unmodified: `alpine-baselayout`, `alpine-keys`, `alpine-release`, `apk-tools`, `busybox` (GPL-2.0), `ca-certificates-bundle`, `libatomic`, `libgcc` and `libstdc++` (GCC, GPL-3.0 with the GCC Runtime Library Exception), `libcrypto3` and `libssl3` (OpenSSL, Apache-2.0), `musl` (MIT), `scanelf`, `ssl_client` and `zlib`. Their source, including that of the GPL packages, is at [Alpine's aports](https://gitlab.alpinelinux.org/alpine/aports/-/tree/3.23-stable) for the 3.23 branch; if a link ever stops working, open an issue on this repository and we will provide the source for the version in the image you received.

## About

Maintained by [Mitsuru Technologies](https://mitsurutech.co.uk), which builds a teaching platform for colleges with browser-based coding, container labs and virtual machines.
