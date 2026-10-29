"""Validation schemas for gUSo password-recovery requests.

These schemas validate incoming requests. They do not issue or verify OTPs,
send SMS/email, or update passwords; those operations belong to the service.
"""

from pydantic import (
    BaseModel,
    Field,
    SecretStr,
    field_validator,
    model_validator,
)


class PasswordResetRequest(BaseModel):
    """Request an OTP for an account's verified recovery destination."""

    identifier: str = Field(
        min_length=5,
        max_length=255,
        description="Registered email address or contact number.",
    )

    @field_validator("identifier")
    @classmethod
    def normalize_identifier(cls, value: str) -> str:
        value = value.strip()
        if len(value) < 5:
            raise ValueError("Enter a valid email or contact number.")
        return value


class PasswordResetConfirm(PasswordResetRequest):
    """Verify an OTP and request a password change in one operation."""

    code: str = Field(
        min_length=6,
        max_length=6,
        pattern=r"^\d{6}$",
        repr=False,
        description="Six-digit one-time recovery code.",
    )
    new_password: SecretStr = Field(
        min_length=8,
        max_length=128,
        repr=False,
    )
    confirm_password: SecretStr = Field(
        min_length=8,
        max_length=128,
        repr=False,
    )

    @model_validator(mode="after")
    def passwords_match(self):
        if (
            self.new_password.get_secret_value()
            != self.confirm_password.get_secret_value()
        ):
            raise ValueError("Passwords do not match.")
        return self


class PasswordResetResponse(BaseModel):
    """Public response containing no token, code, or account details."""

    message: str
