import { callRpc } from '@/lib/supabase-server';

export async function POST(request: Request) {
  const body = await request.json() as { item?: string };
  return callRpc(request, 'smiogl_shop', { p_item: body.item ?? '' });
}

