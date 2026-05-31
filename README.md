# 📝 Notes App

A clean, minimal notes application built with **FastAPI**, **PostgreSQL**, and vanilla **HTML/CSS/JS**. Create an account, log in, and manage your notes with full CRUD operations.

![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

- 🔐 **User Authentication** — Register & login with JWT tokens
- 📝 **Create Notes** — Write notes with a title and content
- 📖 **Read Notes** — View all your notes in a responsive card grid
- ✏️ **Update Notes** — Edit any note in a modal dialog
- 🗑️ **Delete Notes** — Remove notes with a confirmation prompt
- 🌙 **Dark Theme** — Sleek dark UI with purple accents and smooth animations
- 📱 **Responsive** — Works on desktop, tablet, and mobile
- 🚀 **Production Ready** — Gunicorn + Nginx + systemd deployment

---

## 🛠️ Tech Stack

| Layer       | Technology                          |
|-------------|-------------------------------------|
| **Backend** | Python 3.10+, FastAPI, SQLAlchemy   |
| **Database**| PostgreSQL (prod) / SQLite (dev)    |
| **Auth**    | JWT (python-jose) + bcrypt          |
| **Server**  | Gunicorn + Uvicorn workers          |
| **Proxy**   | Nginx                               |
| **Frontend**| Vanilla HTML, CSS, JavaScript       |

---

## 📁 Project Structure

```
my-notes-app/
├── main.py              # FastAPI application — all routes
├── models.py            # SQLAlchemy ORM models (User, Note)
├── schemas.py           # Pydantic request/response schemas
├── auth.py              # JWT authentication & password hashing
├── database.py          # Database engine & session setup
├── requirements.txt     # Python dependencies
├── .env.example         # Environment variable template
├── .gitignore           # Git ignore rules
├── static/
│   ├── index.html       # Single-page frontend application
│   └── style.css        # Dark theme stylesheet
└── deploy/
    ├── setup.sh          # One-command EC2 server setup
    ├── notesapp.service  # systemd service file
    └── nginx.conf        # Nginx reverse proxy config
```

---

## 🗄️ Database Schema

### Users Table

| Column          | Type         | Constraints                    |
|-----------------|--------------|--------------------------------|
| `id`            | INTEGER (PK) | Auto-increment, indexed        |
| `username`      | VARCHAR(50)  | Unique, not null, indexed      |
| `hashed_password` | VARCHAR(255) | Not null                     |
| `created_at`    | TIMESTAMP    | Default: current UTC time      |

### Notes Table

| Column       | Type         | Constraints                         |
|--------------|--------------|-------------------------------------|
| `id`         | INTEGER (PK) | Auto-increment, indexed             |
| `title`      | VARCHAR(200) | Not null                            |
| `content`    | TEXT         | Default: empty string               |
| `created_at` | TIMESTAMP    | Default: current UTC time           |
| `updated_at` | TIMESTAMP    | Default: current UTC time, auto-update |
| `owner_id`   | INTEGER (FK) | References `users.id`, not null, CASCADE delete |

### ER Diagram

```
┌──────────────────────┐         ┌──────────────────────┐
│        users         │         │        notes         │
├──────────────────────┤         ├──────────────────────┤
│ id (PK)              │────┐    │ id (PK)              │
│ username (UNIQUE)    │    │    │ title                │
│ hashed_password      │    └───▶│ owner_id (FK)        │
│ created_at           │         │ content              │
└──────────────────────┘         │ created_at           │
                                 │ updated_at           │
                                 └──────────────────────┘
                                     One User → Many Notes
```

### Raw SQL (PostgreSQL)

```sql
CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    username        VARCHAR(50) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    created_at      TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc')
);

CREATE TABLE notes (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(200) NOT NULL,
    content     TEXT DEFAULT '',
    created_at  TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc'),
    updated_at  TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc'),
    owner_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
);
```

---

## 🔌 API Reference

Base URL: `http://localhost:8000/api`

### Authentication

#### Register a new user
```
POST /api/register
```
**Request Body:**
```json
{
  "username": "himanshu",
  "password": "mypassword123"
}
```
**Response (201):**
```json
{
  "id": 1,
  "username": "himanshu",
  "created_at": "2026-05-31T16:00:00"
}
```

#### Login
```
POST /api/login
```
**Request Body:**
```json
{
  "username": "himanshu",
  "password": "mypassword123"
}
```
**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

### Notes (🔒 Requires `Authorization: Bearer <token>`)

#### Create a note
```
POST /api/notes
```
**Request Body:**
```json
{
  "title": "My First Note",
  "content": "This is the content of my note."
}
```
**Response (201):**
```json
{
  "id": 1,
  "title": "My First Note",
  "content": "This is the content of my note.",
  "created_at": "2026-05-31T16:00:00",
  "updated_at": "2026-05-31T16:00:00"
}
```

#### Get all notes
```
GET /api/notes
```
**Response (200):** Array of note objects (sorted by most recently updated)

#### Get a single note
```
GET /api/notes/{note_id}
```
**Response (200):** Single note object

#### Update a note
```
PUT /api/notes/{note_id}
```
**Request Body** (all fields optional):
```json
{
  "title": "Updated Title",
  "content": "Updated content."
}
```
**Response (200):** Updated note object

#### Delete a note
```
DELETE /api/notes/{note_id}
```
**Response (204):** No content

---

## 🚀 Local Development Setup

### Prerequisites
- Python 3.10 or higher
- Git

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Mr-Himanshu-SenSei/my-notes-app.git
cd my-notes-app

# 2. Create a virtual environment
python -m venv venv

# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up environment variables
cp .env.example .env
# Edit .env if needed (SQLite is the default for local dev)

# 5. Run the development server
uvicorn main:app --reload

# 6. Open in browser
# App:  http://127.0.0.1:8000
# Docs: http://127.0.0.1:8000/docs  (Swagger UI)
```

---

## ☁️ Production Deployment (AWS EC2)

### Prerequisites
- AWS account with an EC2 instance (Ubuntu 22.04/24.04, t2.micro free tier)
- Security Group allowing ports: **22** (SSH), **80** (HTTP), **443** (HTTPS)

### One-Command Setup

SSH into your EC2 instance and run:

```bash
# 1. Clone the repo
git clone https://github.com/Mr-Himanshu-SenSei/my-notes-app.git /home/ubuntu/my-notes-app

# 2. Edit the setup script — change DB_PASS to a strong password
nano /home/ubuntu/my-notes-app/deploy/setup.sh

# 3. Run the setup script
chmod +x /home/ubuntu/my-notes-app/deploy/setup.sh
sudo /home/ubuntu/my-notes-app/deploy/setup.sh
```

This script automatically:
- Installs Python, PostgreSQL, Nginx, and Git
- Creates the PostgreSQL database and user
- Sets up a Python virtual environment and installs dependencies
- Generates a secure `SECRET_KEY` and creates the `.env` file
- Configures and starts the systemd service
- Configures and starts Nginx as a reverse proxy

### Verify Deployment

```bash
# Check if the app is running
sudo systemctl status notesapp

# View live logs
sudo journalctl -u notesapp -f

# Test the app
curl http://localhost:8000
```

Visit `http://<your-ec2-public-ip>` in your browser.

### Useful Commands

```bash
sudo systemctl restart notesapp     # Restart the app
sudo systemctl stop notesapp        # Stop the app
sudo systemctl start notesapp       # Start the app
sudo nginx -t                       # Test Nginx config
sudo systemctl restart nginx        # Restart Nginx
tail -f /var/log/notesapp/*.log     # View app logs
```

---

## 🌐 Custom Domain Setup

1. **Purchase a domain** from a registrar (Cloudflare, Namecheap, GoDaddy, etc.)

2. **Add DNS A records** pointing to your EC2 public IP:
   ```
   A    @      → <EC2-Public-IP>
   A    www    → <EC2-Public-IP>
   ```

3. **Update Nginx config** on the server:
   ```bash
   sudo nano /etc/nginx/sites-available/notesapp
   # Change server_name _; to:
   # server_name yourdomain.com www.yourdomain.com;
   sudo nginx -t && sudo systemctl restart nginx
   ```

4. **Enable HTTPS with Let's Encrypt** (free SSL):
   ```bash
   sudo apt install certbot python3-certbot-nginx -y
   sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```

---

## 🔧 Environment Variables

| Variable                    | Description                        | Default                                    |
|-----------------------------|------------------------------------|--------------------------------------------|
| `DATABASE_URL`              | Database connection string         | `sqlite:///./notes.db`                     |
| `SECRET_KEY`                | JWT signing secret                 | `a-very-secret-key-change-this-in-production` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | JWT token lifetime (minutes)     | `60`                                       |

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

## 👤 Author

**Himanshu** — [@Mr-Himanshu-SenSei](https://github.com/Mr-Himanshu-SenSei)
