const CACHE = "white-rabbits-v13";
const ASSETS = [
  "/",
  "/index.html",
  "/css/app.css",
  "/js/app.js",
  "/js/bunnies.js",
  "/js/inspire.js",
  "/js/circle.js",
  "/manifest.webmanifest",
  "/assets/icon.svg",
  "/assets/icon-1024.png",
];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))),
    ),
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (request.method !== "GET") return;
  event.respondWith(
    fetch(request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE).then((cache) => cache.put(request, copy));
        return response;
      })
      .catch(() => caches.match(request).then((cached) => cached || caches.match("/index.html"))),
  );
});
