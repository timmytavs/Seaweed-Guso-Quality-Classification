from pwdlib import PasswordHash


# =====================================================
# PASSWORD HASHER
# =====================================================

password_hasher = PasswordHash.recommended()


# =====================================================
# HASH PASSWORD
# =====================================================

def hash_password(
    password: str
) -> str:

    return password_hasher.hash(
        password
    )


# =====================================================
# VERIFY PASSWORD
# =====================================================

def verify_password(
    plain_password: str,
    hashed_password: str
) -> bool:

    return password_hasher.verify(
        plain_password,
        hashed_password
    )