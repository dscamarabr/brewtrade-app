import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Supabase client setup
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_ANON_KEY")!
);

serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    const token = authHeader?.replace("Bearer ", "");

    if (!token) {
      return new Response(JSON.stringify({ error: "Token de autenticação ausente" }), { status: 401 });
    }

    const {
      data: { user },
      error: userError
    } = await supabase.auth.getUser(token);

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Usuário não autenticado" }), { status: 401 });
    }

    const { token: pushToken } = await req.json();
    if (!pushToken) {
      return new Response(JSON.stringify({ error: "Token FCM obrigatório" }), { status: 400 });
    }

    const agora = new Date().toISOString();

    // Inativa tokens antigos
    await supabase
      .from("tb_push_tokens")
      .update({ ativo: false })
      .eq("user_id", user.id)
      .lt("criado_em", agora);

    // Upsert do novo token
    const { error } = await supabase
      .from("tb_push_tokens")
      .upsert(
        {
          user_id: user.id,
          token: pushToken,
          ativo: true,
          criado_em: agora
        },
        { onConflict: "token" }
      );

    if (error) {
      console.error("Erro ao salvar token:", error.message);
      return new Response(JSON.stringify({ error: "Erro ao salvar token" }), { status: 500 });
    }

    return new Response(JSON.stringify({ success: true }), { status: 200 });

  } catch (err) {
    console.error("Erro inesperado:", err);
    return new Response(JSON.stringify({ error: "Erro interno do servidor" }), { status: 500 });
  }
});
