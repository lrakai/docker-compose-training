# Node.js version 6 base image
FROM node:6
# use nodemon for development
RUN npm install --global nodemon
# use cached layer for node modules
ADD src/package.json /tmp/package.json
RUN cd /tmp && npm install
RUN mkdir -p /usr/src && cp -a /tmp/node_modules /usr/src/

WORKDIR /usr/src
# Copy source files into container
ADD ./src /usr/src
# Development app runs on port 5000
EXPOSE 5000
# build the app
RUN npm run build

# Watch for changes
CMD ["nodemon", "-L", "/usr/src/bin/www"]