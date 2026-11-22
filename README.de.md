# Container-Image von OWASP NodeGoat: eine absichtlich verwundbare Node.js-Anwendung, aus dem Quellcode gebaut

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

Ein Docker-Image für mehrere Architekturen mit **OWASP NodeGoat**, der absichtlich unsicheren Webanwendung mit Node.js und Express, um die OWASP Top 10 an einer Node.js-Codebasis zu lernen: serverseitige JavaScript-Injection, NoSQL-Injection in MongoDB, fehlerhafte Authentifizierung und Sitzungen, Cross-Site-Scripting, unsichere direkte Objektreferenzen, fehlende Zugriffskontrolle, CSRF, verwundbare Komponenten, eine offene Weiterleitung und ReDoS. Es wird als **`ghcr.io/mitsurutech/owasp-nodegoat`** für `linux/amd64` und `linux/arm64` veröffentlicht.

> **NodeGoat ist absichtlich verwundbar.** Betreiben Sie es nur auf einer Maschine und in einem Netzwerk, die Sie kontrollieren, veröffentlichen Sie seinen Port nie im Internet und legen Sie nie echte Daten darin ab.

Das OWASP-Projekt veröffentlicht NodeGoat als Quellcode mit einem Dockerfile, nicht als Image. Deshalb baut dieses Repository eines, offen für alle einsehbar:

- **Der Upstream-Quellcode bei einem festgelegten Commit.** Das Dockerfile lädt das GitHub-Archiv von [OWASP/NodeGoat](https://github.com/OWASP/NodeGoat) beim Commit `c5cb68a7084e4ae7dcc60e6a98768720a81841e8` herunter und prüft es vor dem Entpacken gegen [`SHA256SUMS`](SHA256SUMS). An NodeGoat wird nichts geändert: Seine Schwachstellen sind ja der Zweck.
- **Abhängigkeiten werden beim Bauen des Images installiert.** `npm ci --omit=dev` installiert genau das, was die `package-lock.json` des Projekts nennt, ohne Installationsskripte auszuführen, sodass ein aus dem Image gestarteter Container überhaupt kein Netzwerk braucht.
- **Startdaten beim Start.** Der Einstiegspunkt [`nodegoat-start`](nodegoat-start) wartet auf MongoDB, lädt die Startkonten von NodeGoat mit dessen eigenem `artifacts/db-reset.js` (wie die Compose-Datei des Projekts) und startet die Website auf Port 4000.
- **Ohne Rechte.** Es läuft unter dem Konto `node` des offiziellen Node.js-Images auf Alpine.

NodeGoat braucht **MongoDB 4.4**: Sein Datenbanktreiber (`mongodb` 2.2) spricht ein Wire-Protokoll, das neuere Server nicht mehr annehmen. Das offizielle Image `mongo:4.4` funktioniert.

```sh
docker network create nodegoat
docker run -d --name mongo --network nodegoat mongo:4.4.29
docker run -d --name nodegoat --network nodegoat -p 127.0.0.1:4000:4000 ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a
```

Öffnen Sie dann http://127.0.0.1:4000/ und melden Sie sich als `user1` mit dem Passwort `User1_123` an (oder `admin` / `Admin_123`), beides Startkonten, die NodeGoat mitbringt. `MONGODB_URI` (Standard `mongodb://mongo:27017/nodegoat`) und `PORT` (Standard `4000`) ändern, wo es seine Datenbank sucht und auf welchem Port es lauscht. Legen Sie das Image überall, wo es darauf ankommt, per Digest fest, zum Beispiel in der Compose-Datei eines Labs: `ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a@sha256:<digest>`.

## Wo es eingesetzt wird

Es ist die Anwendung im [NodeGoat-Lab](https://github.com/mitsurutech/lab-nodegoat-lab), einem Container-Lab auf der Lehrplattform von MitsuruTech, in dem alle Studierenden eine private Kopie ohne Weg ins Internet angreifen und danach im Quellcode die Behebung neben jeder Schwachstelle lesen. Die [Seite zu diesem Lab](https://mitsurutech.co.uk/de/help/lab-nodegoat-lab) im Hilfehandbuch beschreibt, was es vermittelt, und der [Leitfaden zu Container-Labs](https://mitsurutech.co.uk/de/help/labs) erklärt, wie eine Schule eines betreibt. Lehrkräfte können mehr über die [Learning Platform](https://mitsurutech.co.uk/de/learning) lesen, die [Preise](https://mitsurutech.co.uk/de/pricing) ansehen oder sich [registrieren](https://mitsurutech.co.uk/de/signup).

## Auf einen neueren Commit von NodeGoat aktualisieren

1. Ändern Sie `ARG NODEGOAT_COMMIT` (und `ARG NODEGOAT_VERSION`, falls sich `package.json` geändert hat) im `Dockerfile`.
2. Ersetzen Sie die Zeile in `SHA256SUMS` durch den SHA-256 von `https://github.com/OWASP/NodeGoat/archive/<commit>.tar.gz`, benannt als `NodeGoat-<commit>.tar.gz`.
3. Pushen Sie nach `main`. Der Workflow baut beide Architekturen und veröffentlicht den neuen Tag; vorhandene Tags bleiben unberührt.

## Lizenz

NodeGoat steht unter der Lizenz Apache-2.0 des OWASP-NodeGoat-Projekts; seine Lizenz liegt im Image unter `/home/node/app/LICENSE` und in [`LICENSE`](LICENSE). Das Dockerfile, der Einstiegspunkt und der Workflow hier werden zu denselben Bedingungen angeboten. Dieses Image wird von OWASP weder erstellt noch empfohlen.

## Software von Drittanbietern in diesem Image

Neben NodeGoat enthält das Image:

- **Node.js 24.22.3** aus dem offiziellen Image `node:24.22.3-alpine3.23` (per Digest im [`Dockerfile`](Dockerfile) festgelegt), MIT, wobei die Lizenzen der mitgelieferten Bibliotheken in [der LICENSE von Node.js](https://github.com/nodejs/node/blob/v24.22.3/LICENSE) aufgeführt sind.
- **Die npm-Abhängigkeiten von NodeGoat für den Produktivbetrieb**, fast 400 Paketordner unter `/home/node/app/node_modules`, genau so, wie die `package-lock.json` sie festlegt, jeder mit seiner eigenen Lizenzdatei im Ordner. Sie stehen unter MIT oder ISC, bis auf wenige: Apache-2.0 (`mongodb`, `mongodb-core`, `bson`, `require_optional`, `revalidator`), BSD-3-Clause (`qs`, `source-map`), BSD (`uglify-js`), MIT OR Apache-2.0 (`atob`), BSD-3-Clause OR MIT (`amdefine`) und gemeinfrei (`jsonify`). Mehrere sind absichtlich alt, denn sie bilden die Lektion des Projekts zu „verwundbaren Komponenten“.
- **Die Pakete von Alpine Linux 3.23** aus der Node.js-Basis, unverändert: `alpine-baselayout`, `alpine-keys`, `alpine-release`, `apk-tools`, `busybox` (GPL-2.0), `ca-certificates-bundle`, `libatomic`, `libgcc` und `libstdc++` (GCC, GPL-3.0 mit der GCC Runtime Library Exception), `libcrypto3` und `libssl3` (OpenSSL, Apache-2.0), `musl` (MIT), `scanelf`, `ssl_client` und `zlib`. Ihr Quellcode, auch der der GPL-Pakete, liegt in den [aports von Alpine](https://gitlab.alpinelinux.org/alpine/aports/-/tree/3.23-stable) für den Branch 3.23; sollte ein Link einmal nicht mehr funktionieren, eröffnen Sie bitte ein Issue in diesem Repository, und wir stellen Ihnen den Quellcode der Version in dem Image bereit, das Sie erhalten haben.

## Über uns

Gepflegt von [Mitsuru Technologies](https://mitsurutech.co.uk/de), das eine Lehrplattform für Schulen und Colleges mit Programmieren im Browser, Container-Labs und virtuellen Maschinen entwickelt.
