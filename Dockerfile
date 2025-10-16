FROM node:20-alpine

WORKDIR /usr/src/app
COPY app/package*.json ./
RUN npm ci --only=production
COPY app/ ./

EXPOSE 3000
CMD ["node", "server.js"]
