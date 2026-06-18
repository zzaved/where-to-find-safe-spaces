// Safe-space classification rules.
// Combines (1) keyword scanning over Google reviews with (2) an optional
// Perplexity web-reputation verdict into a single 0-100 safety score + label.

export type SafetyLabel = "safe" | "neutral" | "not_safe";

// Keywords are stored already normalized (lowercase, no accents) so that the
// scanner can match them against normalized review text.
const NEGATIVE_KEYWORDS = [
  // pt-BR
  "homofobia", "homofobico", "homofobica", "lgbtfobia", "lgbtofobia",
  "transfobia", "transfobico", "bifobia", "preconceito", "preconceituoso",
  "discriminacao", "discriminou", "discriminado", "constrangeu",
  "constrangimento", "expulsou", "expulsa", "humilhou", "humilhacao",
  "desrespeito", "desrespeitou", "intolerancia", "intolerante", "racismo",
  "racista", "assedio", "recusou atender", "nao fomos bem atendidos",
  "olhares tortos", "nao somos bem-vindos", "nao e bem-vindo",
  // en
  "homophobia", "homophobic", "transphobia", "transphobic", "biphobia",
  "discrimination", "discriminated", "refused service", "kicked out",
  "harassment", "harassed", "bigot", "bigotry", "not welcome", "hateful",
  "slur", "offensive",
];

const POSITIVE_KEYWORDS = [
  // pt-BR
  "acolhedor", "acolhimento", "amigavel", "inclusivo", "inclusiva",
  "inclusao", "diversidade", "respeito", "respeitoso", "ambiente seguro",
  "lgbt", "lgbtqia", "lgbtq", "orgulho", "parada do orgulho", "bandeira lgbt",
  "arco-iris", "arco iris", "arcoiris", "drag", "comunidade lgbt",
  "sem preconceito", "todos sao bem-vindos", "casal gay", "tolerante",
  "empatia", "seguro para",
  // en
  "welcoming", "inclusive", "inclusion", "diversity", "safe space",
  "pride", "rainbow flag", "queer friendly", "gay friendly", "ally",
  "allies", "accepting", "respectful", "everyone welcome", "no judgment",
];

export interface KeywordSignals {
  positive: string[];
  negative: string[];
}

export interface Citation {
  title: string;
  url: string;
}

export interface WebVerdict {
  verdict: SafetyLabel;
  confidence: number; // 0..1
  summary: string;
  positiveSignals: string[];
  negativeSignals: string[];
  citations: Citation[];
}

export interface Classification {
  score: number;
  label: SafetyLabel;
  summary: string;
  positiveSignals: string[];
  negativeSignals: string[];
  citations: Citation[];
}

function normalize(value: string): string {
  return value
    .toLowerCase()
    .normalize("NFD")
    .replace(new RegExp("[\\u0300-\\u036f]", "g"), "");
}

export function scanKeywords(texts: string[]): KeywordSignals {
  const blob = normalize(texts.join("  \n  "));
  return {
    positive: POSITIVE_KEYWORDS.filter((k) => blob.includes(k)),
    negative: NEGATIVE_KEYWORDS.filter((k) => blob.includes(k)),
  };
}

const SAFE_THRESHOLD = 65;
const UNSAFE_THRESHOLD = 40;

export function classify(
  rating: number | null,
  keywords: KeywordSignals,
  verdict: WebVerdict | null,
): Classification {
  let score = 50;
  score += Math.min(keywords.positive.length, 4) * 7; // up to +28
  score -= Math.min(keywords.negative.length, 4) * 12; // up to -48

  if (rating != null) {
    if (rating >= 4.3) score += 5;
    else if (rating > 0 && rating < 3) score -= 5;
  }

  if (verdict) {
    if (verdict.verdict === "safe") score += Math.round(20 * verdict.confidence);
    else if (verdict.verdict === "not_safe") {
      score -= Math.round(35 * verdict.confidence);
    }
  }

  score = Math.max(0, Math.min(100, score));
  const label: SafetyLabel = score >= SAFE_THRESHOLD
    ? "safe"
    : score <= UNSAFE_THRESHOLD
    ? "not_safe"
    : "neutral";

  const positiveSignals = unique([
    ...(verdict?.positiveSignals ?? []),
    ...keywords.positive,
  ]);
  const negativeSignals = unique([
    ...(verdict?.negativeSignals ?? []),
    ...keywords.negative,
  ]);

  return {
    score,
    label,
    summary: verdict?.summary ?? localSummary(label, keywords),
    positiveSignals,
    negativeSignals,
    citations: verdict?.citations ?? [],
  };
}

function unique(items: string[]): string[] {
  return Array.from(new Set(items.filter((i) => i && i.trim().length > 0)));
}

function localSummary(label: SafetyLabel, keywords: KeywordSignals): string {
  if (label === "not_safe") {
    return "Sinais negativos encontrados nas avaliações deste local. " +
      "Avalie com cautela antes de visitar.";
  }
  if (label === "safe") {
    return "As avaliações trazem sinais positivos de acolhimento e respeito " +
      "à comunidade LGBTQIA+.";
  }
  if (keywords.positive.length || keywords.negative.length) {
    return "Sinais mistos nas avaliações. Recomendamos uma verificação " +
      "aprofundada antes de visitar.";
  }
  return "Ainda não há sinais claros sobre este local. " +
    "Abra os detalhes para uma verificação aprofundada na web.";
}
