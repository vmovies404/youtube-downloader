import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  /** IMPORTANT: This is required for Docker deployment */
  output: 'standalone',

  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'i.ytimg.com',
      },
    ],
  },

  // Optional but recommended settings
  reactStrictMode: true,
  swcMinify: true,

  // Reduce bundle size
  experimental: {
    optimizePackageImports: ['framer-motion', 'lucide-react'],
  },
}

export default nextConfig
