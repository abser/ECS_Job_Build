FROM node:14.16-alpine
RUN apk update
WORKDIR /var/app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3002
CMD ["npm", "start"]
