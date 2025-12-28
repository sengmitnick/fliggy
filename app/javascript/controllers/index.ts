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
import PassengerSelectorController from "./passenger_selector_controller"
import CabinSelectorController from "./cabin_selector_controller"
import TripTypeController from "./trip_type_controller"
import ReturnDatePickerController from "./return_date_picker_controller"
import RoundTripSelectorController from "./round_trip_selector_controller"
import TrainSearchController from "./train_search_controller"
import TrainListController from "./train_list_controller"
import TrainCitySelectorController from "./train_city_selector_controller"
import InfiniteScrollController from "./infinite_scroll_controller"

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
application.register("passenger-selector", PassengerSelectorController)
application.register("cabin-selector", CabinSelectorController)
application.register("trip-type", TripTypeController)
application.register("return-date-picker", ReturnDatePickerController)
application.register("round-trip-selector", RoundTripSelectorController)
application.register("train-search", TrainSearchController)
application.register("train-list", TrainListController)
application.register("train-city-selector", TrainCitySelectorController)
application.register("infinite-scroll", InfiniteScrollController)

window.Stimulus = application
