// Type definitions for all models used in Firebase Functions

import * as admin from "firebase-admin";

export interface Product {
  id: string;
  title: string;
  description: string;
  price: number;
  category: string;
  imageUrls?: string[];
  sellerId: string;
  sellerName: string;
  locationName: string;
  latitude: number;
  longitude: number;
  rating: number;
  isAvailable: boolean;
  createdAt: admin.firestore.Timestamp | Date;
}

export interface Message {
  id: string;
  chatId: string;
  senderId: string;
  text: string;
  timestamp: admin.firestore.Timestamp | Date;
  productId?: string;
}

export interface Review {
  id: string;
  sellerId: string;
  reviewerId: string;
  rating: number;
  comment: string;
  createdAt: admin.firestore.Timestamp | Date;
}

export interface Chat {
  id: string;
  participantIds: string[];
  productId: string;
  lastMessage?: string;
  updatedAt: admin.firestore.Timestamp | Date;
}
