import createMiddleware from 'next-intl/middleware';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { locales, defaultLocale } from './lib/i18n/config';

const intlMiddleware = createMiddleware({
  locales: locales as any,
  defaultLocale,
  localePrefix: 'as-needed',
});

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Admin guard - 404 for unauthorized admin API routes (allow login & verify)
  const publicAdminRoutes = ['/api/admin/verify', '/api/admin/login'];
  if (pathname.startsWith('/api/admin/') && !publicAdminRoutes.includes(pathname)) {
    const adminEmail = process.env.ADMIN_EMAIL || 'oren.on.oren.25@gmail.com';
    const sessionCookie = request.cookies.get('admin_session')?.value;
    if (!sessionCookie) {
      return new NextResponse(null, { status: 404 });
    }
    try {
      const payload = JSON.parse(Buffer.from(sessionCookie, 'base64').toString());
      if (payload.email !== adminEmail || payload.exp < Date.now()) {
        return new NextResponse(null, { status: 404 });
      }
    } catch {
      return new NextResponse(null, { status: 404 });
    }
  }

  return intlMiddleware(request);
}

export const config = {
  matcher: ['/((?!_next|_vercel|.*\\..*).*)'],
};
