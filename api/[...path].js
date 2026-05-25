const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Notion-Version',
};

module.exports = async function handler(req, res) {
  Object.entries(CORS).forEach(([k, v]) => res.setHeader(k, v));
  if (req.method === 'OPTIONS') return res.status(200).end();

  const token = process.env.NOTION_TOKEN || (req.headers.authorization || '').replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Token manquant' });

  const segments = Array.isArray(req.query.path) ? req.query.path : [req.query.path].filter(Boolean);
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
  return res.status(notionRes.status).json(data);
};
