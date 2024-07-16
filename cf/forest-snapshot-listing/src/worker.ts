const BASE_URL = 'https://forest-internal.chainsafe.dev';

interface Env {
  FOREST_ARCHIVE: R2Bucket;
}

async function do_listing(env: Env, prefix) {
  const options = {
    limit: 500,
    prefix: prefix,
  };

  const listed = await env.FOREST_ARCHIVE.list(options);
  let truncated = listed.truncated;
  let cursor = listed.truncated ? listed.cursor : undefined;

  // use the truncated property to check if there are more
  // objects to be returned
  while (truncated) {
    const next = await env.FOREST_ARCHIVE.list({
      ...options,
      cursor: cursor,
    });
    listed.objects.push(...next.objects);

    truncated = next.truncated;
    cursor = next.truncated ? next.cursor : undefined;
  }

  let html = `<!DOCTYPE html>
		<body>
		  <h1>Forest Archive</h1>
      <ul>`;
  for (const obj of listed.objects) {
    html += `<li><a href="${BASE_URL}/${obj.key}">${obj.key}</a></li>\n`;
  }
  html += `</ul></body>`;

  return new Response(html, {
    headers: {
      'content-type': 'text/html;charset=UTF-8',
    },
  });
}

export default {
  async fetch(request: Request, env: Env) {
    switch (request.method) {
      case 'GET': {
        const url = new URL(request.url);
        const { pathname } = url;

        switch (pathname) {
          case '/list':
          case '/list/': {
            const html = `<!DOCTYPE html>
		      <body>
		      <h1>Forest Archive</h1>
          <ul>
          <li><a href="/list/calibnet/diff">Calibnet Diffs</a></li>
          <li><a href="/list/calibnet/lite">Calibnet Lite</a></li>
          <li><a href="/list/mainnet/diff">Mainnet Diffs</a></li>
          <li><a href="/list/mainnet/lite">Mainnet Lite</a></li>
          </ul>
          </body>`;
            return new Response(html, {
              headers: {
                'content-type': 'text/html;charset=UTF-8',
              },
            });
          }
          case '/list/mainnet/diff':
            return do_listing(env, 'mainnet/diff');
          case '/list/calibnet/diff':
            return do_listing(env, 'calibnet/diff');
          case '/list/mainnet/lite':
            return do_listing(env, 'mainnet/lite');
          case '/list/calibnet/lite':
            return do_listing(env, 'calibnet/lite');
          default:
            return new Response(`url: ${pathname}`);
        }
      }
      default: {
        return new Response('Method not allowed', {
          status: 405,
          headers: {
            Allow: 'GET',
          },
        });
      }
    }
  },
};
