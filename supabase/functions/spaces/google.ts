// Thin client over the Google Places API (New).
// Responsible ONLY for talking to Google and mapping the payload into our
// internal RawPlace shape. No business rules live here.

const PLACES_BASE = "https://places.googleapis.com/v1";

export interface RawReview {
  author: string;
  authorUri: string;
  rating: number;
  text: string;
  relativeTime: string;
  publishTime: string;
  sourceUri: string;
}

export interface RawPlace {
  googlePlaceId: string;
  name: string;
  primaryType: string | null;
  types: string[];
  address: string | null;
  lat: number;
  lng: number;
  rating: number | null;
  ratingsTotal: number;
  priceLevel: number | null;
  website: string | null;
  googleMapsUri: string | null;
  phone: string | null;
  photoName: string | null;
  reviews: RawReview[];
}

const FIELD_MASK = [
  "places.id",
  "places.displayName",
  "places.formattedAddress",
  "places.location",
  "places.rating",
  "places.userRatingCount",
  "places.priceLevel",
  "places.types",
  "places.primaryType",
  "places.websiteUri",
  "places.googleMapsUri",
  "places.nationalPhoneNumber",
  "places.reviews",
  "places.photos",
].join(",");

const PRICE_MAP: Record<string, number> = {
  PRICE_LEVEL_FREE: 0,
  PRICE_LEVEL_INEXPENSIVE: 1,
  PRICE_LEVEL_MODERATE: 2,
  PRICE_LEVEL_EXPENSIVE: 3,
  PRICE_LEVEL_VERY_EXPENSIVE: 4,
};

// Google Places "Nearby Search (New)" caps a single call at 20 results.
export const GOOGLE_NEARBY_MAX = 20;

export async function searchNearby(params: {
  apiKey: string;
  lat: number;
  lng: number;
  radius: number;
  includedTypes: string[];
  maxResults: number;
}): Promise<RawPlace[]> {
  const body: Record<string, unknown> = {
    maxResultCount: Math.min(params.maxResults, GOOGLE_NEARBY_MAX),
    rankPreference: "DISTANCE",
    locationRestriction: {
      circle: {
        center: { latitude: params.lat, longitude: params.lng },
        radius: params.radius,
      },
    },
  };
  if (params.includedTypes.length) body.includedTypes = params.includedTypes;

  const res = await fetch(`${PLACES_BASE}/places:searchNearby`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": params.apiKey,
      "X-Goog-FieldMask": FIELD_MASK,
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const detail = await res.text();
    throw new Error(`Google searchNearby failed (${res.status}): ${detail}`);
  }

  const data = await res.json();
  return (data.places ?? []).map(mapPlace);
}

function mapPlace(p: Record<string, any>): RawPlace {
  return {
    googlePlaceId: p.id,
    name: p.displayName?.text ?? "Local sem nome",
    primaryType: p.primaryType ?? null,
    types: p.types ?? [],
    address: p.formattedAddress ?? null,
    lat: p.location?.latitude ?? 0,
    lng: p.location?.longitude ?? 0,
    rating: p.rating ?? null,
    ratingsTotal: p.userRatingCount ?? 0,
    priceLevel: p.priceLevel != null ? PRICE_MAP[p.priceLevel] ?? null : null,
    website: p.websiteUri ?? null,
    googleMapsUri: p.googleMapsUri ?? null,
    phone: p.nationalPhoneNumber ?? null,
    photoName: p.photos?.[0]?.name ?? null,
    reviews: (p.reviews ?? []).map((r: Record<string, any>): RawReview => ({
      author: r.authorAttribution?.displayName ?? "Anônimo",
      authorUri: r.authorAttribution?.uri ?? "",
      rating: r.rating ?? 0,
      text: r.text?.text ?? r.originalText?.text ?? "",
      relativeTime: r.relativePublishTimeDescription ?? "",
      publishTime: r.publishTime ?? "",
      sourceUri: r.googleMapsUri ?? "",
    })),
  };
}

// Distance between two coordinates in meters (haversine).
export function distanceMeters(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}
