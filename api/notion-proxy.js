const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Notion-Version',
};

export default async function handler(req, res) {
  Object.entries(CORS).forEach(([k, v]) => res.setHeader(k, v));
  if (req.method === 'OPTIONS') return res.status(200).end();

  const token = process.env.NOTION_TOKEN || req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Token manquant' });

  // /api/search → https://api.notion.com/v1/search
  const rawPath = req.url.split('/api/')[1] ?? '';
  const [pathPart, queryPart] = rawPath.split('?');
  const notionUrl = `https://api.notion.com/v1/${pathPart}${queryPart ? '?' + queryPart : ''}`;

  const notionRes = await fetch(notionUrl, {
    method: req.method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Notion-Version': '2022-06-28',
      'Content-Type': 'application/json',
    },
    body: ['POST', 'PATCH', 'PUT'].includes(req.method) ? JSON.stringify(req.body) : undefined,
  });

  const data = await notionRes.json();
  res.status(notionRes.status).json(data);
}
