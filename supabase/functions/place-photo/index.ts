// Edge function "place-photo" — streams a Google Places photo through the
// backend so the Google API key is never exposed to the mobile client.
// The key is read from env or the service-role-only `app_config` vault.
//
// GET /place-photo?name=<photoResourceName>&w=<maxWidthPx>

import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

async function resolveGoogleKey(): Promise<string | undefined> {
  const fromEnv = Deno.env.get("GOOGLE_MAPS_API_KEY");
  if (fromEnv) return fromEnv;
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data } = await supabase
    .from("app_config")
    .select("value")
    .eq("key", "google_maps_api_key")
    .maybeSingle();
  return data?.value ?? undefined;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const apiKey = await resolveGoogleKey();
  if (!apiKey) {
    return new Response("GOOGLE_MAPS_API_KEY not configured", {
      status: 500,
      headers: corsHeaders,
    });
  }

  const url = new URL(req.url);
  const name = url.searchParams.get("name");
  const width = url.searchParams.get("w") ?? "800";
  if (!name) {
    return new Response("missing 'name'", { status: 400, headers: corsHeaders });
  }

  const googleUrl =
    `https://places.googleapis.com/v1/${name}/media?maxWidthPx=${width}&key=${apiKey}`;

  const upstream = await fetch(googleUrl);
  if (!upstream.ok) {
    return new Response("photo fetch failed", {
      status: upstream.status,
      headers: corsHeaders,
    });
  }

  return new Response(upstream.body, {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": upstream.headers.get("Content-Type") ?? "image/jpeg",
      "Cache-Control": "public, max-age=86400",
    },
  });
});
