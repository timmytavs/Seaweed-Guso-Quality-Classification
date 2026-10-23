
import os
import re
from pathlib import Path

import requests
from dotenv import load_dotenv


# =====================================================
# FILE 28 — SMS VERIFICATION SERVICE
# Provider: Semaphore Philippines
# =====================================================

BASE_DIR = Path(__file__).resolve().parents[2]

load_dotenv(BASE_DIR / ".env")

SEMAPHORE_OTP_URL = (
    "https://api.semaphore.co/api/v4/otp"
)


# =====================================================
# NORMALIZE PHILIPPINE MOBILE NUMBER
# =====================================================

def normalize_mobile_number(mobile_number: str) -> str:

    if not isinstance(mobile_number, str):
        raise ValueError("Invalid mobile number.")

    number = re.sub(
        r"[\s()-]",
        "",
        mobile_number.strip()
    )

    if number.startswith("+"):
        number = number[1:]

    # Example: 09123456789
    if re.fullmatch(r"09[0-9]{9}", number):
        return "63" + number[1:]

    # Example: 639123456789
    if re.fullmatch(r"639[0-9]{9}", number):
        return number

    # Example: 9123456789
    if re.fullmatch(r"9[0-9]{9}", number):
        return "63" + number

    raise ValueError(
        "Enter a valid Philippine mobile number."
    )


# =====================================================
# SEND 6-DIGIT VERIFICATION CODE
# =====================================================

def send_verification_sms(
    destination: str,
    code: str
) -> None:

    """
    Send an existing 6-digit OTP using Semaphore.

    Called by otp_service.send_verification_otp().
    """

    # Validate the OTP.
    if not isinstance(code, str) or not re.fullmatch(
        r"[0-9]{6}", code
    ):
        raise ValueError(
            "OTP must contain exactly 6 digits."
        )

    # Normalize the recipient number.
    mobile_number = normalize_mobile_number(
        destination
    )

    # Read credentials from backend/.env.
    api_key = os.getenv("SEMAPHORE_API_KEY")
    sender_name = os.getenv(
        "SEMAPHORE_SENDER_NAME",
        ""
    ).strip()

    if not api_key:
        raise RuntimeError(
            "Semaphore API key is not configured."
        )

    # Semaphore replaces {otp} with our own code.
    message = (
        "Your gUSo verification code is {otp}. "
        "Valid for 5 minutes. "
        "Do not share this code."
    )

    payload = {
        "apikey": api_key,
        "number": mobile_number,
        "message": message,
        "code": code,
    }

    # Sender name is optional if the account
    # already has a registered default sender.
    if sender_name:
        payload["sendername"] = sender_name

    # -------------------------------------------------
    # SEND REQUEST TO SEMAPHORE
    # -------------------------------------------------

    try:
        response = requests.post(
            SEMAPHORE_OTP_URL,
            data=payload,
            timeout=(5, 20),
        )

    except requests.RequestException as exc:
        raise RuntimeError(
            "SMS gateway connection failed."
        ) from exc

    # -------------------------------------------------
    # CHECK PROVIDER RESPONSE
    # -------------------------------------------------

    if not response.ok:
        raise RuntimeError(
            "SMS gateway rejected the request "
            f"(HTTP {response.status_code})."
        )

    try:
        result = response.json()
    except ValueError as exc:
        raise RuntimeError(
            "SMS gateway returned an invalid response."
        ) from exc

    if (
        not isinstance(result, list)
        or len(result) != 1
        or not isinstance(result[0], dict)
    ):
        raise RuntimeError(
            "SMS gateway did not confirm acceptance."
        )

    sms_record = result[0]

    sms_status = str(
        sms_record.get("status", "")
    ).lower()

    if (
        not sms_record.get("message_id")
        or sms_status not in {
            "queued",
            "pending",
            "sent",
        }
    ):
        raise RuntimeError(
            "SMS gateway did not accept the message."
        )

    # Success means Semaphore accepted the request.
    # Actual delivery may occur later.
    # Never print or return the OTP.
    return None
