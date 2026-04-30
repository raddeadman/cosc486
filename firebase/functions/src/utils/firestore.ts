// firebase/functions/src/utils/firestore.ts
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import { Product } from '../models/product';

const db = admin.firestore();

export async function createProduct(productData: Omit<Product, 'id' | 'createdAt'>): Promise<Product> {
  const productId = db.collection('products').doc().id;
  const createdAt = admin.firestore.FieldValue.serverTimestamp();

  const productWithId = {
    ...productData,
    id: productId,
    createdAt
  };

  await db.collection('products').doc(productId).set(productWithId);
  return { ...productWithId, createdAt: createdAt as FirebaseFirestore.Timestamp };
}

export async function updateProduct(
  productId: string,
  updates: Partial<Product>,
  context?: functions.https.CallableContext
): Promise<Product | null> {
  const productRef = db.collection('products').doc(productId);

  // Get current document to verify seller
  const doc = await productRef.get();
  if (!doc.exists) return null;

  const productData = doc.data() as Product;
  if (context && context.auth?.uid !== productData.sellerId) {
    throw new Error('Not authorized to update this product');
  }

  // Update the document
  await productRef.update({
    ...updates,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { ...productData, ...updates };
}

export async function deleteProduct(
  productId: string,
  context?: functions.https.CallableContext
): Promise<boolean> {
  const productRef = db.collection('products').doc(productId);

  // Get current document to verify seller
  const doc = await productRef.get();
  if (!doc.exists) return false;

  const productData = doc.data() as Product;
  if (context && context.auth?.uid !== productData.sellerId) {
    throw new Error('Not authorized to delete this product');
  }

  // Delete the document
  await productRef.delete();
  return true;
}

export async function getProduct(productId: string): Promise<Product | null> {
  const doc = await db.collection('products').doc(productId).get();
  if (!doc.exists) return null;

  return doc.data() as Product;
}

export async function getProductsByCategory(category: string): Promise<Product[]> {
  const snapshot = await db.collection('products')
    .where('category', '==', category)
    .orderBy('createdAt', 'desc')
    .get();

  return snapshot.docs.map(doc => doc.data() as Product);
}

export async function getNearbyProducts(
  latitude: number,
  longitude: number,
  maxDistance: number
): Promise<Product[]> {
  const products = await db.collection('products')
    .where('latitude', '>=', latitude - maxDistance)
    .where('latitude', '<=', latitude + maxDistance)
    .where('longitude', '>=', longitude - maxDistance)
    .where('longitude', '<=', longitude + maxDistance)
    .get();

  return products.docs.map(doc => doc.data() as Product);
}