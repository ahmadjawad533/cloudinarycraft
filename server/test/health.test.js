const test = require('node:test');
const assert = require('node:assert');
const http = require('node:http');
const app = require('../server');

test('Health check endpoint /healthz returns 200 and status ok', async (t) => {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;

  try {
    const res = await fetch(`http://127.0.0.1:${port}/healthz`);
    assert.strictEqual(res.status, 200);

    const body = await res.json();
    assert.strictEqual(body.status, 'ok');
    assert.strictEqual(body.service, 'cloudicraft-backend');
    assert.ok(typeof body.uptime === 'number');
    assert.ok(body.timestamp);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test('Prometheus metrics endpoint /metrics returns valid text format', async (t) => {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;

  try {
    const res = await fetch(`http://127.0.0.1:${port}/metrics`);
    assert.strictEqual(res.status, 200);

    const text = await res.text();
    assert.ok(text.includes('cloudicraft_http_request_duration_seconds'));
    assert.ok(text.includes('cloudicraft_process_cpu_user_seconds_total'));
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});
