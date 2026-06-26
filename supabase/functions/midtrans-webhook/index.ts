import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const midtransServerKey = Deno.env.get("MIDTRANS_SERVER_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const payload = await req.json();

    const orderId = payload.order_id as string | undefined;
    const statusCode = payload.status_code as string | undefined;
    const grossAmount = payload.gross_amount as string | undefined;
    const signatureKey = payload.signature_key as string | undefined;

    if (!orderId || !statusCode || !grossAmount || !signatureKey) {
      return json({ message: "Invalid Midtrans payload" }, 422);
    }

    const expectedSignature = await sha512(`${orderId}${statusCode}${grossAmount}${midtransServerKey}`);
    if (expectedSignature !== signatureKey) {
      return json({ message: "Invalid signature" }, 401);
    }

    const transactionStatus = payload.transaction_status as string;
    const fraudStatus = payload.fraud_status as string | undefined;
    const paid =
      transactionStatus === "settlement" ||
      (transactionStatus === "capture" && fraudStatus === "accept");
    const expired = transactionStatus === "expire";
    const failed = ["deny", "cancel", "failure"].includes(transactionStatus);

    const { data: payment, error: paymentError } = await supabase
      .from("payments")
      .update({
        status: transactionStatus,
        raw_payload: payload,
      })
      .eq("provider_order_id", orderId)
      .select("booking_id")
      .single();

    if (paymentError || !payment) {
      return json({ message: "Payment not found" }, 404);
    }

    if (paid || expired || failed) {
      await supabase
        .from("bookings")
        .update({
          status: paid ? "paid" : expired ? "expired" : "failed",
        })
        .eq("id", payment.booking_id);
    }

    return json({ received: true });
  } catch (error) {
    return json({ message: error.message ?? "Unexpected error" }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
    },
  });
}

async function sha512(value: string) {
  const data = new TextEncoder().encode(value);
  const hash = await crypto.subtle.digest("SHA-512", data);
  return Array.from(new Uint8Array(hash))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}
