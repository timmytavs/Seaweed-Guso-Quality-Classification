
import os
import ssl
import smtplib

from pathlib import Path
from email.message import EmailMessage
from email.utils import formataddr

from dotenv import load_dotenv


# =====================================================
# LOAD ENVIRONMENT VARIABLES
# =====================================================

BASE_DIR = Path(__file__).resolve().parents[2]

load_dotenv(BASE_DIR / ".env")


# =====================================================
# SEND EMAIL VERIFICATION OTP
# =====================================================

def send_verification_email(
    destination: str,
    code: str
) -> None:

    """
    Sends a 6-digit verification code to a user's email.

    This function is called by otp_service.py.
    """

    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))

    smtp_username = os.getenv("SMTP_USERNAME")
    smtp_password = os.getenv("SMTP_PASSWORD")

    sender_email = os.getenv("SMTP_FROM_EMAIL")
    sender_name = os.getenv(
        "SMTP_FROM_NAME",
        "gUSo Verification"
    )

    # ---------------------------------------------
    # CHECK EMAIL CONFIGURATION
    # ---------------------------------------------

    if not all([
        smtp_host,
        smtp_username,
        smtp_password,
        sender_email,
    ]):
        raise RuntimeError(
            "Email SMTP configuration is incomplete."
        )

    if smtp_port not in (465, 587):
        raise RuntimeError(
            "SMTP port must be 465 or 587."
        )

    # ---------------------------------------------
    # CREATE EMAIL
    # ---------------------------------------------

    message = EmailMessage()

    message["From"] = formataddr(
        (sender_name, sender_email)
    )

    message["To"] = destination

    message["Subject"] = (
        "gUSo - Email Verification Code"
    )

    message.set_content(
        f"""
Welcome to gUSo!

Your email verification code is:

{code}

This code will expire in 5 minutes.

If you did not request this code,
you can safely ignore this email.

For your security, never share this
verification code with anyone.

gUSo Verification System
"""
    )

    # ---------------------------------------------
    # SEND USING SECURE SMTP
    # ---------------------------------------------

    ssl_context = ssl.create_default_context()

    try:

        if smtp_port == 465:

            with smtplib.SMTP_SSL(
                smtp_host,
                smtp_port,
                context=ssl_context,
                timeout=20
            ) as server:

                server.login(
                    smtp_username,
                    smtp_password
                )

                server.send_message(message)

        else:

            with smtplib.SMTP(
                smtp_host,
                smtp_port,
                timeout=20
            ) as server:

                server.ehlo()

                server.starttls(
                    context=ssl_context
                )

                server.ehlo()

                server.login(
                    smtp_username,
                    smtp_password
                )

                server.send_message(message)

    except (smtplib.SMTPException, OSError) as exc:

        print(
            "SMTP ERROR TYPE:",
            type(exc).__name__
        )

        print(
            "SMTP ERROR CODE:",
            getattr(exc, "smtp_code", "N/A")
        )

        raise RuntimeError(
            "Email verification delivery failed."
        ) from exc
