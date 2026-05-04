// Product-related Firebase Functions
import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * ProductService.fetchProducts - HTTP trigger to fetch products with optional filters
 */
export const fetchProducts = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "GET") {
      return res.status(405).send("Method Not Allowed");
    }

    // Get query parameters from request
    const { search, category, sort, lat, lng, radiusKm } = req.query;

    // Build Firestore query based on filters
    let productsRef = db.collection('products');

    if (search) {
      // Use array-contains for text search or create a composite index
      const query = productsRef.where('title', '>=', search);
      productsRef = query as any;
    }

    if (category) {
      let query: admin.firestore.Query = productsRef;
        query = query.where('category', '==', category);
      productsRef = query as any;
    }

    // Apply location-based filtering if coordinates are provided
    if (lat && lng && radiusKm) {
      const latitude = parseFloat(lat as string);
      const longitude = parseFloat(lng as string);

      let query: admin.firestore.Query = productsRef;
        query = query.where('location', '>', new admin.firestore.GeoPoint(latitude, longitude));
      productsRef = query as any;
    }

    // Execute the query
    const productsSnapshot = await productsRef.get();
    const products = [];
    for (const doc of productsSnapshot.docs) {
      const productData = doc.data() as any;
      products.push({
        id: doc.id,
        ...productData,
        createdAt: productData.createdAt?.toDate().toISOString(),
      });
    }

    // Apply sorting if specified
    const sortedProducts = [...products];
    if (sort) {
      switch (sort as string) {
        case 'date':
          sortedProducts.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
          break;
        case 'price':
          sortedProducts.sort((a, b) => a.price - b.price);
          break;
        case 'rating':
          sortedProducts.sort((a, b) => b.rating - a.rating);
          break;
      }
    }

    res.status(200).json(sortedProducts);
  } catch (error) {
    logger.error("Fetch products error", error);
    return res.status(500).json({ error: `Failed to fetch products: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * ProductService.submitPlaceholderProduct - HTTP trigger to create a new product
 */
export const submitPlaceholderProduct = functions.https.onRequest(async (req: any, res: any) => {
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
      logger.error("Invalid token for product creation", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    // Get product data from request body
    const { title, description, category, priceText, locationName, latitude, longitude, imageUrls } = req.body;

    const imageList: string[] = Array.isArray(imageUrls)
      ? (imageUrls as unknown[]).filter((u) => typeof u === "string") as string[]
      : [];

    if (!title || !description || !category || !priceText || !locationName || latitude === undefined || longitude === undefined) {
      return res.status(400).json({ error: "All required fields are missing" });
    }

    const price = parseFloat(priceText as string);
    if (isNaN(price)) {
      return res.status(400).json({ error: "Invalid price value" });
    }

    // Get the user ID from the token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const sellerId = decodedToken.uid;

    // Fetch seller name for the product
    const sellerDoc = await db.collection('users').doc(sellerId).get();
    if (!sellerDoc.exists) {
      return res.status(404).json({ error: "Seller not found" });
    }

    const sellerData = sellerDoc.data() as any;
    const sellerName = sellerData.name || "";

    // Create the product document
    const productRef = await db.collection('products').add({
      title,
      description,
      price,
      category,
      imageUrls: imageList,
      sellerId,
      sellerName,
      locationName,
      latitude,
      longitude,
      rating: 0.0,
      reviewAverage: 0.0,
      reviewCount: 0,
      isAvailable: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      // Add GeoPoint for geolocation queries
      location: new admin.firestore.GeoPoint(latitude, longitude),
    });

    const product = await productRef.get();
    if (!product.exists) {
      return res.status(500).json({ error: "Failed to create product" });
    }

    const productData = product.data() as any;
    res.status(201).json({
      id: product.id,
      ...productData,
      createdAt: productData.createdAt?.toDate().toISOString(),
    });
  } catch (error) {
    logger.error("Submit product error", error);
    return res.status(500).json({ error: `Failed to submit product: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * ProductService.updateProductAvailability - HTTP trigger to toggle product availability
 */
export const updateProductAvailability = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "PATCH") {
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
      logger.error("Invalid token for availability update", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    // Get path parameters and request body
    const userId = req.params.userId;
    const productId = req.params.productId;
    const { isAvailable } = req.body;

    if (!userId || !productId) {
      return res.status(400).json({ error: "User ID and Product ID are required" });
    }

    if (isAvailable === undefined) {
      return res.status(400).json({ error: "Availability status is required" });
    }

    // Verify that the user owns the product
    const productDoc = await db.collection('products').doc(productId).get();
    if (!productDoc.exists) {
      return res.status(404).json({ error: "Product not found" });
    }

    const productData = productDoc.data() as any;
    if (productData.sellerId !== userId) {
      return res.status(403).json({ error: "User does not own this product" });
    }

    // Update the product availability
    await db.collection('products').doc(productId).update({
      isAvailable,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Return the updated product
    const updatedProduct = await db.collection('products').doc(productId).get();
    if (!updatedProduct.exists) {
      return res.status(500).json({ error: "Failed to fetch updated product" });
    }

    const updatedData = updatedProduct.data() as any;
    res.status(200).json({
      id: productId,
      ...updatedData,
      createdAt: updatedData.createdAt?.toDate().toISOString(),
    });
  } catch (error) {
    logger.error("Update availability error", error);
    return res.status(500).json({ error: `Failed to update availability: ${error instanceof Error ? error.message : String(error)}` });
  }
});

