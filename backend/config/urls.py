"""URL map.

Paths follow the structure suggested in section 30. They are proposals in the
specification, not final names -- changing one here is a single edit, but it is
a breaking change for the mobile client, so it belongs in the API contract.
"""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from rest_framework_simplejwt.views import TokenRefreshView

from authentication import views
from orders import views as order_views
from places import views as place_views

urlpatterns = [
    path("admin/", admin.site.urls),

    # Registration
    path(
        "api/auth/register/request-otp",
        views.RegisterRequestOtpView.as_view(),
        name="register-request-otp",
    ),
    path(
        "api/auth/register/verify-otp",
        views.RegisterVerifyOtpView.as_view(),
        name="register-verify-otp",
    ),

    # Login
    path(
        "api/auth/login/request-otp",
        views.LoginRequestOtpView.as_view(),
        name="login-request-otp",
    ),
    path(
        "api/auth/login/verify-otp",
        views.LoginVerifyOtpView.as_view(),
        name="login-verify-otp",
    ),

    # OTP
    path("api/auth/resend-otp", views.ResendOtpView.as_view(), name="resend-otp"),

    # Session
    path("api/auth/token/refresh", TokenRefreshView.as_view(), name="token-refresh"),
    path("api/auth/logout", views.LogoutView.as_view(), name="logout"),
    path("api/auth/me", views.MeView.as_view(), name="me"),

    # Phone number
    path(
        "api/customer/phone/request-change",
        views.PhoneChangeRequestView.as_view(),
        name="phone-request-change",
    ),
    path(
        "api/customer/phone/verify-change",
        views.PhoneChangeVerifyView.as_view(),
        name="phone-verify-change",
    ),

    # Orders
    path(
        "api/orders",
        order_views.OrderListCreateView.as_view(),
        name="order-list-create",
    ),
    path(
        "api/orders/<uuid:order_id>",
        order_views.OrderDetailView.as_view(),
        name="order-detail",
    ),
    path(
        "api/orders/<uuid:order_id>/cancel",
        order_views.OrderCancelView.as_view(),
        name="order-cancel",
    ),
    path(
        "api/orders/<uuid:order_id>/rate",
        order_views.OrderRateView.as_view(),
        name="order-rate",
    ),

    # Places (address search, Google-backed)
    path(
        "api/places/autocomplete",
        place_views.PlacesAutocompleteView.as_view(),
        name="places-autocomplete",
    ),
    path(
        "api/places/details",
        place_views.PlaceDetailsView.as_view(),
        name="places-details",
    ),
    path(
        "api/places/reverse-geocode",
        place_views.ReverseGeocodeView.as_view(),
        name="places-reverse-geocode",
    ),

    # Contract (section 29): the schema the mobile team builds against.
    path("api/schema", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="docs",
    ),
]

if settings.DEBUG:
    # Local disk only in dev (decision: see orders/models.py); production
    # needs real object storage and a real web server in front of it.
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
