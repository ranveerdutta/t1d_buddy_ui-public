abstract class BaseConfig {
  String get apiHost;
  String get nightscoutHost;
}

class DevConfig implements BaseConfig {
  String get apiHost => "http://154.41.254.114/t1d-buddy";
  String get nightscoutHost => "http://154.41.254.114/t1d-buddy";
}

class ProdConfig implements BaseConfig {
  String get apiHost => "http://154.41.254.114/t1d-buddy";
  String get nightscoutHost => "http://154.41.254.114/t1d-buddy";
}