from django.contrib import admin

from .models import Driver, Order


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ["name", "plate", "vehicle", "rating", "active"]
    list_filter = ["vehicle", "active"]
    search_fields = ["name", "plate", "phone_number"]


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    """Driver assignment and stage/status progression are manual for now --
    there is no driver app yet to do either automatically (see
    `services.cancel_order`/`rate_order` for the rules that key off `stage`
    and `status`). `list_editable` makes both a couple of clicks from the
    list view rather than needing the full change form.
    """

    list_display = [
        "order_number",
        "customer",
        "status",
        "stage",
        "driver",
        "vehicle",
        "price_tsh",
        "created_at",
    ]
    list_display_links = ["order_number"]
    list_editable = ["status", "stage", "driver"]
    list_filter = ["status", "stage", "vehicle"]
    search_fields = [
        "order_number",
        "customer__full_name",
        "customer__phone_number",
        "recipient_name",
    ]
    autocomplete_fields = ["driver"]
    date_hierarchy = "created_at"
    readonly_fields = ["id", "order_number", "price_tsh", "created_at", "updated_at"]
