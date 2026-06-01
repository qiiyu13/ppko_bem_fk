FROM node:20-alpine
WORKDIR /app
# libstdc++ is the runtime dependency of the native bcrypt addon. There is no
# musl prebuilt for bcrypt, so it is compiled from source via node-gyp; the
# build toolchain is installed as a virtual package and removed afterwards to
# keep the final image small.
RUN apk add --no-cache libstdc++
COPY package*.json ./
RUN apk add --no-cache --virtual .build-deps python3 make g++ \
 && npm ci --only=production \
 && apk del .build-deps
COPY prisma/ ./prisma/
RUN npx prisma generate
COPY src/ ./src/
RUN mkdir -p /app/uploads/avatars /app/uploads/articles
EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node src/index.js"]
