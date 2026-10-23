import test from 'node:test';
import assert from 'node:assert/strict';
import app from '../server.js';

async function withServer(run) {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  try {
    const port = server.address().port;
    return await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve, reject) => server.close(err => err ? reject(err) : resolve()));
  }
}

test('pagination page 1 respects limit=3', async () => withServer(async origin => {
  const res = await fetch(`${origin}/api/customers?page=1&limit=3`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.meta.limit, 3);
  assert.equal(body.data.length, 3);
  assert.deepEqual(body.data.map(c => c.id), [1, 2, 3]);
  assert.deepEqual(body.meta, { page: 1, limit: 3, total: 36 });
}));

test('pagination page 2 respects limit=3', async () => withServer(async origin => {
  const res = await fetch(`${origin}/api/customers?page=2&limit=3`);
  const body = await res.json();
  assert.equal(body.data.length, 3);
  assert.deepEqual(body.data.map(c => c.id), [4, 5, 6]);
  assert.deepEqual(body.meta, { page: 2, limit: 3, total: 36 });
}));

test('limit=3 defaults to page 1', async () => withServer(async origin => {
  const res = await fetch(`${origin}/api/customers?limit=3`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.deepEqual(body.data.map(c => c.id), [1, 2, 3]);
  assert.deepEqual(body.meta, { page: 1, limit: 3, total: 36 });
}));

for (const [input, limit] of [['1', 1], ['100', 100], ['-5', 1], ['0', 10], ['invalid', 10]]) {
  test(`limit=${input} normalizes to ${limit}`, async () => withServer(async origin => {
    const res = await fetch(`${origin}/api/customers?limit=${input}`);
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.deepEqual(body.meta, { page: 1, limit, total: 36 });
    assert.deepEqual(body.data.map(c => c.id), Array.from({ length: Math.min(limit, 36) }, (_, i) => i + 1));
  }));
}

test('page beyond the last page has empty data and stable metadata', async () => withServer(async origin => {
  const res = await fetch(`${origin}/api/customers?page=13&limit=3`);
  const body = await res.json();
  assert.deepEqual(body.data, []);
  assert.deepEqual(body.meta, { page: 13, limit: 3, total: 36 });
}));

test('default limit=10 still returns ten records', async () => withServer(async origin => {
  const res = await fetch(`${origin}/api/customers?page=1`);
  const body = await res.json();
  assert.equal(body.data.length, 10);
  assert.equal(body.meta.limit, 10);
}));

test('limits are clamped to the accepted 1..100 range', async () => withServer(async origin => {
  const res = await fetch(`${origin}/api/customers?page=1&limit=1000`);
  const body = await res.json();
  assert.equal(body.meta.limit, 100);
  assert.equal(body.data.length, 36);
}));

test('reference endpoints remain healthy', async () => withServer(async origin => {
  for (const path of ['/health','/api/decisions','/api/issues']) {
    const response = await fetch(origin + path);
    assert.equal(response.status, 200, path);
  }
}));
