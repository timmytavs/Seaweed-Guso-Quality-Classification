from pydantic import (
    BaseModel,
    EmailStr,
    Field,
    model_validator
)


# =====================================================
# REGISTER REQUEST
# =====================================================

class RegisterRequest(BaseModel):

    first_name: str = Field(
        min_length=1,
        max_length=100
    )

    last_name: str = Field(
        min_length=1,
        max_length=100
    )

    email: EmailStr | None = None   

    contact_num: str = Field(
        min_length=7,
        max_length=120
    )

    password: str = Field(
        min_length=8,
        max_length=128
    )

    confirm_password: str = Field(
        min_length=8,
        max_length=128
    )


    @model_validator(mode="after")
    def validate_passwords(self):

        if self.password != self.confirm_password:
            raise ValueError(
                "Passwords do not match."
            )

        return self


# =====================================================
# USER RESPONSE
# =====================================================

class UserResponse(BaseModel):

    user_id: int

    full_name: str

    email: EmailStr | None = None

    contact_num: str

    is_verified: bool


# =====================================================
# REGISTER RESPONSE
# =====================================================

class RegisterResponse(BaseModel):

    message: str

    user: UserResponse
    

# =====================================================
# LOGIN REQUEST
# =====================================================

class LoginRequest(BaseModel):

    identifier: str = Field(
        min_length=1,
        max_length=255
    )

    password: str = Field(
        min_length=1,
        max_length=128
    )


# =====================================================
# LOGIN RESPONSE
# =====================================================

class LoginResponse(BaseModel):

    message: str

    user: UserResponse