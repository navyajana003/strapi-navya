FROM node:20

WORKDIR /app

RUN npm install -g create-strapi-app

COPY . .

RUN npm install

EXPOSE 1337

CMD ["npm", "run", "develop"]