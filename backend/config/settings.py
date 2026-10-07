"""Django settings for the Jihudumie authentication backend.

Every parameter the specification marks as "must not be guessed by individual
developers" (section 43) is read from the environment and surfaced in one
place, so the policy lives in configuration rather than scattered through the
code -- and so the mobile client can be told the values rather than hardcoding
its own copy.
"""

import sys
from datetime import timedelta
from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(
    DEBUG=(bool, False),
    ALLOWED_HOSTS=(list, ["localhost", "127.0.0.1"]),
    OTP_LENGTH=(int, 6),
    OTP_TTL_SECONDS=(int, 300),
    OTP_MAX_ATTEMPTS=(int, 3),
    OTP_RESEND_COOLDOWN_SECONDS=(int, 60),
    OTP_MAX_REQUESTS_PER_HOUR=(int, 5),
    OTP_MAX_SMS_PER_DAY=(int, 15),
    OTP_PEPPER=(str, "insecure-development-pepper"),
    ACCESS_TOKEN_LIFETIME_MINUTES=(int, 15),
    REFRESH_TOKEN_LIFETIME_DAYS=(int, 30),
    PHONE_CHANGE_REVOKES_OTHER_SESSIONS=(bool, True),
    ENFORCE_EMAIL_UNIQUENESS=(bool, False),
    SMS_PROVIDER=(str, "logging"),
    SMS_SENDER_ID=(str, ""),
    SMS_API_TOKEN=(str, ""),
    SMS_BASE_URL=(str, "https://sms.webline.africa/api/http"),
    GOOGLE_PLACES_API_KEY=(str, ""),
    ORDER_MIN_PRICE_TSH=(int, 2000),
    # Placeholder rates -- see orders/pricing.py. No real per-km figure from
    # the client yet; these only preserve the old flat table's ratio.
    ORDER_RATE_PER_KM_MOTORCYCLE_TSH=(int, 500),
    ORDER_RATE_PER_KM_BAJAJI_TSH=(int, 650),
    ORDER_RATE_PER_KM_CAR_TSH=(int, 800),
    ORDER_RATE_PER_KM_VAN_TSH=(int, 1200),
)
environ.Env.read_env(BASE_DIR / ".env")

#: True while `manage.py test` is running. The test runner forces DEBUG off,
#: so the SMS guard consults this as well -- otherwise the in-memory provider
#: the tests depend on would be refused as a production misconfiguration.
TESTING = "test" in sys.argv

SECRET_KEY = env("SECRET_KEY", default="insecure-development-key")
DEBUG = env("DEBUG")
ALLOWED_HOSTS = env("ALLOWED_HOSTS")

#: In development the machine's LAN address changes with DHCP, and a real
#: phone on the same Wi-Fi reaches the API by that address. Rather than chase
#: it in .env every time, accept any Host header while DEBUG is on -- this is
#: never true in production, where ALLOWED_HOSTS stays an explicit list.
if DEBUG:
    ALLOWED_HOSTS = ["*"]

#: The mobile client authenticates with a bearer token, not a cookie, so
#: there is no ambient credential a permissive origin could ride in on --
#: allowing every origin in development just means Flutter web (which picks a
#: fresh localhost port on every `flutter run`) is never blocked from
#: reaching the API. Production still wants a real, explicit list.
CORS_ALLOW_ALL_ORIGINS = DEBUG
CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS", default=[])

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    # Tracks issued refresh tokens so logout and a phone change can actually
    # revoke them. JWTs cannot be withdrawn on their own (section 22, 25).
    "rest_framework_simplejwt.token_blacklist",
    "drf_spectacular",
    "corsheaders",
    "authentication",
    "orders",
    "places",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    # Must run before CommonMiddleware so it can attach CORS headers to every
    # response, including the preflight OPTIONS a browser sends before any
    # POST with a JSON body -- without this, Flutter web's requests never
    # leave the browser and the app reports them as a network failure.
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {"default": env.db("DATABASE_URL")}

# The customer is identified by a phone number and never holds a password, so
# Django's username/password user model does not fit. This must be set before
# the first migration is applied -- changing it afterwards is painful.
AUTH_USER_MODEL = "authentication.Customer"

# No passwords exist in the MVP (section 37), so password validators and
# hashing configuration would be misleading if left in place.
AUTH_PASSWORD_VALIDATORS = []

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Africa/Dar_es_Salaam"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# Package photos, local disk for now (decision: dev only -- production needs
# real object storage, e.g. S3, before launch).
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "EXCEPTION_HANDLER": "authentication.errors.exception_handler",
    "DEFAULT_THROTTLE_RATES": {
        # Per client address. The per-phone caps live in `otp.py`; these stop
        # one machine sweeping across many numbers.
        "otp_request": "20/hour",
        "otp_verify": "30/hour",
    },
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(
        minutes=env("ACCESS_TOKEN_LIFETIME_MINUTES")
    ),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=env("REFRESH_TOKEN_LIFETIME_DAYS")),
    # Rotation plus blacklisting gives reuse detection: a refresh token that is
    # presented twice has been stolen or replayed.
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": True,
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "sub",
    # A little slack for device clocks that drift.
    "LEEWAY": 10,
}

SPECTACULAR_SETTINGS = {
    "TITLE": "Jihudumie Customer Authentication API",
    "DESCRIPTION": "Sprint 1 authentication module.",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
}

# --- Authentication policy (section 43) --------------------------------------
# Grouped so the values the client must be told are visible together.
OTP_LENGTH = env("OTP_LENGTH")
OTP_TTL_SECONDS = env("OTP_TTL_SECONDS")
OTP_MAX_ATTEMPTS = env("OTP_MAX_ATTEMPTS")
OTP_RESEND_COOLDOWN_SECONDS = env("OTP_RESEND_COOLDOWN_SECONDS")
OTP_MAX_REQUESTS_PER_HOUR = env("OTP_MAX_REQUESTS_PER_HOUR")
OTP_MAX_SMS_PER_DAY = env("OTP_MAX_SMS_PER_DAY")
OTP_PEPPER = env("OTP_PEPPER")

PHONE_CHANGE_REVOKES_OTHER_SESSIONS = env("PHONE_CHANGE_REVOKES_OTHER_SESSIONS")
ENFORCE_EMAIL_UNIQUENESS = env("ENFORCE_EMAIL_UNIQUENESS")

SMS_PROVIDER = env("SMS_PROVIDER")
SMS_SENDER_ID = env("SMS_SENDER_ID")
SMS_API_TOKEN = env("SMS_API_TOKEN")
SMS_BASE_URL = env("SMS_BASE_URL")

# --- Places search (see places/google_places.py) ------------------------------
GOOGLE_PLACES_API_KEY = env("GOOGLE_PLACES_API_KEY")

# --- Orders pricing (see orders/pricing.py) -----------------------------------
ORDER_MIN_PRICE_TSH = env("ORDER_MIN_PRICE_TSH")
ORDER_RATE_PER_KM_TSH = {
    "MOTORCYCLE": env("ORDER_RATE_PER_KM_MOTORCYCLE_TSH"),
    "BAJAJI": env("ORDER_RATE_PER_KM_BAJAJI_TSH"),
    "CAR": env("ORDER_RATE_PER_KM_CAR_TSH"),
    "VAN": env("ORDER_RATE_PER_KM_VAN_TSH"),
}

# --- Logging -----------------------------------------------------------------
# The masking filter is installed from the start rather than added later:
# section 32 forbids complete OTP values in logs, and phone numbers are
# personal data that should not sit in plain text in a log aggregator.
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "filters": {
        "mask_sensitive": {"()": "authentication.logging.MaskSensitiveFilter"},
    },
    "formatters": {
        "standard": {"format": "%(asctime)s %(levelname)s %(name)s %(message)s"},
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "standard",
            "filters": ["mask_sensitive"],
        },
    },
    "root": {"handlers": ["console"], "level": "INFO"},
}
