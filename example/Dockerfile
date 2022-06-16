FROM node:16-alpine

RUN addgroup -S app && adduser -S app -G app -h /app
USER app

WORKDIR /app

COPY build/ /app/

EXPOSE 4723

CMD node server.bundle.js
