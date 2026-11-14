# syntax=docker/dockerfile:1.7
#
# OWASP NodeGoat, a Node.js and Express web application that is insecure on purpose, as a
# container image for teaching. It must never be reachable from the internet.
#
# The source is the upstream repository at one pinned commit, downloaded as GitHub's archive of
# that commit and checked against SHA256SUMS before anything is unpacked. Its dependencies are
# installed with `npm ci` from the project's own package-lock.json, production ones only, at
# build time, so a container started from this image needs no network at all. Nothing in
# NodeGoat is patched: the weaknesses are the point. The result runs as the unprivileged `node`
# account of the official Node.js image.
#
# What the container does when it starts is `nodegoat-start`, below: wait for MongoDB, load
# NodeGoat's own seed data with its `artifacts/db-reset.js`, then start the site on port 4000.

ARG NODEGOAT_COMMIT=c5cb68a7084e4ae7dcc60e6a98768720a81841e8
ARG NODEGOAT_VERSION=1.3.0

# The build stage runs on the build machine's own platform: with --ignore-scripts every dependency
# is plain JavaScript, so the same node_modules serves amd64 and arm64 and no emulation is needed.
FROM --platform=$BUILDPLATFORM docker.io/library/node:24.22.3-alpine3.23@sha256:3946fb783fdce8a2812136ea694bc95c698c4f4096f3fd18568dc27a8ac389dc AS build
ARG NODEGOAT_COMMIT
COPY SHA256SUMS /SHA256SUMS
WORKDIR /src
RUN set -eu; \
    file="NodeGoat-${NODEGOAT_COMMIT}.tar.gz"; \
    wget -q -O "$file" "https://github.com/OWASP/NodeGoat/archive/${NODEGOAT_COMMIT}.tar.gz"; \
    grep " ${file}\$" /SHA256SUMS | sha256sum -c -; \
    tar -xzf "$file"; \
    mv "NodeGoat-${NODEGOAT_COMMIT}" /app
WORKDIR /app
# --ignore-scripts: no install script of any dependency runs on the build machine. Nothing
# NodeGoat needs at run time has one (its password hashing is the pure JavaScript bcrypt-nodejs).
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
 && rm -rf /root/.npm test cypress.json .github

FROM docker.io/library/node:24.22.3-alpine3.23@sha256:3946fb783fdce8a2812136ea694bc95c698c4f4096f3fd18568dc27a8ac389dc
ARG NODEGOAT_COMMIT
ARG NODEGOAT_VERSION
LABEL org.opencontainers.image.title="nodegoat" \
      org.opencontainers.image.description="OWASP NodeGoat, a deliberately vulnerable Node.js app for teaching, built from source at a pinned commit; never expose it" \
      org.opencontainers.image.version="${NODEGOAT_VERSION}-${NODEGOAT_COMMIT}" \
      org.opencontainers.image.revision="${NODEGOAT_COMMIT}" \
      org.opencontainers.image.source="https://github.com/mitsurutech/nodegoat-image" \
      org.opencontainers.image.url="https://mitsurutech.co.uk/help/lab-nodegoat-lab" \
      org.opencontainers.image.vendor="Mitsuru Technologies" \
      org.opencontainers.image.licenses="Apache-2.0"
COPY --from=build --chown=root:root /app /home/node/app
COPY --chmod=0755 nodegoat-start /usr/local/bin/nodegoat-start
ENV NODE_ENV=production \
    PORT=4000 \
    MONGODB_URI=mongodb://mongo:27017/nodegoat
USER node
WORKDIR /home/node/app
EXPOSE 4000
ENTRYPOINT ["/usr/local/bin/nodegoat-start"]
