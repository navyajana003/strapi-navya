FROM node:18

WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install dependencies (with pg)
RUN npm install && npm install pg

COPY . .

RUN npm run build

EXPOSE 1337

CMD ["npm", "start"]
