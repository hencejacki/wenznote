import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:wenznote/model/card/po/card_po.dart';
import 'package:wenznote/model/card/po/card_set_po.dart';
import 'package:wenznote/model/card/po/card_study_config_po.dart';
import 'package:wenznote/service/isar/isar_service_mixin.dart';
import 'package:wenznote/service/service_manager.dart';

class CardService with IsarServiceMixin {
  @override
  ServiceManager serviceManager;

  CardService(this.serviceManager);

  Future<List<CardSetPO>> queryCardSetList() async {
    return documentIsar.cardSetPOs.where().findAll();
  }

  Future<void> createCardSet(CardSetPO cardSet) async {
    cardSet.updateTime = DateTime.now().millisecondsSinceEpoch;
    cardSet.createTime = DateTime.now().millisecondsSinceEpoch;
    cardSet.uuid = const Uuid().v1();
    cardSet.color ??= generatorRandomColor().value;
    var cardSetConfig = CardStudyConfigPO();
    cardSetConfig.cardSetId = cardSet.uuid;
    cardSetConfig.dailyReviewCount = 30;
    cardSetConfig.dailyStudyCount = 30;
    await upsertDbDelta(
        dataId: cardSet.uuid!,
        dataType: "cardSet",
        properties: cardSet.toMap());
    await upsertDbDelta(
        dataId: cardSet.uuid!,
        dataType: "cardSetConfig",
        properties: cardSetConfig.toMap());
    await documentIsar.writeTxn(() async {
      await documentIsar.cardSetPOs.put(cardSet);
      await documentIsar.cardStudyConfigPOs.put(cardSetConfig);
    });
  }

  Color generatorRandomColor() {
    var colors = [
      Colors.red.shade100,
      Colors.green.shade100,
      Colors.blue.shade100,
      Colors.orange.shade100,
      Colors.pink.shade100,
      Colors.yellow.shade100,
      Colors.cyan.shade100,
      Colors.indigoAccent.shade100,
      Colors.purple.shade100,
    ];
    var index = Random().nextInt(colors.length);
    return colors[index];
  }

  Future<void> deleteCardSet(String? uuid) async {
    if (uuid == null) {
      return;
    }
    await deleteDbDelta([uuid]);
    var cardIds = documentIsar.cardPOs
        .filter()
        .cardSetIdEqualTo(uuid)
        .uuidProperty()
        .findAllSync();
    var configIds = documentIsar.cardStudyConfigPOs
        .filter()
        .cardSetIdEqualTo(uuid)
        .uuidProperty()
        .findAllSync();
    await deleteDbDelta([uuid, ...cardIds, ...configIds]);
    await documentIsar.writeTxn(() async {
      await documentIsar.cardSetPOs.filter().uuidEqualTo(uuid).deleteFirst();
      await documentIsar.cardPOs.filter().cardSetIdEqualTo(uuid).deleteAll();
      await documentIsar.cardStudyConfigPOs
          .filter()
          .cardSetIdEqualTo(uuid)
          .deleteAll();
    });
  }

  Future<void> updateCardSet(CardSetPO cardSet) async {
    cardSet.updateTime = DateTime.now().millisecondsSinceEpoch;
    var oldItem = await documentIsar.cardSetPOs.get(cardSet.id);
    await upsertDbDelta(
        dataId: cardSet.uuid!,
        dataType: "cardSet",
        properties: diffMap(oldItem?.toMap() ?? {}, cardSet.toMap()));
    await documentIsar.writeTxn(() async {
      documentIsar.cardSetPOs.put(cardSet);
    });
  }

  Future<void> createCard(CardPO card) async {
    card.uuid = const Uuid().v1();
    card.createTime = DateTime.now().millisecondsSinceEpoch;
    card.updateTime = DateTime.now().millisecondsSinceEpoch;
    await upsertDbDelta(
        dataId: card.uuid!,
        dataType: "card-${card.cardSetId}",
        properties: card.toMap());
    await documentIsar.writeTxn(() async {
      documentIsar.cardPOs.put(card);
    });
  }

  Future<void> insertCards(String? cardSetId, List<CardPO> cardList) async {
    await upsertDbDeltas(
        dataType: "card-$cardSetId",
        objList: cardList.map((e) => e.toMap()).toList());
    await documentIsar.writeTxn(() async {
      await documentIsar.cardPOs.putAll(cardList);
    });
  }

  Future<List<CardPO>> queryCardList(
      String cardCategory, String? cardSetId) async {
    switch (cardCategory) {
      case "全部":
        return documentIsar.cardPOs
            .filter()
            .cardSetIdEqualTo(cardSetId)
            .findAll();
    }
    return [];
  }

  Future<void> deleteCard(CardPO card) async {
    await deleteDbDelta([card.uuid]);
    await documentIsar.writeTxn(() async {
      documentIsar.cardPOs.delete(card.id);
    });
  }

  Future<void> deleteCardByUuid(String uuid) async {
    await deleteDbDelta([uuid]);
    await documentIsar.writeTxn(() async {
      await documentIsar.cardPOs.filter().uuidEqualTo(uuid).deleteFirst();
    });
  }

  Future<CardPO?> queryCard(String? cardId) async {
    return documentIsar.cardPOs.filter().uuidEqualTo(cardId).findFirst();
  }

  Future<void> updateCard(CardPO card) async {
    var oldItem = await documentIsar.cardPOs.get(card.id);
    await upsertDbDelta(
        dataId: card.uuid!,
        dataType: "card-${card.cardSetId}",
        properties: diffMap(oldItem?.toMap() ?? {}, card.toMap()));
    await documentIsar.writeTxn(() async {
      await documentIsar.cardPOs.put(card);
    });
  }

  Future<CardSetPO?> queryCardSet(String? cardSetId) async {
    return await documentIsar.cardSetPOs
        .filter()
        .uuidEqualTo(cardSetId)
        .findFirst();
  }
}
