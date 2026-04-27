# QuizBlitz Backend API Specification

This document details the REST endpoints required for the Spring Boot backend to support the QuizBlitz Flutter application. 

The backend should run on `http://localhost:8080`.

## 1. Authentication (`/api/auth`)

### Register
- **Endpoint**: `POST /api/auth/register`
- **Request Body**:
  ```json
  {
    "username": "QuizMaster99",
    "email": "user@example.com",
    "password": "securepassword123"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid-string",
      "username": "QuizMaster99",
      "email": "user@example.com",
      "avatarUrl": null
    }
  }
  ```

### Login
- **Endpoint**: `POST /api/auth/login`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "securepassword123"
  }
  ```
- **Response** `200 OK`: Same as Register.

### Get Current User
- **Endpoint**: `GET /api/auth/me`
- **Headers**: `Authorization: Bearer <token>`
- **Response** `200 OK`: User object (same as `user` in Login response).

---

## 2. Quizzes (`/api/quizzes`)
*All endpoints require Bearer Token authorization.*

### Get Public Quizzes
- **Endpoint**: `GET /api/quizzes`
- **Response** `200 OK`:
  ```json
  [
    {
      "id": "uuid-string",
      "title": "World Geography",
      "description": "Test your knowledge of the world!",
      "coverImageUrl": "https://...",
      "authorId": "uuid-string",
      "authorName": "QuizMaster99",
      "isPublic": true,
      "createdAt": "2023-10-27T10:00:00Z",
      "questions": [ /* Optional or omitted for list view */ ]
    }
  ]
  ```

### Get My Quizzes
- **Endpoint**: `GET /api/quizzes/mine`
- **Response** `200 OK`: List of quizzes created by the authenticated user.

### Create Quiz
- **Endpoint**: `POST /api/quizzes`
- **Request Body**:
  ```json
  {
    "title": "World Geography",
    "description": "Test your knowledge!",
    "coverImageUrl": "https://...",
    "isPublic": true,
    "questions": [
      {
        "text": "What is the capital of France?",
        "imageUrl": null,
        "timeLimit": 30,
        "points": 1000,
        "answers": [
          { "text": "Berlin", "isCorrect": false, "color": "#E21B3C" },
          { "text": "Paris", "isCorrect": true, "color": "#1368CE" }
        ]
      }
    ]
  }
  ```
- **Response** `201 Created`: The created quiz object (with generated `id`s for quiz, questions, and answers).

### Get Quiz Details
- **Endpoint**: `GET /api/quizzes/{id}`
- **Response** `200 OK`: The full quiz object including all questions and answers.

### Update Quiz
- **Endpoint**: `PUT /api/quizzes/{id}`
- **Request Body**: The full quiz object to update.
- **Response** `200 OK`: The updated quiz object.

### Delete Quiz
- **Endpoint**: `DELETE /api/quizzes/{id}`
- **Response** `200 OK` or `204 No Content`.

---

## 3. Game Sessions (`/api/games`)
*All endpoints require Bearer Token authorization.*

### Create Game Session (Host)
- **Endpoint**: `POST /api/games/create`
- **Request Body**:
  ```json
  {
    "quizId": "uuid-string"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "sessionId": "uuid-session-string",
    "gamePin": "123456"
  }
  ```

### Join Game Session (Player)
- **Endpoint**: `POST /api/games/join`
- **Request Body**:
  ```json
  {
    "pin": "123456",
    "nickname": "Player1"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "sessionId": "uuid-session-string",
    "playerId": "uuid-player-string"
  }
  ```

### Get Session Details (Polling)
- **Endpoint**: `GET /api/games/{sessionId}`
- **Response** `200 OK`:
  ```json
  {
    "id": "uuid-session-string",
    "quizId": "uuid-string",
    "hostId": "uuid-host-string",
    "gamePin": "123456",
    "status": "LOBBY", // LOBBY, ACTIVE, LEADERBOARD, FINISHED
    "currentQuestionIndex": 0,
    "players": [
      {
        "id": "uuid-player-string",
        "nickname": "Player1",
        "score": 0
      }
    ]
  }
  ```

### Start Game (Host)
- **Endpoint**: `POST /api/games/{sessionId}/start`
- **Response** `200 OK`

### Get Current Question (Host & Player)
- **Endpoint**: `GET /api/games/{sessionId}/current-question`
- **Response** `200 OK`: The current `QuestionModel` object. *(Note: Backend may choose to omit `isCorrect` fields from answers for players, though the app currently expects the standard `QuestionModel`)*.

### Submit Answer (Player)
- **Endpoint**: `POST /api/games/{sessionId}/answer`
- **Request Body**:
  ```json
  {
    "playerId": "uuid-player-string",
    "questionId": "uuid-question-string",
    "answerId": "uuid-answer-string"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "isCorrect": true,
    "pointsEarned": 850
  }
  ```

### Next Question (Host)
- **Endpoint**: `POST /api/games/{sessionId}/next`
- **Response** `200 OK`

### Get Leaderboard (Host & Player)
- **Endpoint**: `GET /api/games/{sessionId}/leaderboard`
- **Response** `200 OK`:
  ```json
  {
    "sessionId": "uuid-session-string",
    "isFinal": false,
    "players": [
      {
        "id": "uuid-player-string",
        "nickname": "Player1",
        "score": 850
      }
    ] // Array should be sorted by score descending
  }
  ```

### Get Final Results
- **Endpoint**: `GET /api/games/{sessionId}/results`
- **Response** `200 OK`: Same structure as Leaderboard, but `isFinal` should be `true`.

---

## 4. User Profile (`/api/users`)
*Requires Bearer Token authorization.*

### Get Profile
- **Endpoint**: `GET /api/users/profile`
- **Response** `200 OK`: User object.

### Update Profile
- **Endpoint**: `PUT /api/users/profile`
- **Request Body**:
  ```json
  {
    "username": "NewUsername",
    "avatarUrl": "https://..." // optional
  }
  ```
- **Response** `200 OK`: Updated User object.
