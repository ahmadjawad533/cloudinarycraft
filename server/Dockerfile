# Stage 1: Dependency resolution and pruning
FROM node:20-alpine AS deps

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --omit=dev

# Stage 2: Hardened Minimal Production Runtime
FROM node:20-alpine AS runner

# Install dumb-init for proper signal handling (PID 1)
RUN apk add --no-cache dumb-init

ENV NODE_ENV=production
ENV PORT=5001

WORKDIR /usr/src/app

# Copy production node_modules from deps stage
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY package*.json ./
COPY server.js ./

# Assign ownership to unprivileged built-in node user
RUN chown -R node:node /usr/src/app

# Switch to non-root user
USER node

# Expose backend service port
EXPOSE 5001

# Container healthcheck using Node's native fetch
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:' + (process.env.PORT || 5001) + '/healthz').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
