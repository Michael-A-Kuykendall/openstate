#!/usr/bin/env node
// Audit the human-readable site and machine-readable reference using only Node.
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const pages = [
 "index.html", "pricing.html", "structural-tools.html", "license.html",
 "privacy.html", "terms.html", "refund.html", "evidence.html",
 "hosts.html", "technical.html", "docs/index.html"
];
const html = Object.fromEntries(pages.map(p => [p,readFileSync(join(root,p),"utf8")]));
const json = JSON.parse(readFileSync(join(root,"product.json"),"utf8"));
const full = readFileSync(join(root,"llms-full.txt"),"utf8");
const short = readFileSync(join(root,"llms.txt"),"utf8");
const broken = [];
const assert = (ok,msg) => { if(!ok)broken.push(msg); };
assert(json.tools.length === 36,"product.json must list 36 tools");
assert(json.tool_count.structural === 22 && json.tool_count.state === 14,"product.json tool count mismatch");
assert(new Set(json.tools.map(t=>t.name)).size === 36,"duplicate tool names in product.json");
for(const t of json.tools) {
 assert(t.description && t.description.length >= 15,"tool description missing: "+t.name);
 assert(full.includes("### "+t.name),"llms-full.txt missing tool: "+t.name);
}
assert(short.includes("product.json"),"llms.txt missing JSON link");
for(const page of pages) {
 const source = html[page];
 const prefix = page.includes("/") ? "../" : "";
 assert((source.match(/<h1\\b/g)||[]).length===1,page+": expected one h1");
 assert(source.includes('name="viewport"'),page+": no viewport");
 assert(source.includes('class="os-mobile-nav"'),page+": mobile navigation missing");
 assert(source.includes('class="os-skip"'),page+": skip navigation missing");
 assert(source.includes('id="main"'),page+": main landmark missing");
 assert(source.includes('href="'+prefix+'product.json"'),page+": product reference not linked");
 assert(!source.includes("fonts.googleapis.com"),page+": external fonts present");
 assert(!/\\$149|\\$49(?![0-9])/.test(source),page+": older price visible");
 const links = [...source.matchAll(/\\bhref="([^"]+)"/g)].map(m=>m[1]);
 for(const link of links) {
   if(/^(https?:|mailto:|tel:|data:)/.test(link))continue;
   if(link[0]==="#") {
      if(link.length>1)assert(source.includes('id="'+link.slice(1)+'"'),page+": dead anchor "+link);
      continue;
   }
   const [relative,fragment] = link.split("#");
   const parts = page.split("/").slice(0,-1);
   for(const part of relative.split("/")) {
     if(part==="..")parts.pop();
     else if(part!==".")parts.push(part);
   }
   const target = parts.join("/");
   assert(existsSync(join(root,target)),page+": missing local target "+link);
   if(fragment && html[target])assert(html[target].includes('id="'+fragment+'"'),page+": dead target anchor "+link);
 }
}
const pricing=html["pricing.html"];
assert(pricing.includes("$129") && pricing.includes("$10"),"pricing missing current plans");
assert(pricing.includes("0.x"),"pricing must disclose release-series limitation");
const privacy=html["privacy.html"];
assert(!privacy.includes("loads fonts from Google Fonts"),"privacy describes obsolete Google Fonts request");
const css=readFileSync(join(root,"css/style.css"),"utf8");
assert(css.includes("@media(max-width:620px)"),"small-screen responsive rules missing");
if(broken.length){console.error("FAIL site contract ("+broken.length+"):\\n"+broken.map(s=>" - "+s).join("\\n"));process.exit(1);}
console.log("PASS site contract: "+pages.length+" pages, 36 documented tools, link and pricing checks.");
