# ==================== BUILD STAGE ====================
FROM node:20-alpine AS builder

# Install system dependencies + yt-dlp + ffmpeg
RUN apk add --no-cache \
    python3 \
    py3-pip \
    ffmpeg \
    curl \
    && pip3 install --no-cache-dir --break-system-packages yt-dlp \
    && yt-dlp --version   # Verify installation

WORKDIR /app

# Enable corepack for pnpm
RUN corepack enable pnpm

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install all dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build with standalone output (highly recommended for Docker)
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm build

# ==================== PRODUCTION STAGE ====================
FROM node:20-alpine AS runner

# Install only runtime dependencies (lighter)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    ffmpeg \
    curl \
    && pip3 install --no-cache-dir --break-system-packages yt-dlp

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs

# Create downloads directory (important for Render)
RUN mkdir -p /app/downloads \
    && chown -R nextjs:nodejs /app

# Copy built app from builder
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Install only production dependencies
COPY --from=builder /app/package.json ./
RUN corepack enable pnpm && pnpm install --prod --frozen-lockfile

USER nextjs

EXPOSE 3000

# Start the standalone server (much more reliable than pnpm start)
CMD ["node", "server.js"]
