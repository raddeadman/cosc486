# Backend API Requirements

This document lists the backend endpoints needed by the current frontend, the data sent/received, and the frontend functions that should call each endpoint.

Base URL (example): `https://api.example.com/v1`

## 1) Auth

### `POST /auth/register`
- **Used by function:** `AuthService.signUp(name:email:password:completion:)`
- **Request body:**
```json
{
  "name": "Sara Ali",
  "email": "sara@example.com",
  "password": "secret123"
}
```
- **Response body:**
```json
{
  "token": "jwt-token",
  "user": {
    "id": "u1",
    "name": "Sara Ali",
    "email": "sara@example.com",
    "profileImageUrl": "",
    "ratingAverage": 0
  }
}
```

### `POST /auth/login`
- **Used by function:** `AuthService.login(email:password:completion:)`
- **Request body:**
```json
{
  "email": "sara@example.com",
  "password": "secret123"
}
```
- **Response body:** same shape as register response (`token` + `user`)

### `POST /auth/logout`
- **Used by function:** `AuthService.logout()`
- **Headers:** `Authorization: Bearer <token>`
- **Request body:** none
- **Response body:** optional `{ "success": true }`

## 2) Users / Profile

### `GET /users/{uid}`
- **Used by function:** `AuthService.fetchUserProfile(uid:)`
- **Path params:** `uid`
- **Response body:**
```json
{
  "id": "u1",
  "name": "Sara Ali",
  "email": "sara@example.com",
  "profileImageUrl": "",
  "ratingAverage": 4.7,
  "createdAt": "2026-04-30T08:00:00Z"
}
```

### `PATCH /users/{uid}`
- **Used by function:** `AuthService.updateUserProfile(name:email:uid:)`
- **Request body:**
```json
{
  "name": "Sara Ali",
  "email": "sara@example.com"
}
```
- **Response body:** updated user object (same shape as above)

## 3) Products

### `GET /products`
- **Used by function:** `ProductService.fetchProducts()`
- **Query params (recommended):**
  - `search` (String)
  - `category` (String)
  - `sort` (`date` | `price` | `rating`)
  - `lat`, `lng`, `radiusKm` (optional for nearby/map views)
- **Response body:** array of product objects
```json
[
  {
    "id": "p1",
    "title": "iPhone 14 Pro",
    "description": "Excellent condition, 256GB.",
    "price": 650,
    "category": "Electronics",
    "imageUrls": ["https://cdn.example.com/p1-1.jpg"],
    "sellerId": "u1",
    "sellerName": "Sara Ali",
    "locationName": "Manama",
    "latitude": 26.2235,
    "longitude": 50.5876,
    "rating": 4.6,
    "isAvailable": true,
    "createdAt": "2026-04-30T08:00:00Z"
  }
]
```

### `POST /products`
- **Used by function:** `ProductService.submitPlaceholderProduct(title:description:category:priceText:locationName:latitude:longitude:)`
- **Request body:**
```json
{
  "title": "Road Bike 700C",
  "description": "Aluminum frame road bike.",
  "category": "Sports",
  "price": 155,
  "isAvailable": true,
  "locationName": "Hamad Town",
  "latitude": 26.1153,
  "longitude": 50.5060
}
```
- **Response body:** created product object

### `PATCH /users/{userId}/products/{productId}/availability`
- **Used by function:** `ProductService.updateProductAvailability(productId:userId:isAvailable:)`
- **Headers:** `Authorization: Bearer <token>`
- **Path params:** `userId`, `productId`
- **Request body:**
```json
{
  "isAvailable": false
}
```
- **Response body:** updated product object

## 4) Favorites

### `GET /users/{userId}/favorites`
- **Used by function:** `FavoritesService.fetchFavoriteProducts(userId:)`
- **Headers:** `Authorization: Bearer <token>`
- **Path params:** `userId`
- **Response body:** array of product objects

### `POST /users/{userId}/favorites`
- **Used by function:** `FavoritesService.addFavorite(productId:userId:)`
- **Headers:** `Authorization: Bearer <token>`
- **Path params:** `userId`
- **Request body:**
```json
{
  "productId": "p1"
}
```
- **Response body:** optional updated favorites list or `{ "success": true }`

### `DELETE /users/{userId}/favorites/{productId}`
- **Used by function:** `FavoritesService.removeFavorite(productId:userId:)`
- **Headers:** `Authorization: Bearer <token>`
- **Path params:** `userId`, `productId`
- **Response body:** optional `{ "success": true }`

## 5) Chat

### `POST /chats`
- **Used by function:** `ChatService.getOrCreateChat(buyerId:sellerId:productId:)`
- **Headers:** `Authorization: Bearer <token>`
- **Purpose:** create or return an existing product-scoped chat between buyer and seller
- **Request body:**
```json
{
  "buyerId": "u2",
  "sellerId": "u1",
  "productId": "p1"
}
```
- **Response body:**
```json
{
  "id": "chat-p1-u1-u2",
  "participantIds": ["u2", "u1"],
  "productId": "p1",
  "lastMessage": "Is this available?",
  "updatedAt": "2026-04-30T08:00:00Z"
}
```

### `GET /chats`
- **Used by function:** `ChatService.fetchChats()`
- **Headers:** `Authorization: Bearer <token>`
- **Response body:** chat list; current frontend expects at least chat IDs
```json
[
  {
    "id": "chat-1",
    "participantIds": ["current-user", "other-user"],
    "productId": "p1",
    "lastMessage": "Is this available?",
    "updatedAt": "2026-04-30T08:00:00Z"
  }
]
```

### `GET /chats/{chatId}/messages`
- **Used by function:** `ChatService.fetchMessages(chatId:)`
- **Path params:** `chatId`
- **Response body:** array of `Message`

### `POST /chats/{chatId}/messages`
- **Used by function:** `ChatService.sendMessage(text:chatId:)`
- **Path params:** `chatId`
- **Request body:**
```json
{
  "text": "Is this still available?"
}
```
- **Response body:** created `Message`

## 6) Reviews

### `GET /reviews?sellerId={sellerId}`
- **Used by function:** `ReviewService.fetchReviews(sellerId:)`
- **Query params:** `sellerId`
- **Response body:** array of review objects

### `POST /reviews`
- **Used by function:** `ReviewService.addReview(_:)`
- **Request body:**
```json
{
  "sellerId": "u1",
  "reviewerId": "u2",
  "rating": 5,
  "comment": "Great seller and fast response."
}
```
- **Response body:** created review object

## 7) Media Uploads

### `POST /uploads/images`
- **Used by function:** `StorageService.uploadImageData(_:)`
- **Content type:** `multipart/form-data`
- **Fields:**
  - `file`: binary image
- **Response body:**
```json
{
  "url": "https://cdn.example.com/images/file.jpg"
}
```

## Suggested DTOs / Function Coverage

Backend should expose models that match these frontend models:
- `User`
- `Product`
- `Message`
- `Review`

Frontend functions that should include network implementations:
- `AuthService.login`
- `AuthService.signUp`
- `AuthService.logout`
- `AuthService.fetchUserProfile`
- `AuthService.updateUserProfile`
- `ProductService.fetchProducts`
- `ProductService.submitPlaceholderProduct`
- `ProductService.updateProductAvailability(productId:userId:isAvailable:)`
- `FavoritesService.fetchFavoriteProducts(userId:)`
- `FavoritesService.addFavorite(productId:userId:)`
- `FavoritesService.removeFavorite(productId:userId:)`
- `ChatService.getOrCreateChat(buyerId:sellerId:productId:)`
- `ChatService.fetchChats`
- `ChatService.fetchMessages`
- `ChatService.sendMessage`
- `ReviewService.fetchReviews`
- `ReviewService.addReview`
- `StorageService.uploadImageData`
