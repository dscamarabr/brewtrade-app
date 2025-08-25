// functions/limpar_tokens_inativos/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (_req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")! // 🔑 precisa da chave service_role
  );

  const { error, count } = await supabase
    .from("tb_push_tokens")
    .delete({ count: "exact" }) // count retorna o total de linhas afetadas
    .eq("ativo", false)
    .lt("criado_em", new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()); // opcional: só com mais de 7 dias

  if (error) {
    console.error("Erro ao limpar tokens:", error);
    return new Response(JSON.stringify({ success: false, error }), { status: 500 });
  }

  return new Response(JSON.stringify({ success: true, removidos: count }), { status: 200 });
});
