import 'package:connection_pool/connection_pool.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:async';

class MongoDbPool extends ConnectionPool<Db> {

  String uri;

  MongoDbPool(String this.uri, int poolSize) : super(poolSize);

  //overrides method in ConnectionPool
  void closeConnection(Db conn) {
    conn.close();
  }

  //overrides method in ConnectionPool
  Future<Db> openNewConnection() {
    var conn = new Db(uri);
    return conn.open().then((_) => conn);
  }
}
