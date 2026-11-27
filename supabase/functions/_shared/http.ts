// HTTP helpers shared by the Edge Functions.

// Browsers (Flutter web) require CORS headers; mobile apps ignore them.
export const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

/** An error whose message is safe to show to the app user. */
export class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

export function errorResponse(error: unknown): Response {
  if (error instanceof HttpError) return json({ error: error.message }, error.status);
  console.error('Unhandled error:', error);
  return json({ error: 'Something went wrong. Please try again.' }, 500);
}

/** Answers CORS preflight requests; returns null for every other request. */
export function handlePreflight(req: Request): Response | null {
  return req.method === 'OPTIONS'
    ? new Response('ok', { headers: CORS_HEADERS })
    : null;
}
