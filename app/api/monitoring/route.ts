import { callRpc } from '@/lib/supabase-server';

const allowed = new Set(['visibility_hidden', 'focus_lost', 'fullscreen_exit', 'connection_lost']);

export async function POST(request: Request) {
  const body = await request.json() as { attemptId?: string; eventType?: string };
  if (!body.attemptId || !body.eventType || !allowed.has(body.eventType)) {
    return Response.json({ error: 'Invalid monitoring event' }, { status: 400 });
  }
  return callRpc(request, 'smiogl_monitor', {
    p_attempt_id: body.attemptId,
    p_event_type: body.eventType,
  });
}

