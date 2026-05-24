export default {
  async fetch(request) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Authorization, Content-Type, Notion-Version',
        },
      });
    }

    const url = new URL(request.url);
    const notionUrl = 'https://api.notion.com' + url.pathname + url.search;

    const notionResponse = await fetch(notionUrl, {
      method: request.method,
      headers: {
        'Authorization': request.headers.get('Authorization') ?? '',
        'Notion-Version': request.headers.get('Notion-Version') ?? '2022-06-28',
        'Content-Type': 'application/json',
      },
      body: request.method !== 'GET' ? request.body : undefined,
    });

    const body = await notionResponse.text();

    return new Response(body, {
      status: notionResponse.status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  },
};
