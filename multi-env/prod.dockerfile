# Node.js version 6 base image
FROM node:6

# Production app runs on port 8080
EXPOSE 8080

# Copy source files into container
COPY ./src /app

# Set working directory to where source is
WORKDIR /app

# Install production dependencies and build app
RUN npm install --production && npm run build

# Start the server in production mode
CMD ["npm", "start"]