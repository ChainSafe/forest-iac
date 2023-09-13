interface Env {
	FOREST_ARCHIVE: R2Bucket,
}

function basename(path: String) {
	return path.split('/').reverse()[0];
}

async function get_latest(env: Env, chain: string): Promise<Response> {
	const listed = await env.FOREST_ARCHIVE.list({ prefix: chain + "/latest/" });
	let latest = listed.objects.at(-1);
	if (latest == null) {
		return new Response(`No latest snapshot found ${chain}`, {
			status: 404,
		});
	} else {
		// Should we support range queries?
		const object = await env.FOREST_ARCHIVE.get(latest.key);
		if (object === null) {
			return new Response('No latest snapshot found', {
				status: 404,
			});
		}
		const headers = new Headers();
		object.writeHttpMetadata(headers);
		headers.set('etag', object.httpEtag);
		let encoded_name = encodeURIComponent(basename(object.key));
		headers.set('content-disposition', `attachment; filename*=UTF-8''${encoded_name}; filename="${encoded_name}"`);

		return new Response(object.body, {
			headers,
		});
	}
}

export default {
	async fetch(request: Request, env: Env): Promise<Response> {
		const url = new URL(request.url);
		const myRe = /\/latest\/(\w*)/;
		const chain = (url.pathname.match(myRe) || ["undefined"])[1];

		return await get_latest(env, chain);
	},
};
