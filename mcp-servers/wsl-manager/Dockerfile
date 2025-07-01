FROM node:18-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Make executable
RUN chmod +x index.js

# Expose port
EXPOSE 3000

# Start the MCP server
CMD ["npm", "start"]