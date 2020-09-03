import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:medico/models/cart.dart';
import 'package:medico/models/diagnolotic.dart';
import 'package:medico/models/medicines.dart';
import 'package:medico/models/server_success.dart';
import 'package:medico/services/shop_use_case.dart';
import 'package:medico/util/server_model.dart';
import 'package:rxdart/rxdart.dart';

class ShopBloc {
  final ShopUseCase shopUseCase;
  ShopBloc(this.shopUseCase);

  final _isSearchController = BehaviorSubject<bool>();

  final _medicineController = BehaviorSubject<ServerModel<List<Medicine>>>();
  List<Medicine> _fullMedicines = [];
  bool isDoctorsFiltered = false;

  final _diagnoloticController =
      BehaviorSubject<ServerModel<List<Diagnolotic>>>();
  List<Diagnolotic> _fullDiagnolotics = [];
  bool isDiagnoloticsFiltered = false;

  final _inAsyncCallController = BehaviorSubject<bool>();

  final _cartController = BehaviorSubject<ServerModel<Cart>>();

  Future<List<ServerModel<List<Medicine>>>> getMedicines(int page) async {
    final List<ServerModel<List<Medicine>>> tempList = [];
    final response = await shopUseCase.getMedicines(page: page);
    if (!response.data.isEmpty) {
      _medicineController.value == null
          ? _medicineController.value = response
          : _medicineController.value.data.addAll(response.data);
      tempList.add(response);
    }
    return tempList;
  }

  void getDiagnolotics() async {
    shopUseCase
        .getDiagnolotics()
        .then((serverModel) => _diagnoloticController.add(serverModel))
        .catchError((serverModel) => _diagnoloticController.add(serverModel));
  }

  void getCart({@required String userId}) async {
    shopUseCase
        .getCart(userId: userId)
        .then((serverModel) => _cartController.add(serverModel))
        .catchError((err) => _cartController.add(err));
  }

  void addMedicineToCart(String userId, Medicine medicine) async {
    _inAsyncCallController.add(true);
    await shopUseCase.addToCart(
      postCart: PostCart(
          userId: userId, itemId: medicine.mongoId, itemType: 'Medicine'),
    );
    ServerModel<Cart> model = _cartController.value;
    if (model.data.medicineList == null) {
      Cart cart = Cart(
        medicineList: [],
        diagnoloticList: model.data.diagnoloticList,
      );
      cart.medicineList.add(medicine);
      model.data = cart;
    } else {
      model.data.medicineList.add(medicine);
    }
    _cartController.add(model);
    _inAsyncCallController.add(false);
  }

  void filterMedicines(String medicineName) {
    if (!isDoctorsFiltered) {
      _fullMedicines = _medicineController.value.data;
      isDoctorsFiltered = true;
    }

    final List<Medicine> filteredMedicines = [];
    _fullMedicines.forEach((medicine) {
      if (medicine.drugName
          .toLowerCase()
          .contains(medicineName.toLowerCase())) {
        filteredMedicines.add(medicine);
      }
    });

    if (medicineName.isEmpty) {
      _medicineController.value = null;
      _isSearchController.add(false);
      isDoctorsFiltered = false;
    } else {
      _medicineController.value.data = filteredMedicines;
      _medicineController.add(_medicineController.value);
      _isSearchController.add(true);
    }
  }

  void filterDiagnolotic(String diagnoloticName) {
    if (!isDiagnoloticsFiltered) {
      _fullDiagnolotics = _diagnoloticController.value.data;
      isDiagnoloticsFiltered = true;
    }

    final List<Diagnolotic> filteredDiagnolotics = [];
    _fullDiagnolotics.forEach((diagnolotic) {
      if (diagnolotic.name
          .toLowerCase()
          .contains(diagnoloticName.toLowerCase())) {
        filteredDiagnolotics.add(diagnolotic);
      }
    });

    if (diagnoloticName.isEmpty) {
      _diagnoloticController.value.data = _fullDiagnolotics;
      _diagnoloticController.add(_diagnoloticController.value);
    } else {
      _diagnoloticController.value.data = filteredDiagnolotics;
      _diagnoloticController.add(_diagnoloticController.value);
    }
  }

  void addDiaognoloticToCart(String userId, Diagnolotic diagnolotic) async {
    _inAsyncCallController.add(true);
    await shopUseCase.addToCart(
      postCart: PostCart(
          userId: userId, itemId: diagnolotic.mongoId, itemType: 'Diagnolotic'),
    );
    ServerModel<Cart> model = _cartController.value;
    if (model.data.diagnoloticList == null) {
      Cart cart = Cart(
        medicineList: model.data.medicineList,
        diagnoloticList: [],
      );
      cart.diagnoloticList.add(diagnolotic);
      model.data = cart;
    } else {
      model.data.diagnoloticList.add(diagnolotic);
    }
    _cartController.add(model);
    _inAsyncCallController.add(false);
  }

  void removeItemFromCart(String userId, String id, String type) async {
    _inAsyncCallController.add(true);

    await shopUseCase.removeFromCart(userId: userId, itemId: id);

    ServerModel<Cart> model = _cartController.value;
    if (type.toLowerCase() == 'Medicine'.toLowerCase()) {
      for (var element in model.data.medicineList) {
        if (element.mongoId == id) {
          model.data.medicineList.remove(element);
          break;
        }
      }
    }

    if (type.toLowerCase() == 'Diagnolotic'.toLowerCase()) {
      for (var element in model.data.diagnoloticList) {
        if (element.mongoId == id) {
          model.data.diagnoloticList.remove(element);
          break;
        }
      }
    }

    _cartController.sink.add(model);

    _inAsyncCallController.add(false);
  }

  void checkout(
      String userId, File file, Function(String) onCheckoutCompleted) async {
    _inAsyncCallController.add(true);

    ServerModel<ServerSuccess> serverModel =
        await shopUseCase.checkout(userId: userId, imageFIle: file);
    _inAsyncCallController.add(false);
    onCheckoutCompleted(serverModel.data.message);
  }

  Stream<ServerModel<List<Medicine>>> get medicineStream =>
      _medicineController.stream;

  Stream<ServerModel<List<Diagnolotic>>> get diagnoloticStream =>
      _diagnoloticController.stream;

  Stream<ServerModel<Cart>> get cartStream => _cartController.stream;

  Stream<bool> get inAsyncCall => _inAsyncCallController.stream;

  Stream<bool> get isSearch => _isSearchController.stream;

  void dispose() {
    _medicineController.close();
    _cartController.close();
    _inAsyncCallController.close();
    _isSearchController.close();
  }
}
