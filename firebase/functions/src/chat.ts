// ... existing code ...

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Gets or creates a chat between buyer and seller for a product
 */
export const getOrCreateChat = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  try {
    const { buyerId, sellerId, productId } = data;
    const currentUserId = context.auth.uid;

    // Determine who is the current user (buyer or seller)
    let isBuyer = false;
    if (currentUserId === buyerId) {
      isBuyer = true;
    } else if (currentUserId === sellerId) {
      isBuyer = false;
    } else {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You are not part of this chat'
      );
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
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      chatRef = chatDoc;
    } else {
      // Use existing chat
      chatRef = existingChat.docs[0].ref;
    }

    // Update lastMessage timestamp
    await chatRef.update({
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    const chatData = (await chatRef.get()).data();
    return {
      id: chatRef.id,
      ...chatData
    };
  } catch (error) {
    logger.error('Error getting or creating chat', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to process chat request'
    );
  }
});

/**
 * Fetches all chats for the current user
 */
export const fetchChats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  try {
    const userId = context.auth.uid;

    // Get all chats where user is either buyer or seller
    const chatsSnapshot = await db.collection('chats')
      .where('participantIds', 'array-contains', userId)
      .orderBy('updatedAt', 'desc')
      .get();

    const chats = [];
    for (const doc of chatsSnapshot.docs) {
      const chatData = doc.data();
      chats.push({
        id: doc.id,
        ...chatData
      });
    }

    return { chats };
  } catch (error) {
    logger.error('Error fetching chats', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch chats'
    );
  }
});

/**
 * Fetches messages for a specific chat
 */
export const fetchMessages = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  try {
    const { chatId } = data;

    // Verify user has access to this chat
    const chatDoc = await db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Chat not found'
      );
    }

    const chatData = chatDoc.data();
    const currentUserId = context.auth.uid;

    // Check if user is part of this chat
    if (!chatData.participantIds.includes(currentUserId)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You are not authorized to view this chat'
      );
    }

    const messagesSnapshot = await db.collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', 'asc')
      .get();

    const messages = [];
    for (const doc of messagesSnapshot.docs) {
      const messageData = doc.data();
      messages.push({
        id: doc.id,
        ...messageData
      });
    }

    return { messages };
  } catch (error) {
    logger.error('Error fetching messages', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch messages'
    );
  }
});

/**
 * Sends a message in a chat
 */
export const sendMessage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  try {
    const { chatId, text } = data;
    const senderId = context.auth.uid;

    // Verify user has access to this chat
    const chatDoc = await db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Chat not found'
      );
    }

    const chatData = chatDoc.data();

    // Check if user is part of this chat
    if (!chatData.participantIds.includes(senderId)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You are not authorized to send messages in this chat'
      );
    }

    const messageDoc = await db.collection('chats')
      .doc(chatId)
      .collection('messages')
      .add({
        text,
        senderId,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

    // Update chat's lastMessage
    await db.collection('chats').doc(chatId).update({
      lastMessage: text,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    const messageData = (await messageDoc.get()).data();
    return {
      id: messageDoc.id,
      ...messageData
    };
  } catch (error) {
    logger.error('Error sending message', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send message'
    );
  }
});

// ... rest of code ...