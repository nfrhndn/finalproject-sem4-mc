import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const midtransServerKey = Deno.env.get("MIDTRANS_SERVER_KEY")!;
    const midtransBaseUrl =
      Deno.env.get("MIDTRANS_BASE_URL") ?? "https://app.sandbox.midtrans.com/snap/v1/transactions";

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ message: "Missing authorization header" }, 401);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const jwt = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser(jwt);

    if (userError || !user) {
      return json({ message: "Invalid user session" }, 401);
    }

    const { booking_id } = await req.json();
    if (!booking_id) {
      return json({ message: "booking_id is required" }, 422);
    }

    const { data: booking, error: bookingError } = await supabase
      .from("bookings")
      .select("id, user_id, grand_total, status")
      .eq("id", booking_id)
      .eq("user_id", user.id)
      .single();

    if (bookingError || !booking) {
      return json({ message: "Booking not found" }, 404);
    }

    if (booking.status !== "pending_payment") {
      return json({ message: "Booking is not pending payment" }, 409);
    }

    const orderId = `PADALPRO-${booking.id}-${Date.now()}`;
    const { data: profile } = await supabase
      .from("profiles")
      .select("name, email, phone")
      .eq("id", user.id)
      .single();
    const midtransPayload = {
      transaction_details: {
        order_id: orderId,
        gross_amount: booking.grand_total,
      },
      customer_details: {
        first_name: profile?.name ?? user.email,
        email: profile?.email ?? user.email,
        phone: profile?.phone ?? undefined,
      },
    };

    const midtransResponse = await fetch(midtransBaseUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization: `Basic ${btoa(`${midtransServerKey}:`)}`,
      },
      body: JSON.stringify(midtransPayload),
    });

    const midtransJson = await midtransResponse.json();
    if (!midtransResponse.ok) {
      return json({ message: "Failed to create Midtrans transaction", details: midtransJson }, 502);
    }

    const { error: paymentError } = await supabase.from("payments").upsert(
      {
        booking_id: booking.id,
        user_id: user.id,
        provider: "midtrans",
        provider_order_id: orderId,
        snap_token: midtransJson.token,
        redirect_url: midtransJson.redirect_url,
        amount: booking.grand_total,
        status: "pending",
        raw_payload: midtransJson,
      },
      { onConflict: "provider_order_id" },
    );

    if (paymentError) {
      return json({ message: "Failed to save payment", details: paymentError.message }, 500);
    }

    return json({
      order_id: orderId,
      snap_token: midtransJson.token,
      redirect_url: midtransJson.redirect_url,
    });
  } catch (error) {
    return json({ message: error.message ?? "Unexpected error" }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
