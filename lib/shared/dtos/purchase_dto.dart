part of ticket_schemas;

@Entity()
class PurchaseDTO extends BaseDTO
{
  String collection_key = "Purchases";
  String firstname;
  String lastname;
  String email;
  int phone;
  String address;
  String flight;
  String transaction;
}
