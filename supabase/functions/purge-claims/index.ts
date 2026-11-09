// Daily retention job (pg_cron → pg_net, migration …08_account.sql):
// - claims decided 90+ days ago: delete the proof photo (Storage API) and
//   null phone + proof_path;
// - superseded suggestions older than 1 year: delete.
// Called with `Authorization: Bearer <PURGE_SECRET>`, not a user JWT.
// Deploy: supabase functions deploy purge-claims --no-verify-jwt
//         supabase secrets set PURGE_SECRET=<same value as vault purge_secret>
import { adminClient, json, PROOF_BUCKET } from "../_shared/admin_client.ts";

const DAY = 24 * 60 * 60 * 1000;
const BATCH = 500;

Deno.serve(async (req) => {
  const secret = Deno.env.get("PURGE_SECRET");
  if (!secret || req.headers.get("Authorization") !== `Bearer ${secret}`) {
    return json({ error: "unauthorized" }, 401);
  }
  const admin = adminClient();
  const claimCutoff = new Date(Date.now() - 90 * DAY).toISOString();
  const suggestionCutoff = new Date(Date.now() - 365 * DAY).toISOString();

  let claims = 0;
  // ponytail: one batch of 500 per run; a backlog drains over a few days.
  const { data: due, error: dueError } = await admin
    .from("masjid_admins")
    .select("id,proof_path")
    .lt("reviewed_at", claimCutoff)
    .or("phone.not.is.null,proof_path.not.is.null")
    .limit(BATCH);
  if (dueError) return json({ error: dueError.message }, 500);

  const paths = due.map((c) => c.proof_path).filter((p): p is string => !!p);
  if (paths.length > 0) {
    const { error } = await admin.storage.from(PROOF_BUCKET).remove(paths);
    if (error) return json({ error: error.message }, 500);
  }
  if (due.length > 0) {
    const { error, count } = await admin
      .from("masjid_admins")
      .update({ phone: null, proof_path: null }, { count: "exact" })
      .in("id", due.map((c) => c.id));
    if (error) return json({ error: error.message }, 500);
    claims = count ?? 0;
  }

  const { error: sError, count: suggestions } = await admin
    .from("time_suggestions")
    .delete({ count: "exact" })
    .eq("status", "superseded")
    .lt("created_at", suggestionCutoff);
  if (sError) return json({ error: sError.message }, 500);

  return json({ claims, photos: paths.length, suggestions: suggestions ?? 0 });
});
