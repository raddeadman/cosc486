import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

async function requireUserId(req: any): Promise<string | null> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return null;
  }
  const idToken = authHeader.split("Bearer ")[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    return decoded.uid;
  } catch {
    return null;
  }
}

/**
 * Fetches reviews for a seller (any signed-in user).
 */
export const fetchReviews = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "GET") {
      return res.status(405).send("Method Not Allowed");
    }

    const currentUserId = await requireUserId(req);
    if (!currentUserId) {
      return res.status(401).json({ error: "Authorization token required" });
    }

    const sellerIdValue = req.query.sellerId;
    const sellerId = Array.isArray(sellerIdValue) ? sellerIdValue[0] : sellerIdValue;
    if (!sellerId || typeof sellerId !== "string") {
      return res.status(400).json({ error: "sellerId is required" });
    }

    const reviewsSnapshot = await db.collection("reviews")
      .where("sellerId", "==", sellerId)
      .orderBy("createdAt", "desc")
      .get();

    const reviews: any[] = [];
    for (const doc of reviewsSnapshot.docs) {
      const reviewData = doc.data() as any;
      reviews.push({
        id: doc.id,
        ...reviewData,
        createdAt: reviewData.createdAt?.toDate().toISOString(),
      });
    }

    res.status(200).json(reviews);
  } catch (error) {
    logger.error("Error fetching reviews", error);
    return res.status(500).json({ error: `Failed to fetch reviews: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * Fetches reviews for a product (product-level thread).
 */
export const fetchProductReviews = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "GET") {
      return res.status(405).send("Method Not Allowed");
    }

    const currentUserId = await requireUserId(req);
    if (!currentUserId) {
      return res.status(401).json({ error: "Authorization token required" });
    }

    const productIdValue = req.query.productId;
    const productId = Array.isArray(productIdValue) ? productIdValue[0] : productIdValue;
    if (!productId || typeof productId !== "string") {
      return res.status(400).json({ error: "productId is required" });
    }

    const reviewsSnapshot = await db.collection("reviews")
      .where("productId", "==", productId)
      .orderBy("createdAt", "desc")
      .get();

    const reviews: any[] = [];
    for (const doc of reviewsSnapshot.docs) {
      const reviewData = doc.data() as any;
      reviews.push({
        id: doc.id,
        ...reviewData,
        createdAt: reviewData.createdAt?.toDate().toISOString(),
      });
    }

    res.status(200).json(reviews);
  } catch (error) {
    logger.error("Error fetching product reviews", error);
    return res.status(500).json({ error: `Failed to fetch product reviews: ${error instanceof Error ? error.message : String(error)}` });
  }
});

async function recomputeProductReviewStats(productId: string) {
  const snap = await db.collection("reviews").where("productId", "==", productId).get();
  let total = 0;
  let count = 0;
  for (const doc of snap.docs) {
    const r = doc.data() as any;
    const n = Number(r.rating);
    if (Number.isFinite(n) && n >= 1 && n <= 5) {
      total += n;
      count++;
    }
  }
  const avg = count > 0 ? total / count : 0;
  await db.collection("products").doc(productId).update({
    reviewAverage: avg,
    reviewCount: count,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function recomputeSellerReviewStats(sellerId: string) {
  const snap = await db.collection("reviews").where("sellerId", "==", sellerId).get();
  let total = 0;
  let count = 0;
  for (const doc of snap.docs) {
    const r = doc.data() as any;
    const n = Number(r.rating);
    if (Number.isFinite(n) && n >= 1 && n <= 5) {
      total += n;
      count++;
    }
  }
  const avg = count > 0 ? total / count : 0;
  await db.collection("users").doc(sellerId).set({
    ratingAverage: avg,
    ratingCount: count,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

/**
 * Adds a product review. Reviewer must be a participant in a chat for this product with this seller.
 */
export const addReview = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const currentUserId = await requireUserId(req);
    if (!currentUserId) {
      return res.status(401).json({ error: "Authorization token required" });
    }

    const { productId, sellerId, rating, comment } = req.body;
    if (!productId || typeof productId !== "string") {
      return res.status(400).json({ error: "productId is required" });
    }
    if (!sellerId || typeof sellerId !== "string") {
      return res.status(400).json({ error: "sellerId is required" });
    }

    const ratingNum = Number(rating);
    if (!Number.isInteger(ratingNum) || ratingNum < 1 || ratingNum > 5) {
      return res.status(400).json({ error: "rating must be an integer from 1 to 5" });
    }

    if (currentUserId === sellerId) {
      return res.status(400).json({ error: "You cannot review yourself" });
    }

    const productDoc = await db.collection("products").doc(productId).get();
    if (!productDoc.exists) {
      return res.status(404).json({ error: "Product not found" });
    }
    const productData = productDoc.data() as any;
    if (productData.sellerId !== sellerId) {
      return res.status(400).json({ error: "Seller does not match this product" });
    }

    const chatSnap = await db.collection("chats")
      .where("productId", "==", productId)
      .where("sellerId", "==", sellerId)
      .where("participantIds", "array-contains", currentUserId)
      .limit(1)
      .get();

    if (chatSnap.empty) {
      return res.status(403).json({ error: "You can only review after chatting with the seller about this product" });
    }

    const existing = await db.collection("reviews")
      .where("productId", "==", productId)
      .where("reviewerId", "==", currentUserId)
      .limit(1)
      .get();

    if (!existing.empty) {
      return res.status(409).json({ error: "You have already reviewed this product" });
    }

    const commentText = typeof comment === "string" ? comment : "";

    const reviewDoc = await db.collection("reviews").add({
      productId,
      sellerId,
      reviewerId: currentUserId,
      rating: ratingNum,
      comment: commentText,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await recomputeProductReviewStats(productId);
    await recomputeSellerReviewStats(sellerId);

    const reviewData = (await reviewDoc.get()).data() as any;
    res.status(201).json({
      id: reviewDoc.id,
      ...reviewData,
      createdAt: reviewData.createdAt?.toDate().toISOString(),
    });
  } catch (error) {
    logger.error("Error adding review", error);
    return res.status(500).json({ error: `Failed to add review: ${error instanceof Error ? error.message : String(error)}` });
  }
});
