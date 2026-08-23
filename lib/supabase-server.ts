import { createClient } from '@supabase/supabase-js';

type RpcParams = Record<string, unknown>;

function getBearerToken(request: Request) {
  const authorization = request.headers.get('authorization');
  if (!authorization?.startsWith('Bearer ')) return null;
  return authorization.slice(7).trim() || null;
}

export async function callRpc(
  request: Request,
  functionName: string,
  params: RpcParams = {},
) {
  const accessToken = getBearerToken(request);
  if (!accessToken) {
    return Response.json({ error: 'Authentication required' }, { status: 401 });
  }

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !publishableKey) {
    return Response.json(
      { error: 'server is missing its supabase environment variables' },
      { status: 503 },
    );
  }

  const supabase = createClient(url, publishableKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  });
  const { data, error } = await supabase.rpc(functionName, params);

  if (error) {
    const unauthenticated = /jwt|auth|permission/i.test(error.message);
    return Response.json(
      { error: unauthenticated ? 'Your session expired. Please sign in again.' : error.message },
      { status: unauthenticated ? 401 : 500 },
    );
  }

  const payload = (data ?? {}) as Record<string, unknown>;
  const status = typeof payload.status === 'number' ? payload.status : 200;
  if ('status' in payload) delete payload.status;
  return Response.json(payload, { status });
}
