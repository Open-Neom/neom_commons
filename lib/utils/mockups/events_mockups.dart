
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/model/instrument_fulfillment.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'places_mockups.dart';

class EventsMockUps {

  static List<Event> events = [
    Event(
      place: PlacesMockups.places[0],
      coverImgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983-8f5c-4db7-afb3-74ae16c3e48e',
      description: "First Event Yeah",
      name: 'First Event',
      imgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983-8f5c-4db7-afb3-74ae16c3e48e',
      paymentPrice: Price(amount: 2500, currency: AppCurrency.mxn),
      instrumentsFulfillment: [
        InstrumentFulfillment(
            id: "1",
            instrument: Instrument.addBasic("Guitar"),
        )
      ]
    ),
    Event(
      place: PlacesMockups.places[1],
      coverImgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983-8f5c-4db7-afb3-74ae16c3e48e',
      imgUrl: "https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FWarhead%2Fsala1.jpg?alt=media&token=d15f0e22-f31b-49e0-ae13-39f6546c8fd3",
      paymentPrice: Price(amount: 2500, currency: AppCurrency.mxn),
      name: "Salas Efectivas Evento",
      description: "Evento para estrenar las salas",
        instrumentsFulfillment: [
          InstrumentFulfillment(
            id: "1",
            instrument: Instrument.addBasic("Guitar"),
          )
        ]
    ),
    Event(
      place: PlacesMockups.places[0],
      coverImgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983-8f5c-4db7-afb3-74ae16c3e48e',
      description: "First gigEvent Yeah",
      name: 'Second Gig Event',
      imgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983-8f5c-4db7-afb3-74ae16c3e48e',
      paymentPrice: Price(amount: 2500, currency: AppCurrency.mxn),
        instrumentsFulfillment: [
          InstrumentFulfillment(
            id: "1",
            instrument: Instrument.addBasic("Guitar"),
          )
        ]
    ),
    Event(
      place: PlacesMockups.places[1],
      coverImgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983-8f5c-4db7-afb3-74ae16c3e48e',
      imgUrl: "https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FWarhead%2Fsala1.jpg?alt=media&token=d15f0e22-f31b-49e0-ae13-39f6546c8fd3",
      paymentPrice: Price(amount: 2500, currency: AppCurrency.mxn),
      name: "Salas Efectivas Evento",
      description: "Evento para estrenar las salas",
        instrumentsFulfillment: [
          InstrumentFulfillment(
            id: "1",
            instrument: Instrument.addBasic("Guitar"),
          )
        ]
    ),
    Event(
      place: PlacesMockups.places[0],
      coverImgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983-8f5c-4db7-afb3-74ae16c3e48e',
      description: "First gigEvent Yeah",
      name: 'First Gig Event',
      imgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983-8f5c-4db7-afb3-74ae16c3e48e',
      paymentPrice: Price(amount: 2500, currency: AppCurrency.mxn),
        instrumentsFulfillment: [
          InstrumentFulfillment(
            id: "1",
            instrument: Instrument.addBasic("Guitar"),
          )
        ]
    ),
    Event(
      place: PlacesMockups.places[1],
      coverImgUrl: 'https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FSolaz%2Frecepcion.jpg?alt=media&token=144ec983-8f5c-4db7-afb3-74ae16c3e48e',
      imgUrl: "https://firebasestorage.googleapis.com/v0/b/gig-me-out.appspot.com/o/RehearsalRooms%2FMexico%2FWarhead%2Fsala1.jpg?alt=media&token=d15f0e22-f31b-49e0-ae13-39f6546c8fd3",
      paymentPrice: Price(amount: 2500, currency: AppCurrency.mxn),
      name: "Salas Efectivas Evento",
      description: "Evento para estrenar las salas",
        instrumentsFulfillment: [
          InstrumentFulfillment(
            id: "1",
            instrument: Instrument.addBasic("Guitar"),
          )
        ]
    ),
  ];

}
