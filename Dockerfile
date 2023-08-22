FROM node:13-alpine

RUN mkdir -p /home/app2

COPY ./* /home/app2/

WORKDIR /home/app2

RUN npm install

CMD ["node", "server.js"]
