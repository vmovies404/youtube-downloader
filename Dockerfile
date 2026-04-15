# ==================== BUILD STAGE ====================
FROM node:20-alpine AS builder

# Install yt-dlp + ffmpeg
RUN apk add --no-cache \
    python3 \
    py3-pip \
    ffmpeg \
    curl \
    && pip3 install --no-cache-dir --break-system-packages yt-dlp

WORKDIR /app

# Setup pnpm
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm build

# ==================== PRODUCTION STAGE ====================
FROM node:20-alpine AS runner

# Install runtime deps
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

# Setup pnpm
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs

RUN mkdir -p /app/downloads && chown -R nextjs:nodejs /app

# Copy standalone output
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-lock.yaml ./

# Production dependencies only
RUN pnpm install --prod --frozen-lockfile

USER nextjs

EXPOSE 3000

# ✅ Correct start command for standalone output
CMD ["node", "server.js"]
