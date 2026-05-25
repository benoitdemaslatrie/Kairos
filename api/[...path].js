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

  // req.query.path is an array like ['blocks', 'abc123', 'children']
  const segments = Array.isArray(req.query.path) ? req.query.path : [req.query.path];
  const notionPath = segments.join('/');
  const notionUrl = `https://api.notion.com/v1/${notionPath}`;

  let bodyText;
  if (['POST', 'PATCH', 'PUT'].includes(req.method)) {
    bodyText = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
  }

  const notionRes = await fetch(notionUrl, {
    method: req.method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Notion-Version': '2022-06-28',
      'Content-Type': 'application/json',
    },
    body: bodyText,
  });

  const data = await notionRes.json();
  res.status(notionRes.status).json(data);
}
