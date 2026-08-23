import { callRpc } from '@/lib/supabase-server';

type Context = { params: Promise<{ id: string }> };

export async function POST(request: Request, context: Context) {
  const { id } = await context.params;
  return callRpc(request, 'smiogl_review_lesson', { p_lesson_id: id });
}

