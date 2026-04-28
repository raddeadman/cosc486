import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

admin.initializeApp();
const db = admin.firestore();

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
 * Helper function to verify authentication
 */
async function verifyAuth(request: any): Promise<any> {
  const authHeader = request.headers.authorization;
  if (!authHeader) {
    throw new Error("Unauthorized - No authorization header");
  }

  try {
    // Verify Firebase ID token
    const idToken = authHeader.split("Bearer ")[1];
    return await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    logger.error("Failed to verify authentication", error);
    throw new Error("Unauthorized - Invalid token");
  }
}

export const createUserProfile = onRequest({
}, async (request, response) => {
  try {
    const userInfo = await verifyAuth(request);
    logger.info(`New user created: ${userInfo.uid}`, { email: userInfo.email });
    const profileImageUrl = getInitialsImageURL(userInfo.displayName || userInfo.email);

    await db.collection("users").doc(userInfo.uid).set({
      id: userInfo.uid,
      name: userInfo.displayName || "User",
      email: userInfo.email || "",
          profileImageUrl: profileImageUrl,
          ratingAverage: 0.0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    logger.info(`User profile created successfully for ${userInfo.uid}`);
    response.status(200).send("User profile created");
  } catch (error) {
    logger.error("Failed to create user profile", error);
    if (error instanceof Error) {
      response.status(error.message === "Unauthorized - No authorization header" ? 401 : 500)
        .json({ error: error.message });
    } else {
      response.status(500).json({ error: "Failed to create user profile" });
    }
    throw error;
  }
});

export const deleteUserProfile = onRequest({
}, async (request, response) => {
  try {
    const userInfo = await verifyAuth(request);
    logger.info("User deleted", { uid: userInfo.uid, email: userInfo.email });
    await db.collection("users").doc(userInfo.uid).delete();
    logger.info(`User profile deleted from Firestore for ${userInfo.uid}`);
    response.status(200).send("User profile deleted");
  } catch (error) {
    logger.error("Failed to delete user profile", error);
    if (error instanceof Error) {
      response.status(error.message === "Unauthorized - No authorization header" ? 401 : 500)
        .json({ error: error.message });
    } else {
      response.status(500).json({ error: "Failed to delete user profile" });
    }
  }
});
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

  // For now, return a placeholder URL; replace with actual avatar generation
  return `https://via.placeholder.com/100x100/${bgColor.replace("#", "")}/FFFFFF?text=${initials}`;
}

/**
 * Error handler for all HTTPS calls
 */

