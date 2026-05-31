from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from database import engine, get_db, Base
from models import User, Note
from schemas import UserCreate, UserResponse, Token, NoteCreate, NoteUpdate, NoteResponse
from auth import hash_password, verify_password, create_access_token, get_current_user

# ── Create tables ─────────────────────────────────────
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Notes App", version="1.0.0")

# ── Serve static files ────────────────────────────────
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
def serve_index():
    return FileResponse("static/index.html")


# ══════════════════════════════════════════════════════
#  AUTH ROUTES
# ══════════════════════════════════════════════════════

@app.post("/api/register", response_model=UserResponse, status_code=201)
def register(user: UserCreate, db: Session = Depends(get_db)):
    """Create a new user account."""
    existing = db.query(User).filter(User.username == user.username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already taken")

    db_user = User(
        username=user.username,
        hashed_password=hash_password(user.password),
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


@app.post("/api/login", response_model=Token)
def login(user: UserCreate, db: Session = Depends(get_db)):
    """Authenticate and receive a JWT token."""
    db_user = db.query(User).filter(User.username == user.username).first()
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    token = create_access_token(data={"sub": db_user.username})
    return {"access_token": token, "token_type": "bearer"}


# ══════════════════════════════════════════════════════
#  NOTES CRUD
# ══════════════════════════════════════════════════════

@app.post("/api/notes", response_model=NoteResponse, status_code=201)
def create_note(
    note: NoteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new note for the authenticated user."""
    db_note = Note(
        title=note.title,
        content=note.content,
        owner_id=current_user.id,
    )
    db.add(db_note)
    db.commit()
    db.refresh(db_note)
    return db_note


@app.get("/api/notes", response_model=list[NoteResponse])
def read_notes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get all notes for the authenticated user."""
    return (
        db.query(Note)
        .filter(Note.owner_id == current_user.id)
        .order_by(Note.updated_at.desc())
        .all()
    )


@app.get("/api/notes/{note_id}", response_model=NoteResponse)
def read_note(
    note_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single note by ID."""
    note = (
        db.query(Note)
        .filter(Note.id == note_id, Note.owner_id == current_user.id)
        .first()
    )
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return note


@app.put("/api/notes/{note_id}", response_model=NoteResponse)
def update_note(
    note_id: int,
    note_update: NoteUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update an existing note."""
    note = (
        db.query(Note)
        .filter(Note.id == note_id, Note.owner_id == current_user.id)
        .first()
    )
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")

    if note_update.title is not None:
        note.title = note_update.title
    if note_update.content is not None:
        note.content = note_update.content

    db.commit()
    db.refresh(note)
    return note


@app.delete("/api/notes/{note_id}", status_code=204)
def delete_note(
    note_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a note."""
    note = (
        db.query(Note)
        .filter(Note.id == note_id, Note.owner_id == current_user.id)
        .first()
    )
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")

    db.delete(note)
    db.commit()
