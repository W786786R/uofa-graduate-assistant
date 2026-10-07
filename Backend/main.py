from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal, User, Conversation, Message, Feedback
from schemas import UserInfo, TitleUpdate, FeedbackRequest
from llama_service import get_llama_response
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, UTC
from email_utils import send_otp_email
import random
from OTP_verification import OTPStore
from fastapi.responses import PlainTextResponse

#Initialize the FastAPI app
app = FastAPI()

#Allow requests from Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#Get the database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

#API to register a new user.
#Receives the user's information as UserInfo schema and adds it to the Users table in the database.
#If the user's email address already exists in the database, it raises a HTTP exception. So two users cannot have the same email address.
@app.post("/register")
def register_user(user: UserInfo, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")

    new_user = User(
        first_name=user.first_name,
        last_name=user.last_name,
        email=user.email,
        password=user.password 
    )
    db.add(new_user)
    db.commit()
    return {"message": "User registered successfully"}


#API to start a new conversation.
#Receives the user's ID and adds a new conversation to the Conversations table for the user in the database.
#Returns the conversation ID.
@app.post("/conversations")
def start_conversation(user_id: str, db: Session = Depends(get_db)):
    convo = Conversation(user_id=user_id)
    db.add(convo)
    db.commit()
    db.refresh(convo)
    return {"conversation_id": convo.id}


#API to get all the conversations for a user.
#Receives the user's ID and returns all the conversations for the user in the database.
#The conversations are ordered by the date and time they were last updated.
@app.get("/conversations/{user_id}")
def get_user_conversations(user_id: str, db: Session = Depends(get_db)):
    return db.query(Conversation).filter_by(user_id=user_id).order_by(Conversation.updated_at.desc()).all()


#API to get all the messages for a conversation.
#Receives the conversation ID and returns all the messages for the conversation in the database.
#The messages are ordered by the date and time they were stored in the database.
@app.get("/messages/{conversation_id}")
def get_messages(conversation_id: int, db: Session = Depends(get_db)):
    return db.query(Message).filter_by(conversation_id=conversation_id).order_by(Message.timestamp).all()


#API to update the title of a conversation.
#Receives the conversation ID and the new title and updates the title of the conversation in the database.
#Returns the conversation ID.
@app.put("/conversations/update-title")
def update_conversation_title(update: TitleUpdate, db: Session = Depends(get_db)):
    convo = db.query(Conversation).filter_by(id=update.conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    convo.title = update.new_title.strip()
    db.commit()
    return {"message": "Title updated successfully", "conversation_id": convo.id}


#API to send a message to a conversation.
#Receives the conversation ID, the sender (user or bot), and the message. The sender is usually always the user.
#At first, We receive the the user's message and store it in the Messages table in the database.
#Second, we send the user's message to the RAG pipeline to get the llama 3.2 response.
#Third, we store the llama 3.2 response in the Messages table in the database.
#Fourth, we update the updated_at field of the conversation in the database.
#Finally, we return the user's message and the llama 3.2 response. User's message is kind of optional here. We had different plans for the user's message.
@app.post("/messages/send")
def send_message_to_conversation(data: dict, db: Session = Depends(get_db)):
    
    #Deconstruct the data
    conversation_id = data["conversation_id"]
    sender = data["sender"]
    message = data["message"]

    #Store the user's message in the Messages table
    user_msg = Message(
        conversation_id=conversation_id,
        sender=sender,
        message=message,
    )
    db.add(user_msg)
    db.commit()
    db.refresh(user_msg)


    bot_reply = get_llama_response(current_user_message=user_msg)


    # Store the bot's reply in the Messages table
    bot_msg = Message(
        conversation_id=conversation_id,
        sender="bot",
        message=bot_reply,
    )
    db.add(bot_msg)
    db.commit()
    db.refresh(bot_msg)

    #Update the updated_at field of the conversation in the database
    conversation = db.query(Conversation).filter_by(id=conversation_id).first()
    if conversation:
        conversation.updated_at = datetime.now(UTC)
        db.commit()

    #Return the user's message and the llama 3.2 response
    return {
        "status": "sent",
        "user_message": {
            "id": user_msg.id,
            "message": user_msg.message,
            "timestamp": user_msg.timestamp.isoformat(),
        },
        "bot_message": {
            "id": bot_msg.id,
            "message": bot_msg.message,
            "timestamp": bot_msg.timestamp.isoformat(),
        } if bot_msg else None
    }


#API to delete a conversation.
#Receives the conversation ID and deletes the conversation from the Conversations table in the database.
#When a conversation is deleted, all the messages in the conversation are also deleted.
#Returns the status of the operation.
@app.delete("/conversations/{conversation_id}")
def delete_conversation(conversation_id: int, db: Session = Depends(get_db)):
    convo = db.query(Conversation).filter_by(id=conversation_id).first()
    if not convo:
        raise HTTPException(status_code=404, detail="Conversation not found")

    db.delete(convo)
    db.commit()
    return {"status": "deleted"}

@app.get("/search-conversations/{user_id}")


#API to search for conversations based on the search keyword.
#Receives the user's ID and the search keyword and returns all the conversations which have messages that match the search keyword.
#The conversations are ordered by the date and time they were last updated.
@app.get("/search-conversations/{user_id}")
def search_conversations(user_id: str, q: str, db: Session = Depends(get_db)):
    conversations = (
        db.query(Conversation)
        .join(Message)
        .filter(
            Conversation.user_id == user_id,
            Message.message.ilike(f"%{q}%")
        )
        .distinct()
        .order_by(Conversation.updated_at.desc())
        .all()
    )
    return conversations


#API to request a OTP to verify the user's email address.
#Receives the user's email address and password and verifies if the user exists in the database.
#If the user exists, it generates a random 6-digit OTP , binds it to the user's email address and sends it to the user's email address.
#If the user does not exist, it raises a HTTP exception.
#Returns the status of the operation.
@app.post("/request-otp")
async def request_otp(data: dict, db: Session = Depends(get_db)):
    email = data["email"]
    password = data["password"]

    user = db.query(User).filter_by(email=email, password=password).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    otp = str(random.randint(100000, 999999))
    OTPStore.set_otp(email, otp)

    await send_otp_email(email, otp)  # ✅ Send email in background

    return {"message": "OTP sent to your email"}


#API to verify the OTP.
#Receives the user's email address and the OTP and verifies if the OTP is correct.
#If the OTP is correct and it is not expired, it returns the user's email address.
#If the OTP is incorrect, it raises a HTTP exception.
@app.post("/verify-otp")
def verify_otp(data: dict, db: Session = Depends(get_db)):
    email = data["email"]
    otp = data["otp"]

    verification_result = OTPStore.verify_otp(email, otp)

    if verification_result != "OTP verified":
        raise HTTPException(status_code=401, detail=verification_result)

    user = db.query(User).filter_by(email=email).first()
    OTPStore.clear(email)
    
    return {"user_id": user.email}


#API to export a conversation messages.
#Receives the conversation ID and retrieves all of the messages for that conversation from the database.
#Then, it formats the messages returns them as a single string.
@app.get("/conversations/{conversation_id}/messages", response_class=PlainTextResponse)
def export_conversation(conversation_id: int, db: Session = Depends(get_db)):
    messages = (
        db.query(Message)
        .filter_by(conversation_id=conversation_id)
        .order_by(Message.timestamp)
        .all()
    )

    if not messages:
        raise HTTPException(status_code=404, detail="No messages found")

    lines = []
    lines.append("========= Conversation Start =========\n")

    for msg in messages:
        timestamp = msg.timestamp.strftime("%Y-%m-%d %H:%M:%S")
        role = "User" if msg.sender == "user" else "Bot "
        lines.append(f"[{timestamp}] {role:4}: {msg.message}\n")

    lines.append("\n========= Conversation End =========")
    return "\n".join(lines)


#API to submit a feedback.
#Receives the user's ID and the feedback and stores it in the database.
#If the user already has a feedback, it updates the existing feedback.
#If the user does not have a feedback, it creates a new feedback.
#Returns the status of the operation.
@app.post("/submit-feedback")
def submit_feedback(feedback: FeedbackRequest, db: Session = Depends(get_db)):
    existing = db.query(Feedback).filter_by(user_id=feedback.user_id).first()

    if existing:
        # Update existing feedback
        existing.satisfaction = feedback.satisfaction
        existing.ease_of_use = feedback.ease_of_use
        existing.relevance = feedback.relevance
        existing.performance = feedback.performance
        existing.design = feedback.design
        existing.comments = feedback.comments
        existing.timestamp = datetime.now(UTC)
    else:
        # Create new feedback
        new_feedback = Feedback(
            user_id=feedback.user_id,
            satisfaction=feedback.satisfaction,
            ease_of_use=feedback.ease_of_use,
            relevance=feedback.relevance,
            performance=feedback.performance,
            design=feedback.design,
            comments=feedback.comments,
        )
        db.add(new_feedback)

    db.commit()
    return {"message": "Feedback submitted successfully."}


#API to fetch a feedback.
#Receives the user's ID and retrieves the feedback for the user from the database.
#If the user does not have a feedback, it raises a HTTP exception.
#And if the user has a feedback, it returns the feedback.
@app.get("/fetch-feedback/{user_id}")
def get_feedback(user_id: str, db: Session = Depends(get_db)):
    feedback = db.query(Feedback).filter_by(user_id=user_id).first()
    if feedback:
        return {
            "user_id": feedback.user_id,
            "satisfaction": feedback.satisfaction,
            "ease_of_use": feedback.ease_of_use,
            "relevance": feedback.relevance,
            "performance": feedback.performance,
            "design": feedback.design,
            "comments": feedback.comments,
        }
    raise HTTPException(status_code=404, detail="Feedback not found")