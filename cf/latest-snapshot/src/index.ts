import parseRange from 'range-parser';
import { R2ObjectBody } from '@cloudflare/workers-types';

interface Env {
	FOREST_ARCHIVE: R2Bucket;
}

function basename(path: string) {
	return path.split('/').reverse()[0];
}

enum SnapshotType {
	latest = 'latest',
	archive = 'archive',
}

// Directly fetch the data for the latest snapshot of a given chain (eg. calibnet or mainnet)
async function get_latest(
	req_headers: Headers,
	env: Env,
	path: string,
	type: SnapshotType
): Promise<Response> {
	let object: R2ObjectBody | R2Object | null = null;

	switch (type) {
		case SnapshotType.latest: {
			const listed = await env.FOREST_ARCHIVE.list({ prefix: path + '/latest/' });
			const latest = listed.objects.at(-1);
			if (latest == undefined) {
				return new Response(`No latest snapshot found ${path}`, {
					status: 404,
				});
			}

			object = await env.FOREST_ARCHIVE.get(latest.key, {
				range: req_headers,
				onlyIf: req_headers,
			});
			if (object === null) {
				return new Response('No latest snapshot found', {
					status: 404,
				});
			}
			break;
		}
		case SnapshotType.archive: {
			object = await env.FOREST_ARCHIVE.get(path, {
				range: req_headers,
				onlyIf: req_headers,
			});
			if (object === null) {
				return new Response(`No archive snapshot found ${path}`, {
					status: 404,
				});
			}
			break;
		}
		default: {
			return new Response('Invalid Snapshot Type. Only archive OR latest is supported', {
				status: 400,
			});
		}
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
		headers.set('Content-Length', `${r.end - r.start + 1}`);
		status = 206; // Partial Content
	} else {
		headers.set('Content-Length', object.size.toString());
	}

	object.writeHttpMetadata(headers);
	headers.set('etag', object.httpEtag);
	headers.set('Accept-Ranges', 'bytes');
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

export default {
	async fetch(request: Request, env: Env): Promise<Response> {
		// Disallow any other request method except HEAD and GET, they are not sensible in the context
		// of fetching a snapshot.
		switch (request.method) {
			case 'HEAD':
			case 'GET': {
				const url = new URL(request.url);
				const path = url.pathname.match(/\/archive\/(\S*)/);
				if (path != null && path.length > 1) {
					return await get_latest(request.headers, env, path[1], SnapshotType.archive);
				}

				const chain = url.pathname.match(/\/latest\/(\w*)/);
				if (chain != null && chain.length > 1) {
					return await get_latest(request.headers, env, chain[1], SnapshotType.latest);
				}

				return new Response('path not found', {
					status: 404,
				});
			}
			default: {
				return new Response('Method not allowed', {
					status: 405,
					headers: {
						Allow: 'GET, HEAD',
					},
				});
			}
		}
	},
};
