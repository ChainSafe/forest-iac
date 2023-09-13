/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run "npm run dev" in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run "npm run deploy" to publish your worker
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

export default {
  async fetch(request, env, ctx) {
    const listing = await env.FOREST_ARCHIVE.list();
    let html = `<!DOCTYPE html>
		<body>
		  <h1>Forest Archive</h1>
      Files: ${listing.objects.length}`;
    html += `</body>`;

    return new Response(html, {
      headers: {
        "content-type": "text/html;charset=UTF-8",
      },
    });
    return new Response('Hello World!');
  },
};