# ==================== BUILD STAGE ====================
FROM node:20-alpine AS builder

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    ffmpeg \
    curl \
    && pip3 install --no-cache-dir --break-system-packages yt-dlp

WORKDIR /app

# Enable pnpm using corepack (no global install needed)
RUN corepack enable pnpm

COPY package.json pnpm-lock.yaml ./

# Install all dependencies (including dev for build)
RUN pnpm install --frozen-lockfile

COPY . .

# Build the app
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm build

# ==================== PRODUCTION STAGE ====================
FROM node:20-alpine AS runner

# Install runtime dependencies (ffmpeg + yt-dlp)
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

# Create non-root user
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs

# Create downloads folder
RUN mkdir -p /app/downloads \
    && chown -R nextjs:nodejs /app

# Copy standalone output from builder
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Copy package.json for production install
COPY --from=builder /app/package.json ./

# Install only production dependencies
RUN corepack enable pnpm && pnpm install --prod --frozen-lockfile

USER nextjs

EXPOSE 3000

# Use the standalone server.js created by Next.js
CMD ["node", "server.js"]
