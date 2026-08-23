import { callRpc } from '@/lib/supabase-server';

export async function POST(request: Request) {
  return callRpc(request, 'smiogl_revive_streak');
}

