export interface Env {
  FOREST_ARCHIVE: R2Bucket;
}

// Number of recent snapshots to keep. Roughly 1 new snapshot is uploaded every hour.
const KEEP_COUNT: number = 10;

async function prune(env: Env, chain: string): Promise<string> {
  const listed = await env.FOREST_ARCHIVE.list({ prefix: chain + "/latest/" });
  // objects are listed chronologically. Reverse to keep the newest snapshots.
  listed.objects.reverse();
  for (let i: number = KEEP_COUNT; i < listed.objects.length; i++) {
    await env.FOREST_ARCHIVE.delete(listed.objects[i].key);
  }
  const pruned = Math.max(listed.objects.length - KEEP_COUNT, 0);
  const kept = listed.objects.length - pruned;
  return `Pruned: ${pruned}. Kept: ${kept}`;
}

export default {
  async scheduled(event, env, ctx) {
		await prune(env, 'calibnet');
		await prune(env, 'mainnet');
  },
  async fetch(request: Request, env: Env): Promise<Response> {
    const calibnet = await prune(env, "calibnet");
    const mainnet = await prune(env, "mainnet");
    return new Response(`Calibnet: ${calibnet}\nMainnet: ${mainnet}\n`);
  },
};
