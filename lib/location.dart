class Location {
  final int id;
  final String name;
  final String nameAlias;

  Location({
    required this.id,
    required this.name,
    required this.nameAlias,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      nameAlias: json['name_alias'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_alias': nameAlias,
    };
  }
}

