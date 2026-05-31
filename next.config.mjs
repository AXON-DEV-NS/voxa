import createNextIntlPlugin from "next-intl/plugin";

const withNextIntl = createNextIntlPlugin("./i18n/request.ts");

/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "images.unsplash.com" },
      { protocol: "https", hostname: "image.pollinations.ai" },
      { protocol: "https", hostname: "assets.mixkit.co" },
      { protocol: "https", hostname: "*.supabase.co" },
      { protocol: "https", hostname: "lh3.googleusercontent.com" },
    ],
  },
  experimental: {
    serverActions: { bodySizeLimit: "50mb" },
  },
  typescript: { ignoreBuildErrors: !!process.env.CI },
};

export default withNextIntl(nextConfig);
