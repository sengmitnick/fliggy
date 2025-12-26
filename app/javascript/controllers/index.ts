import { Application } from "@hotwired/stimulus"

import ThemeController from "./theme_controller"
import DropdownController from "./dropdown_controller"
import SdkIntegrationController from "./sdk_integration_controller"
import ClipboardController from "./clipboard_controller"
import CitySelectorController from "./city_selector_controller"
import FlightSearchController from "./flight_search_controller"
import DatePickerController from "./date_picker_controller"
import BookingController from "./booking_controller"
import PaymentController from "./payment_controller"
import CouponController from "./coupon_controller"
import ComingSoonController from "./coming_soon_controller"
import DestinationController from "./destination_controller"
import RegionSelectorController from "./region_selector_controller"
import ServiceGridController from "./service_grid_controller"

const application = Application.start()

application.register("theme", ThemeController)
application.register("dropdown", DropdownController)
application.register("sdk-integration", SdkIntegrationController)
application.register("clipboard", ClipboardController)
application.register("city-selector", CitySelectorController)
application.register("flight-search", FlightSearchController)
application.register("date-picker", DatePickerController)
application.register("booking", BookingController)
application.register("payment", PaymentController)
application.register("coupon", CouponController)
application.register("coming-soon", ComingSoonController)
application.register("destination", DestinationController)
application.register("region-selector", RegionSelectorController)
application.register("service-grid", ServiceGridController)

window.Stimulus = application
