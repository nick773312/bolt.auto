FROM node:20.18.0 AS base
WORKDIR /app

# Install git and pnpm
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN npm install -g pnpm@8.15.4

# Copy package files and install dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# Copy source code
COPY . .

# Initialize git for build (required for some scripts)
RUN git init && \
    git config --global user.email "build@example.com" && \
    git config --global user.name "Build Process" && \
    git add . && \
    git commit -m "Initial commit for build"

# Build the application
ENV NODE_ENV=production \
    RUNNING_IN_DOCKER=true \
    VITE_CJS_IGNORE_WARNING=true \
    VITE_CJS_TRACE=true \
    HOST=0.0.0.0 \
    WRANGLER_SEND_METRICS=false
RUN mkdir -p /root/.config/.wrangler && \
    echo '{"enabled":false}' > /root/.config/.wrangler/metrics.json
RUN NODE_OPTIONS="--max_old_space_size=4096 --expose-gc" pnpm run build

# Start the application
CMD ["pnpm", "run", "dockerstart"]