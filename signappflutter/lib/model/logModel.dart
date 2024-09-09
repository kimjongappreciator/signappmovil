class logmodel {
  String? date;
  String? log;

  logmodel({this.date, this.log});

  logmodel.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    log = json['log'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['date'] = date;
    data['log'] = log;
    return data;
  }
}