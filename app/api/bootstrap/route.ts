import { callRpc } from '@/lib/supabase-server';

export async function GET(request: Request) {
  return callRpc(request, 'smiogl_bootstrap');
}

