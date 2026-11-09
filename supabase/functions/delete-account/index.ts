// Deletes the caller's account (Settings → Delete my account).
// 1. Verifies the caller's JWT.  2. Removes their proof photos through the
// Storage API.  3. Deletes the auth user. The FKs then cascade the profile,
// votes and claims, and set time_suggestions.suggested_by / masjids.created_by
// to null, so community times stay, anonymised.
// Deploy: supabase functions deploy delete-account (JWT verification on).
import { adminClient, cors, json, PROOF_BUCKET } from "../_shared/admin_client.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const jwt = req.headers.get("Authorization")?.replace(/^Bearer /, "");
  if (!jwt) return json({ error: "unauthorized" }, 401);

  const admin = adminClient();
  const { data: { user }, error: userError } = await admin.auth.getUser(jwt);
  if (userError || !user) return json({ error: "unauthorized" }, 401);

  // Proof photos live under <user_id>/. A user has a handful at most.
  const bucket = admin.storage.from(PROOF_BUCKET);
  const { data: files, error: listError } = await bucket.list(user.id, {
    limit: 1000,
  });
  if (listError) return json({ error: listError.message }, 500);
  if (files.length > 0) {
    const { error } = await bucket.remove(
      files.map((f) => `${user.id}/${f.name}`),
    );
    if (error) return json({ error: error.message }, 500);
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) return json({ error: deleteError.message }, 500);

  // Never log the user id or email.
  return json({ deleted: true });
});
