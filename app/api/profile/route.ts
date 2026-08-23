import { callRpc } from '@/lib/supabase-server';

export async function POST(request: Request) {
  const body = await request.json() as { role?: string };
  if (body.role !== 'student' && body.role !== 'teacher') {
    return Response.json({ error: 'Invalid role' }, { status: 400 });
  }
  return callRpc(request, 'smiogl_set_role', { p_role: body.role });
}

