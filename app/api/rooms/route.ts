import { callRpc } from '@/lib/supabase-server';

export async function GET(request: Request) {
  return callRpc(request, 'smiogl_list_rooms');
}

export async function POST(request: Request) {
  const payload = await request.json() as Record<string, unknown>;
  return callRpc(request, 'smiogl_create_room', { p_payload: payload });
}

