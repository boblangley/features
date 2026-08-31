const http = require("http");

http
  .createServer((request, response) => {
    const url = new URL(request.url, "http://127.0.0.1:18080");

    if (url.pathname === "/health") {
      response.writeHead(204).end();
      return;
    }

    if (
      url.pathname !== "/api/app/satellite/config" ||
      url.searchParams.get("t") !== "sample-credential"
    ) {
      response.writeHead(403).end();
      return;
    }

    response.writeHead(200, { "Content-Type": "application/json" });
    response.end('{"sample":true}\n');
  })
  .listen(18080, "127.0.0.1");
