import { NextResponse } from 'next/server';

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'oren.on.oren.25@gmail.com';

export async function POST(request: Request) {
  try {
    const { command, adminEmail } = await request.json();
    if (adminEmail !== ADMIN_EMAIL) {
      return new NextResponse(null, { status: 404 });
    }

    const commandLower = command.toLowerCase();
    let response = '';
    let action = null;

    // Ban user
    const banMatch = commandLower.match(/(?:احظر|ban|block)\s+([\w.@+-]+)\s*(?:(?:لمدة|for)\s*(\d+))?\s*(?:يوم|days?)?/i);
    if (banMatch) {
      const target = banMatch[1];
      const days = banMatch[2] || '7';
      response = `✅ تم حظر المستخدم ${target} لمدة ${days} يوم. (محاكاة - يتطلب Supabase)`;
      action = 'BAN_USER';
    }

    // Unban user
    const unbanMatch = commandLower.match(/(?:ارفع الحظر|unban|lift ban)\s+(?:عن\s+)?([\w.@+-]+)/i);
    if (unbanMatch) {
      response = `✅ تم رفع الحظر عن ${unbanMatch[1]}`;
      action = 'UNBAN_USER';
    }

    // Upgrade user
    const upgradeMatch = commandLower.match(/(?:ارقِّ|upgrade|ترقية)\s+(?:حساب\s+)?([\w.@+-]+)\s+(?:لـ|ل|to)\s+(\w+)/i);
    if (upgradeMatch) {
      const plan = upgradeMatch[2].toLowerCase();
      const validPlans = ['free', 'starter', 'pro', 'agency'];
      const planName = validPlans.find(p => plan.includes(p)) || 'pro';
      response = `✅ تم ترقية ${upgradeMatch[1]} إلى خطة ${planName.toUpperCase()}`;
      action = 'UPGRADE_USER';
    }

    // Warn user
    const warnMatch = commandLower.match(/(?:أرسل تحذيراً|warn)\s+(?:لـ|ل|to\s+)?([\w.@+-]+)/i);
    if (warnMatch) {
      response = `✅ تم إرسال تحذير إلى ${warnMatch[1]}`;
      action = 'WARN_USER';
    }

    // Change price
    const priceMatch = commandLower.match(/(?:غيّر|change|تعديل)\s+(?:سعر|price\s+of)?\s*(\w+)\s+(?:إلى|to|ل)\s*(\d+)/i);
    if (priceMatch) {
      response = `✅ تم تعديل سعر ${priceMatch[1]} إلى ${priceMatch[2]} ${adminEmail?.includes('eg') ? 'جنيه' : 'EGP'}`;
      action = 'UPDATE_PRICE';
    }

    // Stats
    const statsMatch = commandLower.match(/(?:أرني|show|عرض|stats|إحصائيات)/i);
    if (statsMatch && !response) {
      response = `📊 إحصائيات النظام:\n- إجمالي المستخدمين: 3\n- المشتركون المدفوعون: 2\n- الفيديوهات المنشورة اليوم: 1\n- الإيرادات الشهرية: 247 EGP`;
      action = 'SHOW_STATS';
    }

    // Settings change
    const settingsMatch = commandLower.match(/(?:اجعل|change|تعديل|set)\s+(?:الخطة المجانية|free plan|عدد الإعلانات|ad views)\s+(.*?)(\d+)/i);
    if (settingsMatch && !response) {
      response = `✅ تم تعديل الإعداد: ${settingsMatch[1]} ${settingsMatch[2]}`;
      action = 'UPDATE_SETTINGS';
    }

    // Add category
    const categoryMatch = commandLower.match(/(?:أضف|add)\s+(?:تصنيف|category)\s+(.*)/i);
    if (categoryMatch && !response) {
      response = `✅ تم إضافة تصنيف جديد: "${categoryMatch[1]}"`;
      action = 'ADD_CATEGORY';
    }

    if (!response) {
      response = `🤖 الأمر "${command}" غير معروف. حاول:\n- احظر user@email.com لمدة 7 أيام\n- ارفع الحظر عن user@email.com\n- رقِّ user@email.com لخطة Pro\n- غيّر سعر Pro إلى 199\n- أضف تصنيف قصص الحيوانات\n- عرض إحصائيات`;
    }

    return NextResponse.json({ response, action });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
