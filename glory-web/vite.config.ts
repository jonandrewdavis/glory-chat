import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { cloudflare } from "@cloudflare/vite-plugin";
import { viteStaticCopy } from "vite-plugin-static-copy";
import path from "path";
export default defineConfig({
  plugins: [
    react(),
    cloudflare(),
    viteStaticCopy({
      targets: [
        {
          src: path.resolve(__dirname, "./game"),
          dest: "./game", // 2️⃣
        },
      ],
    }),
  ],
});
