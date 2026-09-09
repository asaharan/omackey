import { resolve, sep } from "node:path";
import { stat } from "node:fs/promises";

const root = resolve(import.meta.dir, "../site");
const server = Bun.serve({
  hostname: "127.0.0.1",
  port: Number(process.env.PORT ?? 8000),
  async fetch(request) {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method not allowed", { status: 405, headers: { Allow: "GET, HEAD" } });
    }
    let pathname: string;
    try {
      pathname = decodeURIComponent(new URL(request.url).pathname);
    } catch {
      return new Response("Bad request", { status: 400 });
    }
    const path = resolve(root, `.${pathname.endsWith("/") ? `${pathname}index.html` : pathname}`);
    const exists = path.startsWith(root + sep) && await stat(path).then(info => info.isFile()).catch(() => false);
    const file = Bun.file(exists ? path : resolve(root, "404.html"));
    return new Response(request.method === "HEAD" ? null : file, {
      status: exists ? 200 : 404,
      headers: { "Content-Type": file.type, "Cache-Control": "no-store" },
    });
  },
});
console.log(`Omackey preview: ${server.url}`);
