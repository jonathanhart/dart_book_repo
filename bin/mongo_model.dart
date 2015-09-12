library ticket_models;

import 'dart:async';
import "dart:mirrors";
import 'package:mongo_dart/mongo_dart.dart';

import 'mongo_pool.dart';
import 'package:tickets/shared/schemas.dart';
import 'package:connection_pool/connection_pool.dart';

class MongoModel {
  static const String DATABASE_NAME = 'Tickets';
  static const String DATABASE_URL = 'mongodb://127.0.0.1/';
  static const int DATABASE_POOL_SIZE = 10;

  static final MongoDbPool _dbPool = new MongoDbPool(DATABASE_URL + DATABASE_NAME, DATABASE_POOL_SIZE);
  Future<Map> createByItem(BaseDTO item) async {
    assert(item.id == null);
    item.id = new ObjectId(); //Exposed by Mongo Dart Library
    return _dbPool.getConnection().then((ManagedConnection mc) {
      Db db = mc.conn;
      Map aMap = dtoToMongoMap(item);
      DbCollection collection = db.collection(item.collection_key);
      return collection.insert(aMap).then((status) {
        _dbPool.releaseConnection(mc);
        return (status ['ok'] == 1) ? item : _;
      });
    });
  }

  Map dtoToMongoMap(object) {
    Map item = dtoToMap(object);
    // mongo uses an underscore prefix which would act as a private field in dart
    // convert only on write to mongo
    item['_id'] = item['id'];
    item.remove('id');
    return item;
  }

  dynamic getInstance(Type t) {
    MirrorSystem mirrors = currentMirrorSystem();
    LibraryMirror lm = mirrors.libraries.values.firstWhere(
            (LibraryMirror lm) => lm.qualifiedName == new Symbol('ticket_schemas'));
    ClassMirror cm = lm.declarations[new Symbol(t.toString())];
    InstanceMirror im = cm.newInstance(new Symbol(''), []);
    return im.reflectee;
  }

  dynamic mapToDto(cleanObject, Map document) {
    var reflection = reflect(cleanObject);
    document['id'] = document['_id'];
    document.remove('_id');
    document.forEach((k, v) {
      reflection.setField(new Symbol(k), v);
    });
    return cleanObject;
  }

  Map dtoToMap(Object object) {
    var reflection = reflect(object);
    Map target = new Map();
    var type = reflection.type;
    while (type != null) {
      type.declarations.values.forEach((item) {
        if (item is VariableMirror) {
          VariableMirror value = item;
          if (!value.isFinal) {
            target[MirrorSystem.getName(value.simpleName)] = reflection.getField(value.simpleName).reflectee;
          }
        };
      });
      type = type.superclass;
      // get properties from superclass too!
    }

    return target;
  }

  Future<Map> deleteByItem(BaseDTO item) async {
    assert(item.id != null);
    return _dbPool.getConnection().then((ManagedConnection mc) {
      Db database = mc.conn;
      DbCollection collection = database.collection(item.collection_key);
      Map aMap = dtoToMongoMap(item);
      return collection.remove(aMap).then((status) {
        _dbPool.releaseConnection(mc);
        return status;
      });
    });
  }

  Future<Map> updateItem(BaseDTO item) async {
    assert(item.id != null);
    return _dbPool.getConnection().then((ManagedConnection mc) async {
      Db database = mc.conn;
      DbCollection collection = new DbCollection(database, item.collection_key);
      Map selector = {'_id': item.id};
      Map newItem = dtoToMongoMap(item);
      return await collection.update(selector, newItem).then((status) {
        _dbPool.releaseConnection(mc);
        return status;
      });
    });
  }

  Future<List> _getCollection(String collectionName, [Map query = null]) {
    return _dbPool.getConnection().then((ManagedConnection mc) async {
      DbCollection collection = new DbCollection(mc.conn, collectionName);
      return await collection.find(query).toList().then((List<map> maps){
        _dbPool.releaseConnection(mc);
        return maps;
      });
    });
  }

  Future<List> _getCollectionWhere(String collectionName, fieldName, values) {
    return _dbPool.getConnection().then((ManagedConnection mc) async {
      Db database = mc.conn;
      DbCollection collection = new DbCollection(database, collectionName);
      SelectorBuilder builder = where.oneFrom(fieldName, values);
      return await collection.find( builder ).toList().then((map) {
        _dbPool.releaseConnection(mc);
        return map;
      });
    });
  }

  //refresh an item from the database instance
  Future<BaseDTO> readItemByItem(BaseDTO matcher) async {
    assert(matcher.id != null);
    Map query = {'_id': matcher.id};
    BaseDTO bDto;
    return _getCollection(matcher.collection_key, query).then((items) {
      bvo = mapToDto(getInstance(matcher.runtimeType), items.first);
      return bDto;
    });
  }

//acquires a collection of documents based off a type, and field values
  Future<List> readCollectionByTypeWhere(t, fieldName, values) async {
    List list = new List();
    BaseDTO freshInstance = getInstance(t);
    return _getCollectionWhere(freshInstance.collection_key, fieldName, values).then((items) {
      items.forEach((item) {
        list.add(mapToDto(getInstance(t), item));
      });
      return list;
    });
  }

}
