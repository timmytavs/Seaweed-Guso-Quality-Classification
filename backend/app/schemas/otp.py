
import re

from pydantic import BaseModel, Field, field_validator


# =====================================================
# FILE 29 — SMS OTP REQUEST / RESPONSE SCHEMAS
# =====================================================


# =====================================================
# REQUEST SMS OTP
# =====================================================

class SmsOtpRequest(BaseModel):

    contact_num: str = Field(
        min_length=10,
        max_length=16,
        description="Registered Philippine mobile number"
    )

    password: str = Field(
        min_length=1,
        max_length=128
    )

    @field_validator("contact_num")
    @classmethod
    def validate_contact_number(cls, value: str):

        number = value.strip()

        valid_patterns = (
            r"09[0-9]{9}",
            r"639[0-9]{9}",
            r"\+639[0-9]{9}",
            r"9[0-9]{9}",
        )

        if not any(
            re.fullmatch(pattern, number)
            for pattern in valid_patterns
        ):
            raise ValueError(
                "Enter a valid Philippine mobile number."
            )

        return number


# =====================================================
# VERIFY SUBMITTED SMS OTP
# =====================================================

class SmsOtpVerifyRequest(SmsOtpRequest):

    code: str = Field(
        min_length=6,
        max_length=6,
        pattern=r"^[0-9]{6}$",
        description="6-digit SMS verification code"
    )


# =====================================================
# SEND OTP RESPONSE
# =====================================================

class SmsOtpSendResponse(BaseModel):

    message: str

    expires_in_minutes: int


# =====================================================
# VERIFY OTP RESPONSE
# =====================================================

class SmsOtpVerifyResponse(BaseModel):

    message: str

    contact_verified: bool

    email_verified: bool

    is_verified: bool
