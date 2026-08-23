import { callRpc } from '@/lib/supabase-server';

type Context = { params: Promise<{ code: string }> };

export async function GET(request: Request, context: Context) {
  const { code } = await context.params;
  return callRpc(request, 'smiogl_get_room', { p_code: code.toUpperCase() });
}

export async function POST(request: Request, context: Context) {
  const { code } = await context.params;
  const payload = await request.json() as Record<string, unknown>;
  return callRpc(request, 'smiogl_room_action', {
    p_code: code.toUpperCase(),
    p_payload: payload,
  });
}

