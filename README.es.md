# Imagen de contenedor de OWASP NodeGoat: una aplicación Node.js vulnerable a propósito, construida desde el código fuente

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

Una imagen Docker multiarquitectura de **OWASP NodeGoat**, la aplicación web de Node.js y Express que es insegura a propósito, para aprender el OWASP Top 10 en un código Node.js: inyección de JavaScript en el servidor, inyección NoSQL en MongoDB, autenticación y sesiones rotas, cross-site scripting, referencias directas inseguras a objetos, control de acceso ausente, CSRF, componentes vulnerables, una redirección abierta y ReDoS. Se publica en **`ghcr.io/mitsurutech/owasp-nodegoat`** para `linux/amd64` y `linux/arm64`.

> **NodeGoat es vulnerable por diseño.** Ejecútalo solo en una máquina y una red que controles, no publiques nunca su puerto en internet y no le pongas nunca datos reales.

El proyecto OWASP publica NodeGoat como código fuente con un Dockerfile, no como imagen, así que este repositorio construye una a la vista de todos:

- **El código original en un commit fijado.** El Dockerfile descarga el archivo de GitHub de [OWASP/NodeGoat](https://github.com/OWASP/NodeGoat) en el commit `c5cb68a7084e4ae7dcc60e6a98768720a81841e8` y lo comprueba con [`SHA256SUMS`](SHA256SUMS) antes de descomprimirlo. En NodeGoat no se cambia nada: sus debilidades son lo que se viene a estudiar.
- **Dependencias instaladas al construir la imagen.** `npm ci --omit=dev` instala exactamente lo que dice el `package-lock.json` del proyecto, sin ejecutar scripts de instalación, así que un contenedor arrancado desde la imagen no necesita red.
- **Datos iniciales al arrancar.** El punto de entrada, [`nodegoat-start`](nodegoat-start), espera a MongoDB, carga las cuentas iniciales de NodeGoat con su propio `artifacts/db-reset.js` (como hace el archivo compose del proyecto) y arranca el sitio en el puerto 4000.
- **Sin privilegios.** Se ejecuta con la cuenta `node` de la imagen oficial de Node.js sobre Alpine.

NodeGoat necesita **MongoDB 4.4**: su controlador de base de datos (`mongodb` 2.2) habla una versión del protocolo que los servidores más nuevos ya no aceptan. La imagen oficial `mongo:4.4` funciona.

```sh
docker network create nodegoat
docker run -d --name mongo --network nodegoat mongo:4.4.29
docker run -d --name nodegoat --network nodegoat -p 127.0.0.1:4000:4000 ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a
```

Después abre http://127.0.0.1:4000/ e inicia sesión como `user1` con la contraseña `User1_123` (o `admin` / `Admin_123`), dos de las cuentas iniciales que trae NodeGoat. `MONGODB_URI` (por defecto `mongodb://mongo:27017/nodegoat`) y `PORT` (por defecto `4000`) cambian dónde busca la base de datos y en qué puerto escucha. Fija la imagen por digest en todo lo que importe, por ejemplo en el archivo compose de un laboratorio: `ghcr.io/mitsurutech/owasp-nodegoat:1.3.0-c5cb68a@sha256:<digest>`.

## Dónde se usa

Es la aplicación del [laboratorio de NodeGoat](https://github.com/mitsurutech/lab-nodegoat-lab), un laboratorio de contenedores de la plataforma de enseñanza de MitsuruTech donde cada estudiante ataca su propia copia sin salida a internet y luego lee en el código la corrección junto a cada debilidad. La [página de ese laboratorio](https://mitsurutech.co.uk/es/help/lab-nodegoat-lab) en el manual de ayuda explica qué enseña, y la [guía de los laboratorios de contenedores](https://mitsurutech.co.uk/es/help/labs) explica cómo lo pone en marcha un centro. Los profesores pueden leer sobre la [plataforma de aprendizaje](https://mitsurutech.co.uk/es/learning), ver los [precios](https://mitsurutech.co.uk/es/pricing) o [crear una cuenta](https://mitsurutech.co.uk/es/signup).

## Actualizar a un commit más reciente de NodeGoat

1. Cambia `ARG NODEGOAT_COMMIT` (y `ARG NODEGOAT_VERSION` si `package.json` ha cambiado) en el `Dockerfile`.
2. Sustituye la línea de `SHA256SUMS` por el SHA-256 de `https://github.com/OWASP/NodeGoat/archive/<commit>.tar.gz`, con el nombre `NodeGoat-<commit>.tar.gz`.
3. Haz push a `main`. El workflow construye las dos arquitecturas y publica la nueva etiqueta; las etiquetas que ya existen no se tocan.

## Licencia

NodeGoat tiene licencia Apache-2.0 del proyecto OWASP NodeGoat; su licencia va dentro de la imagen, en `/home/node/app/LICENSE`, y está en [`LICENSE`](LICENSE). El Dockerfile, el punto de entrada y el workflow de aquí se ofrecen en las mismas condiciones. Esta imagen no la hace ni la respalda OWASP.

## Software de terceros en esta imagen

Además de NodeGoat, la imagen contiene:

- **Node.js 24.22.3**, de la imagen oficial `node:24.22.3-alpine3.23` (fijada por digest en el [`Dockerfile`](Dockerfile)), con licencia MIT; las licencias de las bibliotecas que incluye están en [el LICENSE de Node.js](https://github.com/nodejs/node/blob/v24.22.3/LICENSE).
- **Las dependencias npm de producción de NodeGoat**, casi 400 carpetas de paquetes en `/home/node/app/node_modules`, tal como las fija su `package-lock.json`, cada una con su propio archivo de licencia en su carpeta. Son MIT o ISC salvo unas pocas: Apache-2.0 (`mongodb`, `mongodb-core`, `bson`, `require_optional`, `revalidator`), BSD-3-Clause (`qs`, `source-map`), BSD (`uglify-js`), MIT OR Apache-2.0 (`atob`), BSD-3-Clause OR MIT (`amdefine`) y dominio público (`jsonify`). Varias son antiguas a propósito, porque forman la lección del proyecto sobre "componentes vulnerables".
- **Los paquetes de Alpine Linux 3.23** de la base de Node.js, sin modificar: `alpine-baselayout`, `alpine-keys`, `alpine-release`, `apk-tools`, `busybox` (GPL-2.0), `ca-certificates-bundle`, `libatomic`, `libgcc` y `libstdc++` (GCC, GPL-3.0 con la GCC Runtime Library Exception), `libcrypto3` y `libssl3` (OpenSSL, Apache-2.0), `musl` (MIT), `scanelf`, `ssl_client` y `zlib`. Su código fuente, incluido el de los paquetes GPL, está en los [aports de Alpine](https://gitlab.alpinelinux.org/alpine/aports/-/tree/3.23-stable) de la rama 3.23; si algún enlace deja de funcionar, abre una issue en este repositorio y te daremos el código fuente de la versión que contiene la imagen que recibiste.

## Acerca de

Lo mantiene [Mitsuru Technologies](https://mitsurutech.co.uk/es), que crea una plataforma de enseñanza para centros educativos con programación en el navegador, laboratorios de contenedores y máquinas virtuales.
