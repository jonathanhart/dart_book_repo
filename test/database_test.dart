import 'package:guinness/guinness.dart'; //test framework
import 'package:tickets/shared/schemas.dart'; //test dtos
import 'package:tickets/db/seeder.dart'; //json file
import '../bin/mongo_model.dart';

main() {

  DbConfigValues config = new DbConfigValues();
  MongoModel model = new MongoModel(config.testDbName, config.testDbURI, config.testDbSize);

  //A Test DTO
  RouteDTO routeDTO = new RouteDTO()
  routeDTO.duration=120..price1=90.00..price2=91.00..price3=95.00..seats=7;
}
