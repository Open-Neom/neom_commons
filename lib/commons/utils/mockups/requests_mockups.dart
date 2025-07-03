
import 'package:neom_core/core/domain/model/app_request.dart';
import 'package:neom_core/core/domain/model/event_offer.dart';
import 'package:neom_core/core/domain/model/instrument.dart';
import 'package:neom_core/core/utils/enums/app_currency.dart';
import 'package:neom_core/core/utils/enums/request_decision.dart';

class RequestsMockups {

  static List<AppRequest> requests = [
    AppRequest(
      id: "1",
      from: "",
      to: "",
      createdTime: 0,
      newOffer: EventOffer(amount: 2500, currency: AppCurrency.mxn),
      message: "Vamos armando algo",
      unread: true,
      eventId: "",
      instrument: Instrument.addBasic("guitar"),
      percentageCoverage: 80,
      requestDecision: RequestDecision.pending,
    ),
    AppRequest(
      id: "2",
      from: "",
      to: "",
      createdTime: 0,
      newOffer: EventOffer(amount: 2500, currency: AppCurrency.mxn),
      message: "Vamos armando algo",
      unread: true,
      eventId: "",
      instrument: Instrument.addBasic("keyboard"),
      percentageCoverage: 80,
      requestDecision: RequestDecision.pending,
    ),
    AppRequest(
      id: "3",
      from: "",
      to: "",
      createdTime: 0,
      newOffer: EventOffer(amount: 2500, currency: AppCurrency.mxn),
      message: "Vamos armando algo",
      unread: true,
      eventId: "",
      instrument: Instrument.addBasic("drums"),
      percentageCoverage: 80,
      requestDecision: RequestDecision.pending,
    ),
    AppRequest(
      id: "4",
      from: "",
      to: "",
      createdTime: 0,
      newOffer: EventOffer(amount: 2500, currency: AppCurrency.mxn),
      message: "Vamos armando algo",
      unread: true,
      eventId: "",
      instrument: Instrument.addBasic("vocal"),
      percentageCoverage: 80,
      requestDecision: RequestDecision.pending,
    ),
  ];

}
