class Account {
  final String id;
  final String name;
  final int balance;

  Account({
    required this.id,
    required this.name,
    required this.balance,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      balance: json['balance'],
    );
  }

  @override
  String toString() {
    return 'Account{id: $id, name: $name, balance: $balance}';
  }
}
