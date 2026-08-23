import { callRpc } from '@/lib/supabase-server';

type Context = { params: Promise<{ id: string }> };

export async function GET(request: Request, context: Context) {
  const { id } = await context.params;
  return callRpc(request, 'smiogl_get_lesson', { p_lesson_id: id });
}

