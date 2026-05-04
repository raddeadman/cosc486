# Backend API Requirements

This document lists the backend endpoints needed by the current frontend, the data sent/received, and the frontend functions that should call each endpoint.

Base URL (example): `https://api.example.com/v1`

## Cloud Functions (this repo)

The iOS app calls HTTPS Cloud Functions on `https://us-central1-openmarketmobile.cloudfunctions.net` (see each `*Service.swift`). Names below are the deployed function paths (not the REST-style paths in older sections).

| Function | Method | Notes |
|----------|--------|--------|
| `submitPlaceholderProduct` | POST | Body includes `priceText`, optional `imageUrls` string array |
| `fetchProducts` | GET | Returns **available** products only (`isAvailable !== false`); optional `reviewAverage`, `reviewCount`; `sort=rating` uses review averages |
| `fetchMyProducts` | GET | Bearer required; all products for token’s `sellerId` (including unavailable) |
| `updateProductAvailability` | PATCH | Query `productId`; body `{ "isAvailable" }`; seller from token must own product |
| `fetchUserProfile` | GET | Query **`uid`** (required) |
| `updateUserProfile` | PATCH | Query **`uid`**; Bearer required; token `uid` must match; body `name` and/or `profileImageUrl` (email not updated) |
| `fetchFavoriteProducts` | GET | Bearer required |
| `addFavorite` / `removeFavorite` | POST / DELETE | Body `{ "productId" }` |
| `getOrCreateChat` | POST | Body `buyerId`, `sellerId`, `productId` |
| `fetchChats` | GET | Chat may include `chatStatus`, `resolvedAt`, `resolvedBy` |
| `fetchMessages` | GET | Query `chatId` |
| `sendMessage` | POST | Returns 409 if chat is `resolved` |
| `resolveChat` | POST | Body `{ "chatId" }`; seller only |
| `fetchReviews` | GET | Query `sellerId`; any signed-in user |
| `fetchProductReviews` | GET | Query `productId`; signed-in user |
| `addReview` | POST | Body `productId`, `sellerId`, `rating` (1–5 int), `comment`; reviewer from token; requires prior chat participation |
| `uploadImageData` | POST | Multipart field `file` |

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

### `GET /users/{uid}` (implemented as `fetchUserProfile?uid=`)
- **Used by function:** `AuthService.fetchUserProfile(uid:)`
- **Query params:** `uid` (required)
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

### `PATCH /users/{uid}` (implemented as `updateUserProfile?uid=`)
- **Used by function:** `AuthService.updateUserProfile(name:profileImageUrl:uid:)`
- **Headers:** `Authorization: Bearer <token>` (required; must match `uid`)
- **Query params:** `uid` (required)
- **Request body (at least one field):**
```json
{
  "name": "Sara Ali",
  "profileImageUrl": "https://firebasestorage.googleapis.com/..."
}
```
- **Response body:** updated user object (same shape as above). Email is not modified by this endpoint.

## 3) Products

### `GET /products`
- **Used by function:** `ProductService.fetchProducts()`
- **Query params (recommended):**
  - `search` (String)
  - `category` (String)
  - `sort` (`date` | `price` | `rating` — **rating** sorts by `reviewAverage`, then `reviewCount`, then `createdAt`)
  - `lat`, `lng`, `radiusKm` (optional for nearby/map views)
- **Response body:** array of **available** product objects only
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
    "reviewAverage": 4.5,
    "reviewCount": 12,
    "isAvailable": true,
    "createdAt": "2026-04-30T08:00:00Z"
  }
]
```

### `POST /products`
- **Used by function:** `ProductService.submitPlaceholderProduct(title:description:category:priceText:locationName:latitude:longitude:imageUrls:)`
- **Request body:**
```json
{
  "title": "Road Bike 700C",
  "description": "Aluminum frame road bike.",
  "category": "Sports",
  "priceText": "155",
  "locationName": "Hamad Town",
  "latitude": 26.1153,
  "longitude": 50.5060,
  "imageUrls": ["https://cdn.example.com/p1-1.jpg"]
}
```
- **Response body:** created product object

### `PATCH .../updateProductAvailability?productId=`
- **Used by function:** `ProductService.updateProductAvailability(productId:userId:isAvailable:)`
- **Headers:** `Authorization: Bearer <token>` (seller UID derived from token; must own product)
- **Query params:** `productId` (required; may alternatively be sent in JSON body)
- **Request body:**
```json
{
  "isAvailable": false
}
```
- **Response body:** updated product object

### `GET /fetchMyProducts`
- **Used by function:** `ProductService.fetchMyProducts()`
- **Headers:** `Authorization: Bearer <token>`
- **Response body:** array of all products where `sellerId` equals the authenticated user (includes unavailable)

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
    "updatedAt": "2026-04-30T08:00:00Z",
    "chatStatus": "open",
    "resolvedAt": null,
    "resolvedBy": null
  }
]
```

### `POST /chats/{chatId}/resolve` (implemented as `resolveChat`)

- **Used by function:** `ChatService.resolveChat(chatId:)`
- **Headers:** `Authorization: Bearer <token>`
- **Request body:** `{ "chatId": "chat-1" }`
- **Response body:** updated chat object (`chatStatus` becomes `resolved` for seller after sale)

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
- **Headers:** `Authorization: Bearer <token>`
- **Query params:** `sellerId`
- **Response body:** array of review objects (may include `productId`)

### `GET /reviews?productId={productId}` (implemented as `fetchProductReviews`)

- **Used by function:** `ReviewService.fetchProductReviews(productId:)`
- **Headers:** `Authorization: Bearer <token>`
- **Query params:** `productId`
- **Response body:** array of review objects for that listing

### `POST /reviews`
- **Used by function:** `ReviewService.addReview(productId:sellerId:rating:comment:)` (Cloud Function `addReview`)
- **Headers:** `Authorization: Bearer <token>`
- **Request body:**
```json
{
  "productId": "p1",
  "sellerId": "u1",
  "rating": 5,
  "comment": "Great seller and fast response."
}
```
- **Server:** `reviewerId` is taken from the ID token (body `reviewerId` is ignored). Caller must have participated in a chat for `productId` with `sellerId`.
- **Response body:** created review object

## 7) Media Uploads

### `POST /uploads/images` (implemented as `uploadImageData`)
- **Used by function:** `StorageService.uploadImageData(file:fileName:)`
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
- `ProductService.fetchMyProducts`
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
- `ReviewService.fetchProductReviews`
- `ReviewService.addReview`
- `ChatService.resolveChat`
- `StorageService.uploadImageData`
