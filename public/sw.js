const C='wash-flow-v4';
const BASE=new URL(self.registration.scope).pathname;
const HOME=BASE;
const INDEX=BASE+'index.html';
self.addEventListener('install',e=>{e.waitUntil((async()=>{const c=await caches.open(C);await Promise.allSettled([HOME,BASE+'manifest.webmanifest',BASE+'icon.svg'].map(p=>c.add(p)));try{const r=await fetch(HOME);if(r.ok){const html=await r.text();const assets=[...html.matchAll(/(?:src|href)="([^"]+\.(?:js|css))"/g)].map(m=>m[1]);await Promise.allSettled(assets.map(p=>c.add(new URL(p,self.location.origin).pathname)));}}catch(_){}await self.skipWaiting();})());});
self.addEventListener('activate',e=>{e.waitUntil((async()=>{const keys=await caches.keys();await Promise.all(keys.filter(k=>k.startsWith('wash-flow-')&&k!==C).map(k=>caches.delete(k)));await self.clients.claim();})());});
self.addEventListener('fetch',e=>{const r=e.request;const url=new URL(r.url);if(r.method!=='GET'||url.origin!==self.location.origin||!url.pathname.startsWith(BASE))return;if(r.mode==='navigate'){e.respondWith(fetch(r).catch(async()=>await caches.match(HOME)||await caches.match(INDEX)||Response.error()));return;}e.respondWith(caches.match(r).then(cached=>cached||fetch(r).then(response=>{if(response.ok){const copy=response.clone();caches.open(C).then(c=>c.put(r,copy));}return response;}).catch(()=>caches.match(r))));});
