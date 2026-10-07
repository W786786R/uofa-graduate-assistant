import os
import aiosmtplib
from email.message import EmailMessage
from dotenv import load_dotenv

#Load the environment variables that store the email credentials
load_dotenv()


#The function takes in the user's email address and the OTP code and sends the OTP email to the user's email address
async def send_otp_email(to_email: str, otp: str):
    message = EmailMessage()
    message["From"] = os.getenv("EMAIL_USER") #The email address from which the email is sent
    message["To"] = to_email #The email address to which the email is sent
    message["Subject"] = "OTP Code to login to U of A Graduate Application Assistant App" #The subject of the email
    message.set_content(f"""
Hello,

We received a login request for your U of A Graduate Application Assistant account.

Your One-Time Password (OTP) is:

{otp}

Please enter this OTP in the app to complete your login. This code will expire in 2 minutes and should not be shared with anyone.

If you did not attempt to log in, please ignore this email or contact support immediately.

Thank you,  
U of A Graduate Application Assistant Team
"""
) #The content of the email

    #Send the email
    await aiosmtplib.send(
        message,
        hostname=os.getenv("EMAIL_HOST"),
        port=int(os.getenv("EMAIL_PORT")),
        username=os.getenv("EMAIL_USER"),
        password=os.getenv("EMAIL_PASSWORD"),
        start_tls=True,
    )
