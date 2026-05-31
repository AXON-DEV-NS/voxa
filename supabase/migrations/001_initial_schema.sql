-- ============================================================
-- VOXA v2.0 - Supabase Initial Schema Migration
-- ============================================================

-- 1. ENUM TYPES
CREATE TYPE user_plan AS ENUM ('free', 'starter', 'pro', 'agency');
CREATE TYPE video_status AS ENUM ('pending', 'processing', 'ready', 'scheduled', 'published', 'failed');
CREATE TYPE subscription_status AS ENUM ('pending', 'active', 'expired', 'rejected');
CREATE TYPE ad_type AS ENUM ('rewarded', 'interstitial', 'banner');
CREATE TYPE notification_type AS ENUM ('system', 'promo', 'warning', 'admin');

-- 2. PROFILES (syncs with Firebase Auth)
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  locale TEXT DEFAULT 'ar',
  plan user_plan DEFAULT 'free',
  is_banned BOOLEAN DEFAULT FALSE,
  ban_reason TEXT,
  banned_until TIMESTAMPTZ,
  daily_ad_views INTEGER DEFAULT 0,
  last_ad_view_date DATE,
  daily_video_generations INTEGER DEFAULT 0,
  last_generation_date DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own profile" ON profiles FOR SELECT USING (auth.uid() = firebase_uid);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = firebase_uid);
CREATE POLICY "Admin can read all profiles" ON profiles FOR SELECT USING (auth.email() = 'oren.on.oren.25@gmail.com');
CREATE POLICY "Admin can update all profiles" ON profiles FOR UPDATE USING (auth.email() = 'oren.on.oren.25@gmail.com');

-- 3. CONTENT CATEGORIES
CREATE TABLE content_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_translations JSONB DEFAULT '{}',
  icon TEXT,
  color TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE content_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read categories" ON content_categories FOR SELECT USING (TRUE);
CREATE POLICY "Admin can manage categories" ON content_categories FOR ALL USING (auth.email() = 'oren.on.oren.25@gmail.com');

-- 4. VIDEOS
CREATE TABLE videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  hashtags TEXT[] DEFAULT '{}',
  keywords TEXT[] DEFAULT '{}',
  content_category UUID REFERENCES content_categories(id),
  duration_type TEXT DEFAULT 'short',
  duration_seconds INTEGER DEFAULT 30,
  language TEXT DEFAULT 'ar',
  script JSONB DEFAULT '{}',
  audio_url TEXT,
  video_url TEXT,
  thumbnail_url TEXT,
  status video_status DEFAULT 'pending',
  scheduled_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  youtube_video_id TEXT,
  youtube_url TEXT,
  error_message TEXT DEFAULT '',
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own videos" ON videos FOR SELECT USING (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Users can insert own videos" ON videos FOR INSERT WITH CHECK (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Users can update own videos" ON videos FOR UPDATE USING (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Users can delete own videos" ON videos FOR DELETE USING (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Admin can read all videos" ON videos FOR SELECT USING (auth.email() = 'oren.on.oren.25@gmail.com');
CREATE POLICY "Admin can manage all videos" ON videos FOR ALL USING (auth.email() = 'oren.on.oren.25@gmail.com');

-- 5. CONNECTED ACCOUNTS (YouTube, etc.)
CREATE TABLE connected_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  platform_user_id TEXT,
  display_name TEXT,
  avatar_url TEXT,
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, platform)
);

ALTER TABLE connected_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own accounts" ON connected_accounts FOR SELECT USING (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Users can manage own accounts" ON connected_accounts FOR ALL USING (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Admin can read all accounts" ON connected_accounts FOR SELECT USING (auth.email() = 'oren.on.oren.25@gmail.com');

-- 6. SUBSCRIPTIONS
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_name TEXT,
  plan user_plan NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT DEFAULT 'vodafone_cash',
  payment_ref TEXT,
  receipt_image_url TEXT,
  status subscription_status DEFAULT 'pending',
  starts_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  reviewed_by TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own subscriptions" ON subscriptions FOR SELECT USING (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Users can insert own subscriptions" ON subscriptions FOR INSERT WITH CHECK (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Admin can read all subscriptions" ON subscriptions FOR SELECT USING (auth.email() = 'oren.on.oren.25@gmail.com');
CREATE POLICY "Admin can manage subscriptions" ON subscriptions FOR ALL USING (auth.email() = 'oren.on.oren.25@gmail.com');

-- 7. OFFERS
CREATE TABLE offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  discount_percent INTEGER DEFAULT 0,
  target_plan TEXT DEFAULT 'all',
  max_uses INTEGER DEFAULT 100,
  current_uses INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  rejected_by UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE offers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read offers" ON offers FOR SELECT USING (TRUE);
CREATE POLICY "Admin can manage offers" ON offers FOR ALL USING (auth.email() = 'oren.on.oren.25@gmail.com');

-- 8. NOTIFICATIONS
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type DEFAULT 'system',
  title TEXT NOT NULL,
  body TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own notifications" ON notifications FOR SELECT USING (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Admin can create notifications" ON notifications FOR INSERT WITH CHECK (auth.email() = 'oren.on.oren.25@gmail.com');

-- 9. ARTICLES (Blog)
CREATE TABLE articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  content TEXT,
  image_url TEXT,
  category TEXT DEFAULT 'general',
  seo_title TEXT,
  seo_description TEXT,
  published BOOLEAN DEFAULT FALSE,
  author_name TEXT DEFAULT 'VOXA',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read published articles" ON articles FOR SELECT USING (published = TRUE);
CREATE POLICY "Admin can manage articles" ON articles FOR ALL USING (auth.email() = 'oren.on.oren.25@gmail.com');

-- 10. SYSTEM SETTINGS
CREATE TABLE system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read settings" ON system_settings FOR SELECT USING (TRUE);
CREATE POLICY "Admin can update settings" ON system_settings FOR ALL USING (auth.email() = 'oren.on.oren.25@gmail.com');

-- Insert default settings
INSERT INTO system_settings (key, value) VALUES
  ('starter_price', '49'),
  ('pro_price', '99'),
  ('agency_price', '249'),
  ('daily_ad_views_required', '5'),
  ('vodafone_cash_number', '01000000000'),
  ('maintenance_mode', 'false'),
  ('max_video_duration_short', '60'),
  ('max_video_duration_long', '900'),
  ('daily_generation_limit_free', '2'),
  ('daily_generation_limit_starter', '10'),
  ('daily_generation_limit_pro', '50'),
  ('daily_generation_limit_agency', '999');

-- 11. AD_VIEWS (for daily mission tracking)
CREATE TABLE ad_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  ad_type ad_type DEFAULT 'rewarded',
  viewed_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE ad_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own ad views" ON ad_views FOR SELECT USING (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));
CREATE POLICY "Users can insert own ad views" ON ad_views FOR INSERT WITH CHECK (user_id IN (SELECT id FROM profiles WHERE firebase_uid = auth.uid()));

-- 12. INDEXES
CREATE INDEX idx_videos_user_id ON videos(user_id);
CREATE INDEX idx_videos_status ON videos(status);
CREATE INDEX idx_videos_scheduled_at ON videos(scheduled_at);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_ad_views_user_id ON ad_views(user_id);
CREATE INDEX idx_ad_views_viewed_at ON ad_views(viewed_at);
CREATE INDEX idx_profiles_firebase_uid ON profiles(firebase_uid);
CREATE INDEX idx_articles_slug ON articles(slug);
CREATE INDEX idx_articles_published ON articles(published);

-- 13. FUNCTIONS & TRIGGERS
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_videos_updated_at BEFORE UPDATE ON videos FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_connected_accounts_updated_at BEFORE UPDATE ON connected_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_articles_updated_at BEFORE UPDATE ON articles FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 14. STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public) VALUES
  ('videos', 'videos', FALSE),
  ('thumbnails', 'thumbnails', TRUE),
  ('receipts', 'receipts', FALSE),
  ('avatars', 'avatars', TRUE);

-- Storage policies
CREATE POLICY "Users can read own videos" ON storage.objects FOR SELECT USING (bucket_id = 'videos' AND auth.uid() = (SELECT firebase_uid FROM profiles WHERE id = (storage.foldername(name))::UUID));
CREATE POLICY "Users can upload videos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'videos' AND auth.uid() IS NOT NULL);
CREATE POLICY "Anyone can read thumbnails" ON storage.objects FOR SELECT USING (bucket_id = 'thumbnails');
CREATE POLICY "Users can upload thumbnails" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'thumbnails' AND auth.uid() IS NOT NULL);
CREATE POLICY "Admin can read receipts" ON storage.objects FOR SELECT USING (bucket_id = 'receipts' AND auth.email() = 'oren.on.oren.25@gmail.com');
CREATE POLICY "Users can upload receipts" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'receipts' AND auth.uid() IS NOT NULL);
CREATE POLICY "Anyone can read avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid() IS NOT NULL);
