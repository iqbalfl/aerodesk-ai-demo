import express from 'express';

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '64kb' }));
app.use(express.static('public'));

const decisions = [
  { id: 'ADR-007', title: 'Database Technology Decision', status: 'Accepted (planned)', decision: 'PostgreSQL for future transactional reporting', reason: 'Relational integrity and reporting joins', tradeoff: 'Requires schema migrations and operations' },
  { id: 'ADR-011', title: 'Issue Tracking Tool', status: 'Accepted', decision: 'GitHub Issues', reason: 'Code-adjacent workflow with no extra server', tradeoff: 'Lighter planning features than enterprise trackers' }
];
const mockIssues = [
  { id: 'BUG-012', title: 'Customer list ignores requested page limit', status: 'Open', priority: 'Medium' },
  { id: 'TASK-021', title: 'Define customer API pagination contract', status: 'In progress', priority: 'Low' }
];
const customers = Array.from({ length: 36 }, (_, i) => ({ id: i + 1, name: `Demo Customer ${i + 1}`, tier: i % 3 === 0 ? 'Business' : 'Standard' }));

app.get('/health', (req, res) => res.json({ status: 'ok', service: 'aerodesk-demo-api', version: '1.1.0', revision: process.env.APP_REVISION || 'local', database: 'in-memory mock' }));
app.get('/api/decisions', (req, res) => res.json({ data: decisions }));
app.get('/api/issues', (req, res) => res.json({ data: mockIssues, note: 'Fictional backlog fixtures, not live GitHub Issues' }));
app.get('/api/customers', (req, res) => {
  const page = Math.max(1, parseInt(String(req.query.page ?? '1'), 10) || 1);
  const requestedLimit = Math.max(1, Math.min(100, parseInt(String(req.query.limit ?? '10'), 10) || 10));
  const effectiveLimit = requestedLimit;
  const data = customers.slice((page - 1) * effectiveLimit, page * effectiveLimit);
  res.json({ data, meta: { page, limit: effectiveLimit, total: customers.length } });
});

app.use((req, res) => res.status(404).json({ error: 'Not found' }));
const port = Number(process.env.PORT || 3000);
if (process.env.NODE_ENV !== 'test') {
  app.listen(port, '0.0.0.0', () => console.log(`AeroDesk demo listening on ${port}`));
}

export default app;
