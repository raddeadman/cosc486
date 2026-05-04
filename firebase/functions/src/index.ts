import admin from "./admin";
import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";

import * as auth from "./auth";
import * as products from "./products";
import * as favorites from "./favorites";
import * as chat from "./chat";
import * as reviews from "./reviews";
import * as storage from "./storage";

const db = admin.firestore();

// import {
//   Product,
//   Message,
//   Review,
//   Chat
// } from "./types";

/**
 * User Profile Model (matches User.swift structure)
 */
export interface UserProfile {
  id: string;
  name: string;
  email: string;
  profileImageUrl?: string;
  ratingAverage: number;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt?: FirebaseFirestore.Timestamp;
}

/**
 * Get initials image URL for default avatar
 */
function getInitialsImageURL(name?: string): string {
  if (!name) return "";

  const initials = name
    .split(" ")
    .map((word) => word[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);

  // Generate a deterministic color based on initials
  const hue = initials.charCodeAt(0) % 360;
  const bgColor = `hsl(${hue}, 70%, 90%)`;

  return `https://via.placeholder.com/100x100/${bgColor.replace("#", "")}/FFFFFF?text=${initials}`;
}

/**
 * OnAuthUserCreate - Triggered when a new user is created in Firebase Auth
 */
export const onAuthUserCreate = functions.auth.user().onCreate(async (user, context) => {
  logger.log(`New user created: ${user.uid}`, { email: user.email });

  try {
    // Generate default profile image URL
    const profileImageUrl = getInitialsImageURL(user.displayName || user.email);

    // Create user profile in Firestore with the exact User.swift model structure
    await db.collection("users").doc(user.uid).set({
      id: user.uid,
      name: user.displayName || "User",
      email: user.email || "",
      profileImageUrl: profileImageUrl,
      ratingAverage: 0.0,
      ratingCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    logger.log(`User profile created successfully for ${user.uid}`);
    return null; // Explicitly return to prevent any implicit returns
  } catch (error) {
    logger.error("Failed to create user profile", error);
    throw new Error(`Failed to create user profile: ${error}`);
  }
});

/**
 * OnAuthUserDelete - Triggered when a user is deleted from Firebase Auth
 */
export const onAuthUserDelete = functions.auth.user().onDelete(async (user, context) => {
  logger.log("User deleted", { uid: user.uid, email: user.email });

  try {
    // Delete the Firestore document
    await db.collection("users").doc(user.uid).delete();

    logger.log(`User profile deleted from Firestore for ${user.uid}`);
    return null;
  } catch (error) {
    logger.error("Failed to delete user profile", error);
    // Don't throw on delete to ensure auth user deletion succeeds
    return null;
  }
});

// Export all the new functions
export const login = auth.login;
export const logout = auth.logout;
export const fetchUserProfile = auth.fetchUserProfile;
export const updateUserProfile = auth.updateUserProfile;
export const signUp = auth.signUp;

export const fetchProducts = products.fetchProducts;
export const fetchMyProducts = products.fetchMyProducts;
export const submitPlaceholderProduct = products.submitPlaceholderProduct;
export const updateProductAvailability = products.updateProductAvailability;

export const fetchFavoriteProducts = favorites.fetchFavoriteProducts;
export const addFavorite = favorites.addFavorite;
export const removeFavorite = favorites.removeFavorite;

export const getOrCreateChat = chat.getOrCreateChat;
export const fetchChats = chat.fetchChats;
export const fetchMessages = chat.fetchMessages;
export const sendMessage = chat.sendMessage;
export const resolveChat = chat.resolveChat;

export const fetchReviews = reviews.fetchReviews;
export const fetchProductReviews = reviews.fetchProductReviews;
export const addReview = reviews.addReview;

export const uploadImageData = storage.uploadImageData;

