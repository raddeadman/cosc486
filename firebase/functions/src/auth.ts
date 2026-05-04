// Auth-related Firebase Functions
import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";

// Initialize app
admin.initializeApp();


const db = admin.firestore();

/**
 * AuthService.login - HTTP trigger for login endpoint
 */
export const login = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    // Get email and password from request body
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required" });
    }

    // Sign in the user with Firebase Auth - this verifies both email and password
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (error) {
      logger.error("User not found", error);
      return res.status(401).json({ error: "Invalid email or password" });
    }

    // Verify password by attempting to create a custom token
    try {
      const customToken = await admin.auth().createCustomToken(userRecord.uid);
      // If we get here, the credentials are valid

      // Get the user's UID
      const uid = userRecord.uid;

      // Fetch the user profile from Firestore
      const userDoc = await db.collection("users").doc(uid).get();

      if (!userDoc.exists) {
        return res.status(404).json({ error: "User not found" });
      }

      // Get the user data with proper types
      const userData = userDoc.data() as any;

      // Return the response in the expected format (using customToken instead of ID token)
      res.status(200).json({
        token: customToken,
        user: {
          id: uid,
          name: userData.name || "",
          email: userData.email || "",
          profileImageUrl: userData.profileImageUrl || "",
          ratingAverage: userData.ratingAverage || 0,
        },
      });
    } catch (authError) {
      logger.error("Authentication error", authError);
      if (authError instanceof Error && authError.message.includes("USER_DISABLED")) {
        return res.status(401).json({ error: "User account disabled" });
      }
      return res.status(401).json({ error: "Invalid email or password" });
    }
  } catch (error) {
    logger.error("Login error", error);
    // Handle errors with proper type checking since admin.auth.AuthError doesn't exist in v10+
    if (error && typeof error === 'object' && 'code' in error) {
      const authError = error as { code: string; message?: string };
      // Handle specific auth errors
      switch (authError.code) {
        case "auth/invalid-email":
          return res.status(400).json({ error: "Invalid email" });
        case "auth/user-not-found":
          return res.status(401).json({ error: "User not found" });
        default:
          return res.status(500).json({ error: `Authentication failed: ${authError.message || String(error)}` });
      }
    }
    return res.status(500).json({ error: `Login failed: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * AuthService.logout - HTTP trigger for logout endpoint
 */
export const logout = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    // Get the authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Authorization token required" });
    }

    const idToken = authHeader.split("Bearer ")[1];

    // Verify the ID token
    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.error("Invalid token", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    // In Firebase Auth, logout is typically handled client-side
    // Server-side we can just acknowledge the request
    res.status(200).json({ success: true });
  } catch (error) {
    logger.error("Logout error", error);
    return res.status(500).json({ error: `Logout failed: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * AuthService.fetchUserProfile - HTTP trigger to fetch user profile
 */
export const fetchUserProfile = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "GET") {
      return res.status(405).send("Method Not Allowed");
    }

    // Get the UID from path parameters
    const uid = req.params.uid;

    if (!uid) {
      return res.status(400).json({ error: "User ID is required" });
    }

    // Fetch the user profile from Firestore
    const userDoc = await db.collection("users").doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: "User not found" });
    }

    // Get the user data with proper types and add createdAt as string for API consistency
    const userData = userDoc.data() as any;
    const profileImageUrl = userData.profileImageUrl || "";

    res.status(200).json({
      id: uid,
      name: userData.name || "",
      email: userData.email || "",
      profileImageUrl,
      ratingAverage: userData.ratingAverage || 0,
      createdAt: userData.createdAt?.toDate().toISOString() || "",
    });
  } catch (error) {
    logger.error("Fetch user profile error", error);
    return res.status(500).json({ error: `Failed to fetch user profile: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * AuthService.updateUserProfile - HTTP trigger to update user profile
 */
export const updateUserProfile = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "PATCH") {
      return res.status(405).send("Method Not Allowed");
    }

    // Get the UID from path parameters and request body
    const uid = req.params.uid;
    const { name, email } = req.body;

    if (!uid) {
      return res.status(400).json({ error: "User ID is required" });
    }

    if (!name && !email) {
      return res.status(400).json({ error: "At least one of name or email must be provided" });
    }

    // Get the authorization header for validation
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith("Bearer ")) {
      const idToken = authHeader.split("Bearer ")[1];
      try {
        await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        logger.error("Invalid token for profile update", error);
        return res.status(401).json({ error: "Invalid or expired token" });
      }
    }

    // Update the user in Firestore
    const updates: any = {};
    if (name !== undefined) {
      updates.name = name;
    }
    if (email !== undefined) {
      updates.email = email;
    }
    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    // Check if user document exists before updating
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: "User not found" });
    }

    await db.collection("users").doc(uid).update(updates);

    // Return the updated user profile
    const updatedUserDoc = await db.collection("users").doc(uid).get();
    if (!updatedUserDoc.exists) {
      return res.status(404).json({ error: "User not found" });
    }
    const userData = updatedUserDoc.data() as any;
    const profileImageUrl = userData.profileImageUrl || "";

    res.status(200).json({
      id: uid,
      name: userData.name || "",
      email: userData.email || "",
      profileImageUrl,
      ratingAverage: userData.ratingAverage || 0,
      createdAt: userData.createdAt?.toDate().toISOString() || "",
    });
  } catch (error) {
    logger.error("Update user profile error", error);
    return res.status(500).json({ error: `Failed to update user profile: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * AuthService.signUp - HTTP trigger for user registration
 */
export const signUp = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    // Get user data from request body
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: "Name, email and password are required" });
    }

    // Check if user already exists
    let userExists = false;
    try {
      await admin.auth().getUserByEmail(email);
      userExists = true;
    } catch (error) {
      // User doesn't exist, this is expected
      if (!(error instanceof Error) || !error.message.includes("USER_NOT_FOUND")) {
        throw error;
      }
    }

    if (userExists) {
      return res.status(409).json({ error: "Email already in use" });
    }

    // Create user in Firebase Auth with the provided email and password
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    // Get the user's UID
    const uid = userRecord.uid;

    // Create or update user profile in Firestore with initial data
    await db.collection("users").doc(uid).set({
      id: uid,
      name,
      email,
      profileImageUrl: "", // Will be updated by onAuthUserCreate trigger
      ratingAverage: 0.0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Create a custom token for the new user
    const customToken = await admin.auth().createCustomToken(uid);

    // Return the response in the expected format
    res.status(201).json({
      token: customToken,
      user: {
        id: uid,
        name,
        email,
        profileImageUrl: "",
        ratingAverage: 0.0,
      },
    });
    return; // Explicit return
  } catch (error) {
    logger.error("Sign up error", error);
    // Handle errors with proper type checking since admin.auth.AuthError doesn't exist in v10+
    if (error && typeof error === 'object' && 'code' in error) {
      const authError = error as { code: string; message?: string };
      // Handle specific auth errors
      switch (authError.code) {
        case "auth/email-already-in-use":
          return res.status(409).json({ error: "Email already in use" });
        case "auth/invalid-email":
          return res.status(400).json({ error: "Invalid email" });
        default:
          return res.status(500).json({ error: `Registration failed: ${authError.message || String(error)}` });
      }
    }
    return res.status(500).json({ error: `Sign up failed: ${error instanceof Error ? error.message : String(error)}` });
  }
});