import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Fetches reviews for a seller
 */
export const fetchReviews = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== "GET") {
      return res.status(405).send("Method Not Allowed");
    }

    // Get the authorization header for validation
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Authorization token required" });
    }

    const idToken = authHeader.split("Bearer ")[1];

    // Verify the ID token
    try {
      await admin.auth().verifyIdToken(idToken);
  } catch (error) {
      logger.error("Invalid token for fetching reviews", error);
      return res.status(401).json({ error: "Invalid or expired token" });
  }

    const { sellerId } = req.query;
    const currentUserId = (await admin.auth().verifyIdToken(idToken)).uid;

    // Check if current user is the seller or admin
    if (currentUserId !== sellerId) {
      return res.status(403).json({ error: "You are not authorized to view these reviews" });
    }

    const reviewsSnapshot = await db.collection('reviews')
      .where('sellerId', '==', sellerId)
      .orderBy('createdAt', 'desc')
      .get();

    const reviews = [];
    for (const doc of reviewsSnapshot.docs) {
      const reviewData = doc.data();
      reviews.push({
        id: doc.id,
        ...reviewData
      });
    }

    res.status(200).json(reviews);
  } catch (error) {
    logger.error('Error fetching reviews', error);
    return res.status(500).json({ error: 'Failed to fetch reviews' });
  }
});

/**
 * Adds a review for a seller
 */
export const addReview = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    // Get the authorization header for validation
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Authorization token required" });
    }

    const idToken = authHeader.split("Bearer ")[1];

    // Verify the ID token
    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.error("Invalid token for adding review", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    const { sellerId, reviewerId, rating, comment } = req.body;
    const currentUserId = (await admin.auth().verifyIdToken(idToken)).uid;

    // Verify the reviewer is not the seller
    if (currentUserId === sellerId) {
      return res.status(400).json({ error: "You cannot review yourself" });
    }

    // Check if this product has already been reviewed by this buyer
    const existingReview = await db.collection('reviews')
      .where('sellerId', '==', sellerId)
      .where('reviewerId', '==', reviewerId)
      .get();

    if (!existingReview.empty) {
      return res.status(409).json({ error: "You have already reviewed this seller" });
    }

    const reviewDoc = await db.collection('reviews').add({
      sellerId,
      reviewerId,
      rating,
      comment,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update seller's average rating
    const sellerDocRef = db.collection('users').doc(sellerId);
    const sellerDoc = await sellerDocRef.get();

    if (sellerDoc.exists) {
      const currentRating = sellerDoc.data().ratingAverage || 0;
      // Get all reviews for this seller to calculate new average
      const allReviewsSnapshot = await db.collection('reviews')
        .where('sellerId', '==', sellerId)
        .get();

      let totalRating = 0;
      let reviewCount = 0;

      for (const doc of allReviewsSnapshot.docs) {
        const reviewData = doc.data();
        totalRating += reviewData.rating;
        reviewCount++;
      }

      const newRating = reviewCount > 0 ? totalRating / reviewCount : rating;

      await sellerDocRef.update({
        ratingAverage: newRating
      });
    }

    const reviewData = (await reviewDoc.get()).data();
    res.status(201).json({
      id: reviewDoc.id,
      ...reviewData
    });
  } catch (error) {
    logger.error('Error adding review', error);
    return res.status(500).json({ error: 'Failed to add review' });
  }
});
