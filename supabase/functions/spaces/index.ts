// Edge function "spaces" — the application backend.
//
// POST { action: "discover", lat, lng, category?, radius?, deviceId?, forceRefresh? }
//   -> Finds nearby venues via Google Places, classifies each as a safe space
//      (keyword scan + Claude web check for the nearest few), caches the result
//      in Postgres and returns the list ordered by distance.
//
// POST { action: "details", googlePlaceId, forceRefresh? }
//   -> Returns a single venue, running a deep Claude web check on demand.
//
// API keys are read from the service-role-only `app_config` table (or env),
// never from the mobile client.

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "./cors.ts";
import { distanceMeters, RawPlace, searchNearby } from "./google.ts";
import { classify, Classification, scanKeywords } from "./classification.ts";
import { classifyWithClaude } from "./anthropic.ts";

const MAX_RESULTS = 20; // Google Nearby (New) hard cap per request
const DEEP_CHECK_ON_DISCOVER = 8; // web-check the nearest N on first discovery
const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // re-classify after 7 days

const CATEGORY_TYPES: Record<string, string[]> = {
  all: [],
  restaurant: ["restaurant"],
  cafe: ["cafe", "coffee_shop"],
  bar: ["bar"],
  night_club: ["night_club"],
  gym: ["gym", "fitness_center"],
  store: ["store", "shopping_mall"],
  hotel: ["hotel", "lodging"],
};

interface DiscoverRequest {
  action: "discover";
  lat: number;
  lng: number;
  category?: string;
  radius?: number;
  deviceId?: string;
  forceRefresh?: boolean;
}

interface DetailsRequest {
  action: "details";
  googlePlaceId: string;
  forceRefresh?: boolean;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const config = await loadConfig(supabase);
  const googleKey = config.google_maps_api_key;
  const anthropicKey = config.anthropic_api_key;
  if (!googleKey) {
    return jsonResponse({ error: "GOOGLE_MAPS_API_KEY not configured" }, 500);
  }

  let body: DiscoverRequest | DetailsRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  try {
    if (body.action === "discover") {
      const places = await discover(supabase, googleKey, anthropicKey, body);
      return jsonResponse({ places });
    }
    if (body.action === "details") {
      const place = await details(supabase, anthropicKey, body);
      return jsonResponse({ place });
    }
    return jsonResponse({ error: "Unknown action" }, 400);
  } catch (err) {
    console.error("spaces error:", err);
    return jsonResponse({ error: String((err as Error)?.message ?? err) }, 500);
  }
});

type Supa = SupabaseClient;

interface AppConfig {
  google_maps_api_key?: string;
  anthropic_api_key?: string;
}

/// Resolves API keys from env first, falling back to the `app_config` vault.
async function loadConfig(supabase: Supa): Promise<AppConfig> {
  const config: AppConfig = {
    google_maps_api_key: Deno.env.get("GOOGLE_MAPS_API_KEY") ?? undefined,
    anthropic_api_key: Deno.env.get("ANTHROPIC_API_KEY") ?? undefined,
  };
  if (config.google_maps_api_key && config.anthropic_api_key) return config;

  const { data } = await supabase.from("app_config").select("key, value");
  for (const row of data ?? []) {
    if (row.key === "google_maps_api_key") {
      config.google_maps_api_key ??= row.value;
    }
    if (row.key === "anthropic_api_key") {
      config.anthropic_api_key ??= row.value;
    }
  }
  return config;
}

async function discover(
  supabase: Supa,
  googleKey: string,
  anthropicKey: string | undefined,
  req: DiscoverRequest,
): Promise<unknown[]> {
  const radius = clampRadius(req.radius);
  const includedTypes = CATEGORY_TYPES[req.category ?? "all"] ?? [];

  const raw = await searchNearby({
    apiKey: googleKey,
    lat: req.lat,
    lng: req.lng,
    radius,
    includedTypes,
    maxResults: MAX_RESULTS,
  });

  const withDistance = raw
    .map((p) => ({
      place: p,
      distance: distanceMeters(req.lat, req.lng, p.lat, p.lng),
    }))
    .sort((a, b) => a.distance - b.distance);

  const ids = withDistance.map((w) => w.place.googlePlaceId);
  const cached = await loadCached(supabase, ids);

  const now = Date.now();
  let deepBudget = anthropicKey ? DEEP_CHECK_ON_DISCOVER : 0;

  const rows = await Promise.all(
    withDistance.map(async ({ place, distance }) => {
      const existing = cached.get(place.googlePlaceId);
      const fresh = existing &&
        existing.classified_at &&
        now - new Date(existing.classified_at).getTime() < CACHE_TTL_MS &&
        !req.forceRefresh;

      if (fresh) {
        return { ...existing, distance_m: distance };
      }

      const keywords = scanKeywords(place.reviews.map((r) => r.text));
      let verdict = null;
      const shouldDeepCheck = anthropicKey &&
        deepBudget > 0 &&
        (!existing?.deep_checked || req.forceRefresh);
      if (shouldDeepCheck) {
        deepBudget--;
        verdict = await classifyWithClaude(
          anthropicKey!,
          place.name,
          place.address,
        );
      }

      const classification = classify(place.rating, keywords, verdict);
      return await upsertPlace(
        supabase,
        place,
        classification,
        verdict !== null,
        distance,
      );
    }),
  );

  if (req.deviceId) {
    await supabase.from("search_history").insert({
      device_id: req.deviceId,
      lat: req.lat,
      lng: req.lng,
      category: req.category ?? "all",
      result_count: rows.length,
    });
  }

  return rows.sort((a, b) => (a.distance_m ?? 0) - (b.distance_m ?? 0));
}

async function details(
  supabase: Supa,
  anthropicKey: string | undefined,
  req: DetailsRequest,
): Promise<unknown> {
  const { data: existing } = await supabase
    .from("places")
    .select("*")
    .eq("google_place_id", req.googlePlaceId)
    .maybeSingle();

  if (!existing) throw new Error("Place not found in cache");

  const alreadyDeep = existing.deep_checked && !req.forceRefresh;
  if (alreadyDeep || !anthropicKey) {
    return existing;
  }

  const reviewTexts = (existing.reviews ?? []).map(
    (r: { text?: string }) => r.text ?? "",
  );
  const keywords = scanKeywords(reviewTexts);
  const verdict = await classifyWithClaude(
    anthropicKey,
    existing.name,
    existing.address,
  );
  const classification = classify(existing.google_rating, keywords, verdict);

  const { data: updated } = await supabase
    .from("places")
    .update({
      safety_score: classification.score,
      safety_label: classification.label,
      classification_summary: classification.summary,
      positive_signals: classification.positiveSignals,
      negative_signals: classification.negativeSignals,
      web_citations: classification.citations,
      deep_checked: verdict !== null,
      classified_at: new Date().toISOString(),
    })
    .eq("id", existing.id)
    .select("*")
    .single();

  return updated;
}

async function loadCached(
  supabase: Supa,
  ids: string[],
): Promise<Map<string, Record<string, any>>> {
  if (ids.length === 0) return new Map();
  const { data } = await supabase
    .from("places")
    .select("*")
    .in("google_place_id", ids);
  const map = new Map<string, Record<string, any>>();
  for (const row of data ?? []) map.set(row.google_place_id, row);
  return map;
}

async function upsertPlace(
  supabase: Supa,
  place: RawPlace,
  classification: Classification,
  deepChecked: boolean,
  distance: number,
): Promise<Record<string, any>> {
  const payload = {
    google_place_id: place.googlePlaceId,
    name: place.name,
    primary_type: place.primaryType,
    types: place.types,
    address: place.address,
    lat: place.lat,
    lng: place.lng,
    google_rating: place.rating,
    google_ratings_total: place.ratingsTotal,
    price_level: place.priceLevel,
    website: place.website,
    google_maps_uri: place.googleMapsUri,
    phone: place.phone,
    photo_name: place.photoName,
    safety_score: classification.score,
    safety_label: classification.label,
    classification_summary: classification.summary,
    positive_signals: classification.positiveSignals,
    negative_signals: classification.negativeSignals,
    web_citations: classification.citations,
    reviews: place.reviews,
    deep_checked: deepChecked,
    classified_at: new Date().toISOString(),
  };

  const { data, error } = await supabase
    .from("places")
    .upsert(payload, { onConflict: "google_place_id" })
    .select("*")
    .single();

  if (error) throw error;
  return { ...data, distance_m: distance };
}

function clampRadius(radius: number | undefined): number {
  const value = radius ?? 2000;
  return Math.max(200, Math.min(value, 30000));
}
