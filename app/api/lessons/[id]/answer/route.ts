import { callRpc } from '@/lib/supabase-server';

type Context = { params: Promise<{ id: string }> };

export async function POST(request: Request, context: Context) {
  const { id } = await context.params;
  const body = await request.json() as { answer?: unknown; useSpecialHint?: boolean };
  return callRpc(request, 'smiogl_answer_lesson', {
    p_lesson_id: id,
    p_answer: String(body.answer ?? ''),
    p_use_special_hint: Boolean(body.useSpecialHint),
  });
}

