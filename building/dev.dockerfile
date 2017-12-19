# Node.js version 6 base image
FROM node:6
# use nodemon for development
RUN npm install --global nodemon
# use cached layer for node modules
RUN mkdir src
WORKDIR /src
ADD src/package.json /src/package.json
RUN npm install

# Development app runs on port 3000
EXPOSE 3000

# Watch for changes
CMD ["nodemon", "-L", "/src/app/bin/www"]