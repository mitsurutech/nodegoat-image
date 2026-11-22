# Image conteneur OWASP NodeGoat : une application Node.js vulnérable exprès, construite depuis la source

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

Une image Docker multi-architecture d'**OWASP NodeGoat**, l'application web Node.js et Express volontairement non sécurisée, pour apprendre l'OWASP Top 10 dans une base de code Node.js : injection de JavaScript côté serveur, injection NoSQL dans MongoDB, authentification et sessions défaillantes, cross-site scripting, références directes à des objets non sécurisées, contrôle d'accès manquant, CSRF, composants vulnérables, redirection ouverte et ReDoS. Elle est publiée sous **`ghcr.io/mitsurutech/owasp-nodegoat`** pour `linux/amd64` et `linux/arm64`.

> **NodeGoat est vulnérable par conception.** Ne le lancez que sur une machine et un réseau que vous contrôlez, n'exposez jamais son port sur internet et n'y mettez jamais de vraies données.

Le projet OWASP publie NodeGoat sous forme de code source avec un Dockerfile, pas sous forme d'image. Ce dépôt en construit donc une, de façon transparente :

- **La source amont à un commit épinglé.** Le Dockerfile télécharge l'archive GitHub d'[OWASP/NodeGoat](https://github.com/OWASP/NodeGoat) au commit `c5cb68a7084e4ae7dcc60e6a98768720a81841e8` et la vérifie avec [`SHA256SUMS`](SHA256SUMS) avant de la décompresser. Rien n'est changé dans NodeGoat : ses failles sont justement le sujet.
- **Les dépendances installées à la construction de l'image.** `npm ci --omit=dev` installe exactement ce que nomme le `package-lock.json` du projet, sans lancer aucun script d'installation, si bien qu'un conteneur démarré à partir de l'image n'a besoin d'aucun réseau.
- **Les données de départ au démarrage.** Le point d'entrée, [`nodegoat-start`](nodegoat-start), attend MongoDB, charge les comptes de départ de NodeGoat avec son propre `artifacts/db-reset.js` (comme le fait le fichier compose du projet) et lance le site sur le port 4000.
- **Sans privilèges.** Elle tourne sous le compte `node` de l'image Node.js officielle sur Alpine.

NodeGoat a besoin de **MongoDB 4.4** : son pilote de base de données (`mongodb` 2.2) parle une version du protocole que les serveurs plus récents n'acceptent plus. L'image officielle `mongo:4.4` fonctionne.

```sh
docker network create nodegoat
docker run -d --name mongo --network nodegoat mongo:4.4.29
docker run -d --name nodegoat --network nodegoat -p 127.0.0.1:4000:4000 ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a
```

Ouvrez ensuite http://127.0.0.1:4000/ et connectez-vous en tant que `user1` avec le mot de passe `User1_123` (ou `admin` / `Admin_123`), deux comptes de départ fournis par NodeGoat. `MONGODB_URI` (par défaut `mongodb://mongo:27017/nodegoat`) et `PORT` (par défaut `4000`) changent l'endroit où il cherche sa base et le port qu'il écoute. Épinglez l'image par digest partout où cela compte, par exemple dans le fichier compose d'un labo : `ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a@sha256:<digest>`.

## Où elle sert

C'est l'application du [labo NodeGoat](https://github.com/mitsurutech/lab-nodegoat-lab), un labo en conteneur de la plateforme d'enseignement de MitsuruTech, où chaque étudiant attaque sa propre copie sans accès à internet, puis lit dans la source le correctif placé à côté de chaque faille. La [page de ce labo](https://mitsurutech.co.uk/fr/help/lab-nodegoat-lab) dans le manuel d'aide dit ce qu'il enseigne, et le [guide des labos en conteneur](https://mitsurutech.co.uk/fr/help/labs) explique comment un établissement en fait tourner un. Les enseignants peuvent découvrir la [plateforme d'apprentissage](https://mitsurutech.co.uk/fr/learning), consulter les [tarifs](https://mitsurutech.co.uk/fr/pricing) ou [créer un compte](https://mitsurutech.co.uk/fr/signup).

## Passer à un commit plus récent de NodeGoat

1. Modifiez `ARG NODEGOAT_COMMIT` (et `ARG NODEGOAT_VERSION` si `package.json` a changé) dans le `Dockerfile`.
2. Remplacez la ligne de `SHA256SUMS` par le SHA-256 de `https://github.com/OWASP/NodeGoat/archive/<commit>.tar.gz`, nommé `NodeGoat-<commit>.tar.gz`.
3. Poussez sur `main`. Le workflow construit les deux architectures et publie le nouveau tag ; les tags existants ne sont pas touchés.

## Licence

NodeGoat est sous licence Apache-2.0, par le projet OWASP NodeGoat ; sa licence est livrée dans l'image, à `/home/node/app/LICENSE`, et se trouve dans [`LICENSE`](LICENSE). Le Dockerfile, le point d'entrée et le workflow de ce dépôt sont proposés aux mêmes conditions. Cette image n'est ni réalisée ni approuvée par l'OWASP.

## Logiciels tiers dans cette image

En plus de NodeGoat, l'image contient :

- **Node.js 24.22.3**, issu de l'image officielle `node:24.22.3-alpine3.23` (épinglée par digest dans le [`Dockerfile`](Dockerfile)), sous licence MIT, les licences des bibliothèques qu'il embarque étant listées dans [le LICENSE de Node.js](https://github.com/nodejs/node/blob/v24.22.3/LICENSE).
- **Les dépendances npm de production de NodeGoat**, près de 400 dossiers de paquets sous `/home/node/app/node_modules`, exactement comme son `package-lock.json` les épingle, chacun avec son propre fichier de licence dans son dossier. Elles sont sous MIT ou ISC, à quelques exceptions près : Apache-2.0 (`mongodb`, `mongodb-core`, `bson`, `require_optional`, `revalidator`), BSD-3-Clause (`qs`, `source-map`), BSD (`uglify-js`), MIT OR Apache-2.0 (`atob`), BSD-3-Clause OR MIT (`amdefine`) et domaine public (`jsonify`). Plusieurs sont anciennes exprès, puisqu'elles servent à la leçon du projet sur les « composants vulnérables ».
- **Les paquets Alpine Linux 3.23** de la base Node.js, non modifiés : `alpine-baselayout`, `alpine-keys`, `alpine-release`, `apk-tools`, `busybox` (GPL-2.0), `ca-certificates-bundle`, `libatomic`, `libgcc` et `libstdc++` (GCC, GPL-3.0 avec la GCC Runtime Library Exception), `libcrypto3` et `libssl3` (OpenSSL, Apache-2.0), `musl` (MIT), `scanelf`, `ssl_client` et `zlib`. Leur source, y compris celle des paquets sous GPL, se trouve dans les [aports d'Alpine](https://gitlab.alpinelinux.org/alpine/aports/-/tree/3.23-stable) pour la branche 3.23 ; si un lien ne fonctionne plus un jour, ouvrez une issue sur ce dépôt et nous fournirons la source de la version contenue dans l'image que vous avez reçue.

## À propos

Maintenu par [Mitsuru Technologies](https://mitsurutech.co.uk/fr), qui construit une plateforme d'enseignement pour les établissements, avec du code dans le navigateur, des labos en conteneur et des machines virtuelles.
