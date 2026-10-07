from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, ForeignKey, func
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime, UTC

#Path to the database file
DATABASE_URL = "sqlite:///./chat.db"

#Create the engine. Check same thread is set to False for thread safety
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

#Create the session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

#Create the base class
Base = declarative_base()


#Create the user table to store the user's information
#The user's information includes the first name, last name, email, and password
#The email is the primary key
class User(Base):
    __tablename__ = "users"

    first_name = Column(String)
    last_name = Column(String)
    email = Column(String, primary_key=True, index=True)
    password = Column(String)


#Create the conversation table to store the conversation history
#The conversation history includes the user's id, title, and the messages
#The id is the primary key
#The conversation is related to the user by the user's id. A user can have multiple conversations
#The conversation has a cascade delete relationship with the messages to delete all the messages when the conversation is deleted
class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(String, index=True)
    title = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.now(UTC))
    updated_at = Column(DateTime, default=datetime.now(UTC), onupdate=func.now())  # To store the timestamp of the last update so that we can sort the conversations by the last updated time

    messages = relationship("Message", back_populates="conversation", cascade="all, delete")


#Create the message table to store the messages
#The message includes the conversation id, sender, and the message
#The id is the primary key
#The message is related to the conversation by the conversation's id
#A conversation can have multiple messages
class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"))
    sender = Column(String)
    message = Column(Text)
    timestamp = Column(DateTime, default=datetime.now(UTC)) # To store the timestamp of the message and sort the messages by the timestamp

    conversation = relationship("Conversation", back_populates="messages")
    

#Create the feedback table to store the feedback
#The feedback includes the user's id, satisfaction, ease of use, relevance, performance, design, and comments
#The user's id is the primary key
#The feedback is related to the user by the user's id
#A user can have only one feedback and update it later on.
class Feedback(Base):
    __tablename__ = "feedbacks"

    user_id = Column(String, primary_key=True, index=True)
    satisfaction = Column(Integer)
    ease_of_use = Column(Integer)
    relevance = Column(Integer)
    performance = Column(Integer)
    design = Column(Integer)
    comments = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=datetime.now(UTC))

#Create all the tables in the database
Base.metadata.create_all(bind=engine)