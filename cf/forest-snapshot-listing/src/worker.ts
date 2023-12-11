/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run "npm run dev" in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run "npm run deploy" to publish your worker
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

const BASE_URL = "https://forest-archive.chainsafe.dev";

async function do_listing(env, prefix) {
  const options = {
    limit: 500,
    prefix: prefix,
  };

  const listed = await env.FOREST_ARCHIVE.list(options);
  let truncated = listed.truncated;
  let cursor = truncated ? listed.cursor : undefined;

  // use the truncated property to check if there are more
  // objects to be returned
  while (truncated) {
    const next = await env.FOREST_ARCHIVE.list({
      ...options,
      cursor: cursor,
    });
    listed.objects.push(...next.objects);

    truncated = next.truncated;
    cursor = next.cursor
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
      "content-type": "text/html;charset=UTF-8",
    },
  });
}

export default {
  async fetch(request, env) {

    const url = new URL(request.url);
    const { pathname } = url;

    switch (pathname) {
      case '/list/': {
        const html = `<!DOCTYPE html>
		      <body>
		      <h1>Forest Archive</h1>
          <ul>
          <li><a href="/list/calibnet/diff">Calibnet Diffs</a></li>
          <li><a href="/list/calibnet/lite">Calibnet Lite</a></li>
          <li><a href="/list/calibnet/lite">Calibnet Latest</a></li>
          <li><a href="/list/mainnet/diff">Mainnet Diffs</a></li>
          <li><a href="/list/mainnet/lite">Mainnet Lite</a></li>
          <li><a href="/list/mainnet/lite">Mainnet Latest</a></li>
          </ul>
          </body>`;
        return new Response(html, {
          headers: {
            "content-type": "text/html;charset=UTF-8",
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
      case '/list/mainnet/latest':
        return do_listing(env, 'mainnet/latest');
      case '/list/calibnet/latest':
        return do_listing(env, 'calibnet/latest');
      default:
        return new Response(`url: ${pathname}`);
    }
  },
};
