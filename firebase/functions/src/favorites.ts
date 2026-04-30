// ... existing code ...

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Fetches favorite products for a user
 */
export const fetchFavoriteProducts = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  try {
    const userId = data.userId || context.auth.uid;
    const querySnapshot = await db.collection('favorites')
      .where('userId', '==', userId)
      .get();

    const favorites = [];
    for (const doc of querySnapshot.docs) {
      const productData = doc.data();
      if (productData.productId) {
        // Fetch the actual product data
        const productDoc = await db.collection('products').doc(productData.productId).get();
        if (productDoc.exists) {
          favorites.push({
            ...productDoc.data(),
            favoriteId: doc.id
          });
        }
      }
    }

    return { favorites };
  } catch (error) {
    logger.error('Error fetching favorites', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch favorites'
    );
  }
});

/**
 * Adds a product to user's favorites
 */
export const addFavorite = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  try {
    const { productId } = data;
    const userId = context.auth.uid;

    // Check if already favorite
    const existingDoc = await db.collection('favorites')
      .where('userId', '==', userId)
      .where('productId', '==', productId)
      .get();

    if (!existingDoc.empty) {
      throw new functions.https.HttpsError(
        'already-exists',
        'Product already in favorites'
      );
    }

    await db.collection('favorites').add({
      userId,
      productId,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true };
  } catch (error) {
    logger.error('Error adding favorite', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to add favorite'
    );
  }
});

/**
 * Removes a product from user's favorites
 */
export const removeFavorite = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  try {
    const { productId } = data;
    const userId = context.auth.uid;

    // Find the favorite document
    const querySnapshot = await db.collection('favorites')
      .where('userId', '==', userId)
      .where('productId', '==', productId)
      .get();

    if (querySnapshot.empty) {
      throw new functions.https.HttpsError(
        'not-found',
        'Favorite not found'
      );
    }

    // Delete the document
    for (const doc of querySnapshot.docs) {
      await doc.ref.delete();
    }

    return { success: true };
  } catch (error) {
    logger.error('Error removing favorite', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to remove favorite'
    );
  }
});

// ... rest of code ...