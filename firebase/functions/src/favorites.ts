import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Fetches favorite products for a user
 */
export const fetchFavoriteProducts = functions.https.onRequest(async (req: any, res: any) => {
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
      logger.error("Invalid token for favorites fetch", error);
      return res.status(401).json({ error: "Invalid or expired token" });
  }

    // Get the user ID from path parameters or token
    const userId = req.params.userId || (await admin.auth().verifyIdToken(idToken)).uid;
    const querySnapshot = await db.collection('favorites')
      .where('userId', '==', userId)
      .get();

    const favorites = [];
    for (const doc of querySnapshot.docs) {
      const productData = doc.data() as any;
      if (productData.productId) {
        // Fetch the actual product data
        const productDoc = await db.collection('products').doc(productData.productId).get();
        if (productDoc.exists) {
          const productInfo = productDoc.data() as any;
          favorites.push({
            ...productInfo,
            favoriteId: doc.id,
            createdAt: productInfo.createdAt?.toDate().toISOString(),
          });
        }
      }
    }

    res.status(200).json(favorites);
  } catch (error) {
    logger.error('Error fetching favorites', error);
    return res.status(500).json({ error: `Failed to fetch favorites: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * Adds a product to user's favorites
 */
export const addFavorite = functions.https.onRequest(async (req: any, res: any) => {
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
      logger.error("Invalid token for adding favorite", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    const { productId } = req.body;
    const userId = (await admin.auth().verifyIdToken(idToken)).uid;

    // Check if already favorite
    const existingDoc = await db.collection('favorites')
      .where('userId', '==', userId)
      .where('productId', '==', productId)
      .get();

    if (!existingDoc.empty) {
      return res.status(409).json({ error: "Product already in favorites" });
    }

    await db.collection('favorites').add({
      userId,
      productId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ success: true });
  } catch (error) {
    logger.error('Error adding favorite', error);
    return res.status(500).json({ error: `Failed to add favorite: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * Removes a product from user's favorites
 */
export const removeFavorite = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "DELETE") {
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
      logger.error("Invalid token for removing favorite", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    const { productId } = req.body;
    const userId = (await admin.auth().verifyIdToken(idToken)).uid;

    // Find the favorite document
    const querySnapshot = await db.collection('favorites')
      .where('userId', '==', userId)
      .where('productId', '==', productId)
      .get();

    if (querySnapshot.empty) {
      return res.status(404).json({ error: "Favorite not found" });
    }

    // Delete the document
    for (const doc of querySnapshot.docs) {
      await doc.ref.delete();
    }

    res.status(200).json({ success: true });
  } catch (error) {
    logger.error('Error removing favorite', error);
    return res.status(500).json({ error: `Failed to remove favorite: ${error instanceof Error ? error.message : String(error)}` });
  }
});

