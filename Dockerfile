FROM node:14.16-alpine
RUN apk update
WORKDIR /var/app/myapp
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
