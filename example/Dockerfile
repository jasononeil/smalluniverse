# Lix's Haxe 4.2.3 and Neko binaries for Linux are x86-64.
ARG HAXE_BUILD_PLATFORM=linux/amd64
FROM --platform=${HAXE_BUILD_PLATFORM} node:26-bookworm-slim AS build

RUN npm install --global yarn@1.22.22

WORKDIR /workspace

COPY package.json yarn.lock .haxerc ./
COPY example/package.json example/package.json
COPY haxe_libraries/ haxe_libraries/
RUN yarn install --frozen-lockfile

COPY src/ src/
COPY example/ example/
RUN yarn workspace mealplanner build

FROM node:26-alpine AS runtime

RUN addgroup -S app && adduser -S app -G app -h /app
USER app

WORKDIR /app

COPY --from=build /workspace/example/build/server.bundle.js /workspace/example/build/client.bundle.js /app/

EXPOSE 4723

CMD ["node", "server.bundle.js"]
