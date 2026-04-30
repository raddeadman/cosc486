export interface Product {
  id: string;
  title: string;
  description: string;
  price: number;
  category: string;
  imageUrls: string[];
  sellerId: string;
  sellerName: string;
  locationName: string;
  latitude: number;
  longitude: number;
  rating: number;
  createdAt: FirebaseFirestore.Timestamp;
}