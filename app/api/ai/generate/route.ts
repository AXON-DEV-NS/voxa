import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const { topic, category, duration, language, tone, voiceGender } = await request.json();
    if (!topic) {
      return NextResponse.json({ error: 'Missing topic' }, { status: 400 });
    }

    let script;
    const geminiKey = process.env.GEMINI_API_KEY;

    if (geminiKey) {
      try {
        const prompt = `Generate a YouTube video script about "${topic}" in ${language || 'Arabic'}.
Return JSON with: title (string), hook (string), scenes (array of {index, narration, imagePrompt, duration}), hashtags (array).
Category: ${category || 'general'}. Tone: ${tone || 'educational'}. Duration: ${duration || 'short'}.`;

        const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiKey}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: { responseMimeType: 'application/json', temperature: 0.7 },
          }),
        });

        if (res.ok) {
          const data = await res.json();
          const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (text) {
            const parsed = JSON.parse(text.replace(/```json|```/g, '').trim());
            script = parsed;
          }
        }
      } catch (e) {
        // Gemini failed, fall through to default
      }
    }

    if (!script) {
      script = {
        title: `Unlocking: ${topic.substring(0, 60)}`,
        hook: `Have you ever wondered about ${topic}? Today we'll explore the answers.`,
        scenes: [
          { index: 0, narration: `Welcome to today's deep dive into ${topic}.`, imagePrompt: `${topic} introduction concept`, duration: 5 },
          { index: 1, narration: `Let's explore the first key insight about ${topic}.`, imagePrompt: `${topic} key insight visualization`, duration: 7 },
          { index: 2, narration: `Here's another fascinating aspect of ${topic}.`, imagePrompt: `${topic} additional perspective`, duration: 6 },
          { index: 3, narration: `Now let's look at the practical applications of ${topic}.`, imagePrompt: `${topic} real world applications`, duration: 7 },
          { index: 4, narration: `That concludes our exploration of ${topic}. Subscribe for more!`, imagePrompt: `${topic} summary and conclusion`, duration: 5 },
        ],
        hashtags: ['VOXA', 'AIVideo', topic.replace(/\s+/g, '').substring(0, 20)],
      };
    }

    return NextResponse.json({
      success: true,
      script,
      media: {
        audio_url: `/mock/audio-${Date.now()}.mp3`,
        video_url: 'https://assets.mixkit.co/videos/preview/mixkit-forest-stream-with-mossy-rocks-42795-large.mp4',
        thumbnail_url: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600',
      },
      estimated_duration: script.scenes.reduce((acc: number, s: any) => acc + s.duration, 0),
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function GET() {
  return NextResponse.json({
    models: ['gemini-1.5-flash', 'gemini-1.5-pro'],
    voice_models: ['google-tts-wavenet'],
    image_models: ['pollinations-ai', 'unsplash-fallback'],
    max_scenes: 20,
    max_duration: 900,
  });
}
