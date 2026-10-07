from pydantic import BaseModel, Field
from typing import Optional

#Schema to store the user's information.
#This is used in the parameters of the API to register a new user.
class UserInfo(BaseModel):
    first_name: str
    last_name: str
    email: str
    password: str

#Schema to update the title of a conversation.
#This is used in the parameters of the API to update the title of a conversation.
class TitleUpdate(BaseModel):
    conversation_id: int
    new_title: str

#Schema to create a new feedback.
#This is used in the parameters of the API to create a new feedback.
#The satisfaction, ease of use, relevance, performance, and design are between 1 and 5.
class FeedbackRequest(BaseModel):
    user_id: str
    satisfaction: int = Field(ge=1, le=5)
    ease_of_use: int = Field(ge=1, le=5)
    relevance: int = Field(ge=1, le=5)
    performance: int = Field(ge=1, le=5)
    design: int = Field(ge=1, le=5)
    comments: Optional[str] = None
