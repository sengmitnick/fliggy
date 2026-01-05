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
// ComingSoonController removed - using window.showToast() instead
import DestinationController from "./destination_controller"
import RegionSelectorController from "./region_selector_controller"
import HotelSearchController from "./hotel_search_controller"
import HotelDetailController from "./hotel_detail_controller"
import ServiceGridController from "./service_grid_controller"
import PassengerSelectorController from "./passenger_selector_controller"
import CabinSelectorController from "./cabin_selector_controller"
import TripTypeController from "./trip_type_controller"
import ReturnDatePickerController from "./return_date_picker_controller"
import RoundTripSelectorController from "./round_trip_selector_controller"
import TrainSearchController from "./train_search_controller"
import TrainListController from "./train_list_controller"
import TrainCitySelectorController from "./train_city_selector_controller"
import InfiniteScrollController from "./infinite_scroll_controller"
import DeepTravelController from "./deep_travel_controller"
import MultiCityController from "./multi_city_controller"
import FlightFilterController from "./flight_filter_controller"
import FlightSortController from "./flight_sort_controller"
import DateLinkController from "./date_link_controller"
import HotelGuestSelectorController from "./hotel_guest_selector_controller"
import HotelDatePickerController from "./hotel_date_picker_controller"
import PaymentModalController from "./payment_modal_controller"
import PaymentConfirmationController from "./payment_confirmation_controller"
import HotelTabsController from "./hotel_tabs_controller"
import HotelTravelerSelectorController from "./hotel_traveler_selector_controller"
import ToastController from "./toast_controller"
import ToastTriggerController from "./toast_trigger_controller"
import HotelBookingController from "./hotel_booking_controller"
import TourDetailController from "./tour_detail_controller"
import CarouselController from "./carousel_controller"
import ScrollSpyController from "./scroll_spy_controller"
import PackageSwitcherController from "./package_switcher_controller"
import BookingModalController from "./booking_modal_controller"
import BottomBarController from "./bottom_bar_controller"
import InsuranceSelectorController from "./insurance_selector_controller"
import TourTravelerSelectorController from "./tour_traveler_selector_controller"

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
// ComingSoonController removed - using window.showToast() instead
application.register("destination", DestinationController)
application.register("region-selector", RegionSelectorController)
application.register("hotel-search", HotelSearchController)
application.register("hotel-detail", HotelDetailController)
application.register("service-grid", ServiceGridController)
application.register("passenger-selector", PassengerSelectorController)
application.register("cabin-selector", CabinSelectorController)
application.register("trip-type", TripTypeController)
application.register("return-date-picker", ReturnDatePickerController)
application.register("round-trip-selector", RoundTripSelectorController)
application.register("train-search", TrainSearchController)
application.register("train-list", TrainListController)
application.register("train-city-selector", TrainCitySelectorController)
application.register("infinite-scroll", InfiniteScrollController)
application.register("deep-travel", DeepTravelController)
application.register("multi-city", MultiCityController)
application.register("flight-filter", FlightFilterController)
application.register("flight-sort", FlightSortController)
application.register("date-link", DateLinkController)
application.register("hotel-guest-selector", HotelGuestSelectorController)
application.register("hotel-date-picker", HotelDatePickerController)
application.register("payment-modal", PaymentModalController)
application.register("payment-confirmation", PaymentConfirmationController)
application.register("hotel-tabs", HotelTabsController)
application.register("hotel-traveler-selector", HotelTravelerSelectorController)
application.register("toast", ToastController)
application.register("toast-trigger", ToastTriggerController)
application.register("hotel-booking", HotelBookingController)
application.register("tour-detail", TourDetailController)
application.register("carousel", CarouselController)
application.register("scroll-spy", ScrollSpyController)
application.register("package-switcher", PackageSwitcherController)
application.register("booking-modal", BookingModalController)
application.register("bottom-bar", BottomBarController)
application.register("insurance-selector", InsuranceSelectorController)
application.register("tour-traveler-selector", TourTravelerSelectorController)

window.Stimulus = application
