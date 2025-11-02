part of 'internet_status_bloc.dart';

abstract class InternetStatusEvent {}

class InternetStatusBackEvent extends InternetStatusEvent {}

class InternetStatusLostEvent extends InternetStatusEvent {}

class CheckInternetEvent extends InternetStatusEvent {}

