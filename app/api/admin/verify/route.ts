import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';

export async function POST(request: Request) {
  try {
    const { email, password, checkSession } = await request.json();
    const adminEmail = process.env.ADMIN_EMAIL;
    const adminPassword = process.env.ADMIN_PASSWORD;

    // Session check mode (no credentials required, checks existing cookie)
    if (checkSession) {
      const cookieStore = await cookies();
      const session = cookieStore.get('admin_session')?.value;
      if (!session) return new NextResponse(null, { status: 404 });
      const payload = JSON.parse(Buffer.from(session, 'base64').toString());
      if (payload.email === adminEmail && payload.exp > Date.now()) {
        return NextResponse.json({ success: true });
      }
      return new NextResponse(null, { status: 404 });
    }

    // Login mode
    if (!adminEmail || !adminPassword || email !== adminEmail || password !== adminPassword) {
      return new NextResponse(null, { status: 404 });
    }

    const sessionToken = Buffer.from(JSON.stringify({ email: adminEmail, exp: Date.now() + 24 * 60 * 60 * 1000 })).toString('base64');
    const response = NextResponse.json({ success: true, sessionToken });
    response.cookies.set('admin_session', sessionToken, {
      httpOnly: true, secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax', maxAge: 86400, path: '/',
    });
    return response;
  } catch {
    return new NextResponse(null, { status: 404 });
  }
}
