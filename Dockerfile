FROM node:24-alpine
WORKDIR /app
COPY app/package*.json ./
RUN npm install --omit=dev --no-audit --no-fund
COPY app/ ./
ARG APP_REVISION=local
ENV NODE_ENV=production PORT=3000 APP_REVISION=${APP_REVISION}
USER node
EXPOSE 3000
CMD ["node", "server.js"]
