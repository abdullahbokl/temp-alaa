import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/subscription_model.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptionsEvent extends SubscriptionEvent {
  const LoadSubscriptionsEvent();
}

class LoadSubscriptionByIdEvent extends SubscriptionEvent {
  final int id;

  const LoadSubscriptionByIdEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class SelectSubscriptionEvent extends SubscriptionEvent {
  final int index;

  const SelectSubscriptionEvent({required this.index});

  @override
  List<Object?> get props => [index];
}

class ApplyPromoCodeEvent extends SubscriptionEvent {
  final String promoCode;

  const ApplyPromoCodeEvent({required this.promoCode});

  @override
  List<Object?> get props => [promoCode];
}

class CreateSubscriptionEvent extends SubscriptionEvent {
  final CreateSubscriptionRequest request;

  const CreateSubscriptionEvent({required this.request});

  @override
  List<Object?> get props => [request];
}

class UpdateSubscriptionEvent extends SubscriptionEvent {
  final int id;
  final UpdateSubscriptionRequest request;

  const UpdateSubscriptionEvent({
    required this.id,
    required this.request,
  });

  @override
  List<Object?> get props => [id, request];
}

class ClearSubscriptionStateEvent extends SubscriptionEvent {
  const ClearSubscriptionStateEvent();
}

class ProcessPaymentEvent extends SubscriptionEvent {
  final PaymentService service;
  final String currency;
  final int? courseId;
  final int? subscriptionId;
  final String phone;
  final String? couponCode;

  const ProcessPaymentEvent({
    required this.service,
    required this.currency,
    this.courseId,
    this.subscriptionId,
    required this.phone,
    this.couponCode,
  });

  @override
  List<Object?> get props => [service, currency, courseId, subscriptionId, phone, couponCode];
}

class VerifyIapReceiptEvent extends SubscriptionEvent {
  final String receiptData;
  final String transactionId;
  final int purchaseId;
  final String store;
  final PurchaseDetails? purchaseDetails;

  VerifyIapReceiptEvent({
    required this.receiptData,
    required this.transactionId,
    required this.purchaseId,
    required this.store,
    this.purchaseDetails,
  });

  @override
  List<Object?> get props => [receiptData, transactionId, purchaseId, store, purchaseDetails];
}

class IapPurchaseUpdatedEvent extends SubscriptionEvent {
  final PurchaseDetails purchase;
  const IapPurchaseUpdatedEvent(this.purchase);

  @override
  List<Object?> get props => [purchase];
}

class IapErrorEvent extends SubscriptionEvent {
  final String error;
  const IapErrorEvent(this.error);

  @override
  List<Object?> get props => [error];
}

