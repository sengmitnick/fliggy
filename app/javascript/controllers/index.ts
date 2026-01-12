import { Application } from "@hotwired/stimulus"

import ThemeController from "./theme_controller"
import DropdownController from "./dropdown_controller"
import SdkIntegrationController from "./sdk_integration_controller"
import ClipboardController from "./clipboard_controller"
import CitySelectorController from "./city_selector_controller"
import FlightSearchController from "./flight_search_controller"
import DatePickerController from "./date_picker_controller"
import BookingController from "./booking_controller"
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
import SpecialFlightsFormController from "./special_flights_form_controller"
import TrainBookingController from "./train_booking_controller"
import TrainBookingLockController from "./train_booking_lock_controller"
import TrainSeatSelectorController from "./train_seat_selector_controller"
import TourGroupFilterController from "./tour_group_filter_controller"
import CarRentalTabsController from "./car_rental_tabs_controller"
import HotelPackageSearchController from "./hotel_package_search_controller"
import HotelPackageOrderController from "./hotel_package_order_controller"
import PwaInstallController from "./pwa_install_controller"
import BusDatePickerController from "./bus_date_picker_controller"
import BusTicketSearchController from "./bus_ticket_search_controller"
import BusTicketOrderController from "./bus_ticket_order_controller"
import DeepBookingController from "./deep_booking_controller"
import AbroadRegionSelectorController from "./abroad_region_selector_controller"
import AbroadDatePickerController from "./abroad_date_picker_controller"
import AbroadPassengerSelectorController from "./abroad_passenger_selector_controller"
import AbroadOrderFormController from "./abroad_order_form_controller"
import AbroadTicketSearchController from "./abroad_ticket_search_controller"

const application = Application.start()

application.register("theme", ThemeController)
application.register("dropdown", DropdownController)
application.register("sdk-integration", SdkIntegrationController)
application.register("clipboard", ClipboardController)
application.register("city-selector", CitySelectorController)
application.register("flight-search", FlightSearchController)
application.register("date-picker", DatePickerController)
application.register("booking", BookingController)
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
application.register("special-flights-form", SpecialFlightsFormController)
application.register("train-booking", TrainBookingController)
application.register("train-booking-lock", TrainBookingLockController)
application.register("train-seat-selector", TrainSeatSelectorController)
application.register("tour-group-filter", TourGroupFilterController)
application.register("car-rental-tabs", CarRentalTabsController)
application.register("hotel-package-search", HotelPackageSearchController)
application.register("hotel-package-order", HotelPackageOrderController)
application.register("pwa-install", PwaInstallController)
application.register("bus-date-picker", BusDatePickerController)
application.register("bus-ticket-search", BusTicketSearchController)
application.register("bus-ticket-order", BusTicketOrderController)
application.register("deep-booking", DeepBookingController)
application.register("abroad-region-selector", AbroadRegionSelectorController)
application.register("abroad-date-picker", AbroadDatePickerController)
application.register("abroad-passenger-selector", AbroadPassengerSelectorController)
application.register("abroad-order-form", AbroadOrderFormController)
application.register("abroad-ticket-search", AbroadTicketSearchController)

window.Stimulus = application
