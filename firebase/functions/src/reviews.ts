// ... existing code ...

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Fetches reviews for a seller
 */
export const fetchReviews = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  try {
    const { sellerId } = data;
    const currentUserId = context.auth.uid;

    // Check if current user is the seller or admin
    if (currentUserId !== sellerId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You are not authorized to view these reviews'
      );
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

    return { reviews };
  } catch (error) {
    logger.error('Error fetching reviews', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch reviews'
    );
  }
});

/**
 * Adds a review for a seller
 */
export const addReview = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  try {
    const { sellerId, reviewerId, rating, comment } = data;
    const currentUserId = context.auth.uid;

    // Verify the reviewer is not the seller
    if (currentUserId === sellerId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'You cannot review yourself'
      );
    }

    // Check if this product has already been reviewed by this buyer
    const existingReview = await db.collection('reviews')
      .where('sellerId', '==', sellerId)
      .where('reviewerId', '==', reviewerId)
      .get();

    if (!existingReview.empty) {
      throw new functions.https.HttpsError(
        'already-exists',
        'You have already reviewed this seller'
      );
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
      const newRating = ((currentRating * reviewsSnapshot.size) + rating) / (reviewsSnapshot.size + 1);

      await sellerDocRef.update({
        ratingAverage: newRating
      });
    }

    const reviewData = (await reviewDoc.get()).data();
    return {
      id: reviewDoc.id,
      ...reviewData
    };
  } catch (error) {
    logger.error('Error adding review', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to add review'
    );
  }
});

// ... rest of code ...