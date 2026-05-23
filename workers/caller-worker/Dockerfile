FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY tsconfig.json ./
COPY src/ ./src/

ENV III_URL=ws://localhost:49134

CMD ["npx", "tsx", "src/worker.ts"]
