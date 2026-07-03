import type { NextConfig } from "next";

const apiUrl = process.env.API_URL ?? "http://localhost:8080";

const nextConfig: NextConfig = {
  output: "standalone",
  // nginx: location /mido/ { proxy_pass http://mido-web:3000/; } 가 /mido 를 strip 하므로 basePath 없음
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: `${apiUrl}/api/:path*`,
      },
      // 로컬에서 /mido/api 호출 시 백엔드로 프록시 (프로덕션은 nginx가 처리)
      {
        source: "/mido/api/:path*",
        destination: `${apiUrl}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;
