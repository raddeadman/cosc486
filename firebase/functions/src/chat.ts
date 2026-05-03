import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Gets or creates a chat between buyer and seller for a product
 */
export const getOrCreateChat = functions.https.onRequest(async (req: any, res: any) => {
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
      logger.error("Invalid token for chat", error);
      return res.status(401).json({ error: "Invalid or expired token" });
  }

    const { buyerId, sellerId, productId } = req.body;
    const currentUserId = (await admin.auth().verifyIdToken(idToken)).uid;

    // Determine who is the current user (buyer or seller)
    if (currentUserId === buyerId) {
      // Current user is buyer
    } else if (currentUserId === sellerId) {
      // Current user is seller
    } else {
      return res.status(403).json({ error: "You are not part of this chat" });
    }

    // Check if chat already exists
    const existingChat = await db.collection('chats')
      .where('buyerId', '==', buyerId)
      .where('sellerId', '==', sellerId)
      .where('productId', '==', productId)
      .get();

    let chatRef;
    if (existingChat.empty) {
      // Create new chat
      const chatDoc = await db.collection('chats').add({
        buyerId,
        sellerId,
        productId,
        participantIds: [buyerId, sellerId],
        lastMessage: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      chatRef = chatDoc;
    } else {
      // Use existing chat
      chatRef = existingChat.docs[0].ref;
    }

    // Update lastMessage timestamp
    await chatRef.update({
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const chatData = (await chatRef.get()).data();
    res.status(200).json({
      id: chatRef.id,
      ...chatData,
    });
  } catch (error) {
    logger.error('Error getting or creating chat', error);
    return res.status(500).json({ error: 'Failed to process chat request' });
  }
});

/**
 * Fetches all chats for the current user
 */
export const fetchChats = functions.https.onRequest(async (req: any, res: any) => {
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
      logger.error("Invalid token for fetching chats", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    const userId = (await admin.auth().verifyIdToken(idToken)).uid;

    // Get all chats where user is either buyer or seller
    const chatsSnapshot = await db.collection('chats')
      .where('participantIds', 'array-contains', userId)
      .orderBy('updatedAt', 'desc')
      .get();

    const chats = [];
    for (const doc of chatsSnapshot.docs) {
      const chatData = doc.data() as any;
      chats.push({
        id: doc.id,
        ...chatData,
        createdAt: chatData.createdAt?.toDate().toISOString(),
        updatedAt: chatData.updatedAt?.toDate().toISOString(),
      });
    }

    res.status(200).json(chats);
  } catch (error) {
    logger.error('Error fetching chats', error);
    return res.status(500).json({ error: `Failed to fetch chats: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * Fetches messages for a specific chat
 */
export const fetchMessages = functions.https.onRequest(async (req: any, res: any) => {
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
      logger.error("Invalid token for fetching messages", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    const { chatId } = req.params;

    // Verify user has access to this chat
    const chatDoc = await db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      return res.status(404).json({ error: "Chat not found" });
    }

    const chatData = chatDoc.data() as any;
    const currentUserId = (await admin.auth().verifyIdToken(idToken)).uid;

    // Check if user is part of this chat
    if (!chatData.participantIds.includes(currentUserId)) {
      return res.status(403).json({ error: "You are not authorized to view this chat" });
    }

    const messagesSnapshot = await db.collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', 'asc')
      .get();

    const messages = [];
    for (const doc of messagesSnapshot.docs) {
      const messageData = doc.data() as any;
      messages.push({
        id: doc.id,
        ...messageData,
        createdAt: messageData.createdAt?.toDate().toISOString(),
      });
    }

    res.status(200).json(messages);
  } catch (error) {
    logger.error('Error fetching messages', error);
    return res.status(500).json({ error: `Failed to fetch messages: ${error instanceof Error ? error.message : String(error)}` });
  }
});

/**
 * Sends a message in a chat
 */
export const sendMessage = functions.https.onRequest(async (req: any, res: any) => {
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
      logger.error("Invalid token for sending message", error);
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    const { chatId, text } = req.body;
    const senderId = (await admin.auth().verifyIdToken(idToken)).uid;

    // Verify user has access to this chat
    const chatDoc = await db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      return res.status(404).json({ error: "Chat not found" });
    }

    const chatData = chatDoc.data() as any;

    // Check if user is part of this chat
    if (!chatData.participantIds.includes(senderId)) {
      return res.status(403).json({ error: "You are not authorized to send messages in this chat" });
    }

    const messageDoc = await db.collection('chats')
      .doc(chatId)
      .collection('messages')
      .add({
        text,
        senderId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Update chat's lastMessage
    await db.collection('chats').doc(chatId).update({
      lastMessage: text,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const messageData = (await messageDoc.get()).data() as any;
    res.status(201).json({
      id: messageDoc.id,
      ...messageData,
      createdAt: messageData.createdAt?.toDate().toISOString(),
    });
  } catch (error) {
    logger.error('Error sending message', error);
    return res.status(500).json({ error: `Failed to send message: ${error instanceof Error ? error.message : String(error)}` });
  }
});

