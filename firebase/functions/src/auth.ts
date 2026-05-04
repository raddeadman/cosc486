// Auth-related Firebase Functions
import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";
import * as https from "https";

const FIREBASE_API_KEY = process.env.FIREBASE_API_KEY || "AIzaSyCEPDGVBsVyub1BOzUKy5af7rbpCHXidWg";
const FIREBASE_AUTH_ENDPOINT = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;

const db = admin.firestore();

interface FirebaseAuthResponse {
  idToken: string;
  refreshToken: string;
  expiresIn: string;
  localId: string;
  displayName?: string;
  email?: string;
}

async function signInWithEmailPassword(email: string, password: string): Promise<FirebaseAuthResponse> {
  const body = JSON.stringify({
    email,
    password,
    returnSecureToken: true,
  });

  return new Promise((resolve, reject) => {
    const req = https.request(FIREBASE_AUTH_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    }, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        try {
          const json = JSON.parse(data) as any;
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            resolve(json as FirebaseAuthResponse);
          } else {
            const message = json?.error?.message || `Authentication failed with status ${res.statusCode}`;
            reject(new Error(message));
          }
        } catch (error) {
          reject(error);
        }
      });
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

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

    // Sign in the user with Firebase Auth using the email/password REST endpoint
    try {
      const authResult = await signInWithEmailPassword(email, password);
      const uid = authResult.localId;

      // Fetch the user profile from Firestore
      const userDoc = await db.collection("users").doc(uid).get();

      if (!userDoc.exists) {
        return res.status(404).json({ error: "User not found" });
      }

      // Get the user data with proper types
      const userData = userDoc.data() as any;
      const createdAt = userData.createdAt && typeof userData.createdAt.toDate === "function" ?
        userData.createdAt.toDate().toISOString() :
        typeof userData.createdAt === "string" ?
          userData.createdAt :
          new Date().toISOString();

      res.status(200).json({
        token: authResult.idToken,
        user: {
          id: uid,
          name: userData.name || "",
          email: userData.email || "",
          profileImageUrl: userData.profileImageUrl || "",
          ratingAverage: userData.ratingAverage || 0,
          createdAt,
        },
      });
    } catch (authError) {
      logger.error("Authentication error", authError);
      if (authError instanceof Error) {
        if (authError.message.includes("USER_DISABLED")) {
          return res.status(401).json({ error: "User account disabled" });
        }
        if (authError.message.includes("INVALID_PASSWORD") || authError.message.includes("EMAIL_NOT_FOUND") || authError.message.includes("USER_DISABLED")) {
          return res.status(401).json({ error: "Invalid email or password" });
        }
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

    const uidRaw = req.query.uid ?? req.params.uid;
    const uid = Array.isArray(uidRaw) ? uidRaw[0] : uidRaw;

    if (!uid || typeof uid !== "string") {
      return res.status(400).json({ error: "User ID is required (uid query parameter)" });
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

    const uidRaw = req.query.uid ?? req.params.uid;
    const uid = Array.isArray(uidRaw) ? uidRaw[0] : uidRaw;
    const { name, profileImageUrl } = req.body;

    if (!uid || typeof uid !== "string") {
      return res.status(400).json({ error: "User ID is required (uid query parameter)" });
    }

    if (name === undefined && profileImageUrl === undefined) {
      return res.status(400).json({ error: "At least one of name or profileImageUrl must be provided" });
    }

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Authorization token required" });
    }

    let tokenUid: string;
    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split("Bearer ")[1]);
      tokenUid = decoded.uid;
    } catch (error) {
      logger.error("Invalid token for profile update", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    if (tokenUid !== uid) {
      return res.status(403).json({ error: "You can only update your own profile" });
    }

    // Update the user in Firestore (email is not changed via this API)
    const updates: any = {};
    if (name !== undefined) {
      updates.name = name;
    }
    if (profileImageUrl !== undefined && typeof profileImageUrl === "string") {
      updates.profileImageUrl = profileImageUrl;
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
    const savedProfileImageUrl = userData.profileImageUrl || "";

    res.status(200).json({
      id: uid,
      name: userData.name || "",
      email: userData.email || "",
      profileImageUrl: savedProfileImageUrl,
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
      const authError = error as { code?: string; message?: string };
      if (authError.code !== "auth/user-not-found" && authError.code !== "USER_NOT_FOUND") {
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

    // Sign in the newly created user to generate an ID token
    const authResult = await signInWithEmailPassword(email, password);

    const createdAt = new Date().toISOString();

    // Return the response in the expected format
    res.status(201).json({
      token: authResult.idToken,
      user: {
        id: uid,
        name,
        email,
        profileImageUrl: "",
        ratingAverage: 0.0,
        createdAt,
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
