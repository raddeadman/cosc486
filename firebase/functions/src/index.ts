/**
 * Authentication and User Profile Management Cloud Functions
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/auth";
import {onError, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as validator from "express-validator";

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();
const storage = admin.storage();

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
 * OnAuthUserCreate - Triggered when a new user is created in Firebase Auth
 * This function creates the user profile in Firestore
 */
export const onAuthUserCreate = functions.auth.user().onCreate(async (user) => {
  logger.info(`New user created: ${user.uid}`, { email: user.email });

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
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    logger.info(`User profile created successfully for ${user.uid}`);
    
    return { status: "success", message: "User profile created" };
  } catch (error) {
    logger.error("Failed to create user profile", error);
    throw error;
  }
});

/**
 * OnAuthUserUpdate - Triggered when user updates their display name or email
 */
export const onAuthUserUpdate = functions.auth.user().onUpdate(async (change) => {
  const before = change.before.toJSON();
  const after = change.after.toJSON();

  logger.info("User updated", { uid: change.uid });

  try {
    // Only update Firestore if display name changed
    if (before.displayName !== after.displayName) {
      await db.collection("users").doc(change.uid).update({
        name: after.displayName || "User",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { status: "success", message: "User profile updated" };
  } catch (error) {
    logger.error("Failed to update user profile", error);
    throw error;
  }
});

/**
 * OnAuthUserDelete - Triggered when a user is deleted from Firebase Auth
 * This helps clean up data but keep some user stats if needed
 */
export const onAuthUserDelete = functions.auth.user().onDelete(async (user) => {
  logger.info("User deleted", { uid: user.uid, email: user.email });

  try {
    // Optionally delete the Firestore document or archive it
    await db.collection("users").doc(user.uid).delete();

    logger.info(`User profile deleted from Firestore for ${user.uid}`);
    
    return { status: "success", message: "User profile deleted" };
  } catch (error) {
    logger.error("Failed to delete user profile", error);
    // Don't throw on delete to ensure auth user deletion succeeds
  }
});

/**
 * Get initials image URL for default avatar
 */
function getInitialsImageURL(name?: string): string {
  if (!name) return "";
  
  const initials = name
    .split(" ")
    .map(word => word[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);

  // Generate a deterministic color based on initials
  const hue = initials.charCodeAt(0) % 360;
  const bgColor = `hsl(${hue}, 70%, 90%)`;
  const textColor = "hsl(0, 0%, 15%)";

  return {
    url: `https://www.undraw.co/api/img/${initials}?bg=${bgColor}&textColor=${textColor}&color=default`,
    initials: initials,
  };
}

/**
 * Error handler for all HTTPS calls
 */
onError((error, request, response) => {
  logger.error("HTTPS call error:", error);
  return response.status(500).json({ error: "Internal server error" });
});
