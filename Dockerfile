# Use an official Node.js runtime as a parent image
FROM node:18-alpine

# Set the working directory to /app
WORKDIR /app

# Copy the backend folder contents to the working directory
# We only copy backend because that's what needs to be deployed as the server
COPY backend/package*.json ./
RUN npm install

# Copy the rest of the backend code
COPY backend/ .

# Expose the port the app runs on
EXPOSE 8000

# Define the command to run your app
CMD ["node", "server.js"]
