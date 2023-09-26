import parseRange from 'range-parser';

interface Env {
	FOREST_ARCHIVE: R2Bucket;
}

function basename(path: string) {
	return path.split('/').reverse()[0];
}

// Directly fetch the data for the latest snapshot of a given chain (eg. calibnet or mainnet)
async function get_latest(req_headers: Headers, env: Env, chain: string): Promise<Response> {
	const listed = await env.FOREST_ARCHIVE.list({ prefix: chain + '/latest/' });
	const latest = listed.objects.at(-1);
	if (latest == null) {
		return new Response(`No latest snapshot found ${chain}`, {
			status: 404,
		});
	} else {
		const object = await env.FOREST_ARCHIVE.get(latest.key, {
			range: req_headers,
			onlyIf: req_headers,
		});

		if (object === null) {
			return new Response('No latest snapshot found', {
				status: 404,
			});
		}

		const headers = new Headers();

		// If the client requested a range, then we need to set the Content-Range header.
		// The `parseRange` returns an error code if the range is not satisfiable (or not specified),
		// so we can handle the range request only if it returns an array.
		let status = 200;
		const range = parseRange(object.size, req_headers.get('range') || '');
		if (Array.isArray(range)) {
			// R2Object doesn't support multiple ranges, so we only use the first one.
			// Throw an error if there are more than one range.
			if (range.length > 1) {
				return new Response('Multiple ranges are not supported', {
					status: 416, // Range Not Satisfiable
				});
			}

			const r = range[0];
			headers.set('Content-Range', `${r.type} ${r.start}-${r.end}/${object.size}`);
			status = 206; // Partial Content
		}

		object.writeHttpMetadata(headers);
		headers.set('etag', object.httpEtag);
		const encoded_name = encodeURIComponent(basename(object.key));
		// Tell browsers and aria2c which filename to use. For 'wget', you have to use `--trust-server-names`.
		headers.set(
			'Content-Disposition',
			`attachment; filename*=UTF-8''${encoded_name}; filename="${encoded_name}"`
		);

		if ('body' in object) {
			return new Response(object.body, {
				headers,
				status,
			});
		} else {
			return new Response(null, {
				headers,
				status,
			});
		}
	}
}

export default {
	async fetch(request: Request, env: Env): Promise<Response> {
		const url = new URL(request.url);
		const chain = (url.pathname.match(/\/latest\/(\w*)/) || ['undefined'])[1];

		// Disallow any other request method except GET, they are not sensible in the context
		// of fetching a snapshot.
		if (request.method !== 'GET') {
			return new Response('Method not allowed', {
				status: 405,
				headers: {
					Allow: 'GET',
				},
			});
		}
		return await get_latest(request.headers, env, chain);
	},
};
