FROM node:20-alpine

WORKDIR /app

# Install dependencies first (better layer caching).
COPY package*.json ./
RUN npm install --omit=dev

# Copy the source.
COPY . .

EXPOSE 3000

# Run migrations, then start the server.
CMD ["sh", "-c", "npm run migrate && npm start"]
