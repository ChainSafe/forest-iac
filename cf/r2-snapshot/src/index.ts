import parseRange from 'range-parser';

interface Env {
		FOREST_ARCHIVE: R2Bucket;
}

function basename(path: string) {
		return path.split('/').reverse()[0];
}

// Directly fetch the data for the given R2 path
async function get_archive(req_headers: Headers, env: Env, r2_path: string): Promise<Response> {
		console.log("inside of get_archive---"+ r2_path)
		const object = await env.FOREST_ARCHIVE.get(r2_path, {
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
				console.log("request.url: " + request.url);
				const url = new URL(request.url);

				const path = url.pathname.split('/archive').pop() || 'undefined';

				// Disallow any other request method except HEAD and GET, they are not sensible in the context
				// of fetching a snapshot.
				switch (request.method) {
						case 'HEAD':
						case 'GET':
								console.log("inside of get")
								return await get_archive(request.headers, env, path);
						default:
								return new Response('Method not allowed', {
										status: 405,
										headers: {
												Allow: 'GET, HEAD',
										},
								});
				}
		},
};

