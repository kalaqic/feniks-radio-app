const Stripe = require("stripe");

module.exports = async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({error: "Method not allowed"});
  }

  const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
  if (!stripeSecretKey) {
    return res.status(500).json({error: "Missing STRIPE_SECRET_KEY"});
  }

  const amountEur = Number(req.body?.amountEur);
  const uid = String(req.body?.uid ?? "");
  if (!Number.isFinite(amountEur) || amountEur < 2.5 || amountEur > 100) {
    return res.status(400).json({error: "Invalid amount"});
  }
  if (!uid) {
    return res.status(400).json({error: "Missing uid"});
  }

  const stripe = new Stripe(stripeSecretKey);
  const amount = Math.round(amountEur * 100);

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: "eur",
      payment_method_types: ["card"],
      metadata: {
        uid,
        source: "feniks_flutter_music_request",
      },
    });

    return res.status(200).json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (error) {
    return res.status(500).json({
      error: "Failed to create payment intent",
      message: error?.message ?? "Unknown error",
    });
  }
};
