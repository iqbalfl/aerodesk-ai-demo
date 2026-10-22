#!/usr/bin/env bash
set -euo pipefail
BASE="${DEMO_BASE_URL:-http://127.0.0.1:3000}"
BASE="${BASE%/}"
node - "$BASE" <<'NODE'
const base=process.argv[2];
for(const [page,expected] of [[1,[1,2,3]],[2,[4,5,6]]]){
 const res=await fetch(`${base}/api/customers?page=${page}&limit=3`);
 if(!res.ok)throw new Error(`HTTP ${res.status}`);
 const data=await res.json();
 if(data.meta.limit!==3||JSON.stringify(data.data.map(x=>x.id))!==JSON.stringify(expected))
   throw new Error(`Pagination regression on page ${page}: ${JSON.stringify(data)}`);
}
const health=await (await fetch(`${base}/health`)).json();
console.log('PASSED pagination page 1 & 2; revision:',health.revision);
NODE
