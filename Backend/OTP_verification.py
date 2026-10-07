from datetime import datetime, timedelta

#Class to store the OTPs for the users.
class OTPStore:
    otps = {}  # static variable that binds users' email addresses to their OTPs and their expiration times.

    @classmethod
    #Sets the OTP for the user's email address with a default expiry time of 2 minutes.
    def set_otp(cls, email, otp, expiry_minutes=2):
        expiry_time = datetime.now() + timedelta(minutes=expiry_minutes)
        cls.otps[email] = (otp, expiry_time)

    @classmethod
    #Verifies the OTP for the user's email address.
    #Returns the status of the operation.
    #If there is no corresponding entry in the otps dictionary, it returns "OTP not found".
    #If the OTP is expired, it clears the OTP and returns "OTP has expired!".
    #If the OTP is correct, it clears the OTP and returns "OTP verified".
    #If the OTP is incorrect, it returns "Invalid OTP!".
    def verify_otp(cls, email, entered_otp):
        data = cls.otps.get(email)
        if not data:
            return "OTP not found"
        otp, expiry_time = data
        if datetime.now() > expiry_time:
            cls.clear(email)
            return "OTP has expired!"
        if otp == entered_otp:
            cls.clear(email)
            return "OTP verified"
        return "Invalid OTP!"

    @classmethod
    #Clears the OTP for the user's email address.
    def clear(cls, email):
        cls.otps.pop(email, None)
