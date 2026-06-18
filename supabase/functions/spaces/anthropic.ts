// Anthropic (Claude) client with the server-side web_search tool.
// Performs a live web-reputation check for a venue and returns a structured
// verdict about how safe/welcoming it is for LGBTQIA+ people.
// Returns null on any failure so callers degrade to keyword-only classification.

import type { Citation, SafetyLabel, WebVerdict } from "./classification.ts";

const API_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-haiku-4-5";

const SYSTEM_PROMPT =
  `Você é um pesquisador especializado em avaliar se um estabelecimento é ` +
  `seguro e acolhedor para pessoas LGBTQIA+. SEMPRE use a ferramenta de busca ` +
  `na web para encontrar informações atuais (notícias, redes sociais, ` +
  `avaliações públicas, reclamações) antes de decidir. Procure por: ` +
  `(1) polêmicas, denúncias ou processos envolvendo homofobia, transfobia, ` +
  `discriminação ou recusa de atendimento; (2) sinais positivos como apoio a ` +
  `campanhas de orgulho, políticas de inclusão e diversidade, ambiente ` +
  `reconhecidamente acolhedor. Seja criterioso: só classifique como "not_safe" ` +
  `se houver evidências concretas. Ao final, SEMPRE chame a ferramenta ` +
  `"submit_verdict" com sua conclusão, escrevendo o resumo em português do Brasil.`;

const WEB_SEARCH_TOOL = {
  type: "web_search_20250305",
  name: "web_search",
  max_uses: 3,
};

const VERDICT_TOOL = {
  name: "submit_verdict",
  description:
    "Registra a avaliação final sobre o quão seguro e acolhedor o local é " +
    "para pessoas LGBTQIA+.",
  input_schema: {
    type: "object",
    properties: {
      verdict: { type: "string", enum: ["safe", "neutral", "not_safe"] },
      confidence: { type: "number", description: "Confiança de 0 a 1" },
      summary: { type: "string", description: "Resumo em português do Brasil" },
      positive_signals: { type: "array", items: { type: "string" } },
      negative_signals: { type: "array", items: { type: "string" } },
    },
    required: [
      "verdict",
      "confidence",
      "summary",
      "positive_signals",
      "negative_signals",
    ],
  },
};

export async function classifyWithClaude(
  apiKey: string,
  name: string,
  address: string | null,
): Promise<WebVerdict | null> {
  const userPrompt = `Estabelecimento: "${name}"` +
    (address ? `, endereço: ${address}.` : ".") +
    ` Pesquise na web e avalie se é um espaço seguro e acolhedor para ` +
    `pessoas LGBTQIA+.`;

  try {
    const res = await fetch(API_URL, {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 1500,
        system: SYSTEM_PROMPT,
        tools: [WEB_SEARCH_TOOL, VERDICT_TOOL],
        messages: [{ role: "user", content: userPrompt }],
      }),
    });

    if (!res.ok) {
      console.error(`Anthropic failed (${res.status}): ${await res.text()}`);
      return null;
    }

    const data = await res.json();
    const blocks: Array<Record<string, any>> = data.content ?? [];
    const verdictBlock = blocks.find(
      (b) => b.type === "tool_use" && b.name === "submit_verdict",
    );
    if (!verdictBlock) {
      console.error("Anthropic response had no submit_verdict tool call");
      return null;
    }

    const input = verdictBlock.input ?? {};
    return {
      verdict: normalizeVerdict(input.verdict),
      confidence: clamp01(input.confidence ?? 0.5),
      summary: (input.summary as string | undefined)?.trim() ||
        "Sem resumo disponível.",
      positiveSignals: input.positive_signals ?? [],
      negativeSignals: input.negative_signals ?? [],
      citations: extractCitations(blocks),
    };
  } catch (err) {
    console.error("Anthropic request error:", err);
    return null;
  }
}

function normalizeVerdict(value: string | undefined): SafetyLabel {
  if (value === "safe" || value === "not_safe") return value;
  return "neutral";
}

function clamp01(value: number): number {
  if (Number.isNaN(value)) return 0.5;
  return Math.max(0, Math.min(1, value));
}

function extractCitations(blocks: Array<Record<string, any>>): Citation[] {
  const out: Citation[] = [];
  for (const block of blocks) {
    if (block.type === "web_search_tool_result" && Array.isArray(block.content)) {
      for (const result of block.content) {
        if (result?.type === "web_search_result" && result.url) {
          out.push({ title: result.title ?? result.url, url: result.url });
        }
      }
    }
  }
  const seen = new Set<string>();
  return out
    .filter((c) => (seen.has(c.url) ? false : seen.add(c.url)))
    .slice(0, 8);
}
