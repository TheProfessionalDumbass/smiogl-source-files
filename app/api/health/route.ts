export async function GET() {
  return Response.json({ ok: true, service: 'smiogl', monitoringPolicy: 'browser-signals-only' });
}
