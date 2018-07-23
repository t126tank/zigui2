<?php

class TradeStateEnum {
  const __default = self::OPEN;

  const OPEN = "open";
  const CLOSED = "closed";
}

class TradeOpEnum {
  const __default = self::BUY;

  const BUY = "buy";
  const SELL = "sell";

  public static function opReverse(TradeOpEnum $op) {
    return $op == self::BUY? self::SELL: self::BUY;
  }
}

class TradeCrawler {
  const RANK = "http://abc.com/ifis/hedge/rank.php?num=";
  const TRADEWALL = "http://abc.com/ifis/hedge/tradewall.php?idx=";

  public static function getRank($num) {
    return self::getApiData(self::RANK . $num);
  }

  public static function getTradewall($idx) {
    $infos = array();

    $jsonArr = self::getApiData(self::TRADEWALL . $idx);
    foreach ($jsonArr as $info) {
      if (empty($info['tid']) || $info['price'] == 0 || $info['pair'] == NULL)
        break;

      $infos[] = new TradeInfo($info);
    }

    return $infos;
  }

  private static function getApiData($url) {
    $options = [
      'http' => [
        'method'  => 'GET',
        'timeout' => 300, // タイムアウト時間
      ]
    ];

    $json = file_get_contents($url, false, stream_context_create($options));

    // もしFalseが返っていたらエラーなので空白配列を返す
    if ($json === false) {
      return [];
    }

    // 200以外のステータスコードは失敗とみなし空配列を返す
    preg_match('/HTTP\/1\.[0|1|x] ([0-9]{3})/', $http_response_header[0], $matches);
    $statusCode = (int)$matches[1];
    if ($statusCode !== 200) {
      return [];
    }

    // 文字列から変換
    $jsonArray = json_decode($json, true);

    return $jsonArray;
  }

  private static function getApiDataCurl($url) {
    $option = [
      CURLOPT_RETURNTRANSFER => true, //文字列として返す
      CURLOPT_TIMEOUT        => 300, // タイムアウト時間
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, $option);

    $json    = curl_exec($ch);
    $info    = curl_getinfo($ch);
    $errorNo = curl_errno($ch);

    // OK以外はエラーなので空白配列を返す
    if ($errorNo !== CURLE_OK) {
      // 詳しくエラーハンドリングしたい場合はerrorNoで確認
      // タイムアウトの場合はCURLE_OPERATION_TIMEDOUT
      return [];
    }

    // 200以外のステータスコードは失敗とみなし空配列を返す
    if ($info['http_code'] !== 200) {
      return [];
    }

    // 文字列から変換
    $jsonArray = json_decode($json, true);

    return $jsonArray;
  }
}
?>
