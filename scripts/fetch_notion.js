const fs = require('fs');

const TOKEN = process.env.NOTION_TOKEN;
const VERSION = '2022-06-28';
const BASE = 'https://api.notion.com/v1';

const headers = {
  'Authorization': `Bearer ${TOKEN}`,
  'Notion-Version': VERSION,
  'Content-Type': 'application/json',
};

function save(data) {
  fs.mkdirSync('web', { recursive: true });
  fs.writeFileSync('web/notion_cache.json', JSON.stringify(data));
}

async function main() {
  if (!TOKEN) {
    console.log('NOTION_TOKEN non défini — cache vide généré.');
    save({ pages: [], generated_at: new Date().toISOString() });
    return;
  }

  console.log('Récupération des pages Notion...');

  const searchRes = await fetch(`${BASE}/search`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      filter: { value: 'page', property: 'object' },
      page_size: 30,
      sort: { direction: 'descending', timestamp: 'last_edited_time' },
    }),
  });

  if (!searchRes.ok) {
    console.error(`Erreur ${searchRes.status} lors de la recherche.`);
    save({ pages: [], generated_at: new Date().toISOString() });
    return;
  }

  const pages = (await searchRes.json()).results;
  console.log(`${pages.length} pages trouvées.`);

  const pagesWithBlocks = await Promise.all(pages.map(async (page) => {
    const blocksRes = await fetch(`${BASE}/blocks/${page.id}/children?page_size=20`, { headers });
    const children = blocksRes.ok ? (await blocksRes.json()).results : [];
    return { ...page, children };
  }));

  save({ pages: pagesWithBlocks, generated_at: new Date().toISOString() });
  console.log('Cache Notion sauvegardé dans web/notion_cache.json');
}

main().catch(err => {
  console.error('Erreur :', err);
  save({ pages: [], generated_at: new Date().toISOString() });
});
