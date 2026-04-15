import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  output: 'standalone',           // ← REQUIRED for reliable Docker deploy

  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'i.ytimg.com',
      },
    ],
  },

  reactStrictMode: true,
  swcMinify: true,

  // Recommended for Next.js 15 + Docker
  experimental: {
    optimizePackageImports: ['lucide-react', 'youtubei.js'],
  },
}

export default nextConfig
