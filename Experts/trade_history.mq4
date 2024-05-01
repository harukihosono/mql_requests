// 著作権表記とその他のMQL4ヘッダープロパティ
#property copyright "Copyright © 2019-2021 Artem Maltsev (Vivazzi)"
#property link      "https://vivazzi.pro"
#property strict

#include <requests/requests.mqh>

// 日時を文字列に変換する関数（カスタムフォーマット）
string DateTimeToString(datetime time) {
    MqlDateTime mdt;
    TimeToStruct(time, mdt);
    return(StringFormat("%04d.%02d.%02d %02d:%02d:%02d", mdt.year, mdt.mon, mdt.day, mdt.hour, mdt.min, mdt.sec));
}

// CSV形式でデータを生成する関数
string PrepareCsvData(int start, int end) {
    string csv = "Ticket,OpenTime,OpenPrice,Type,Lots,Symbol,StopLoss,TakeProfit,CloseTime,ClosePrice,Commission,Swap,Profit,MagicNumber\n";
    for (int i = start; i < end && i < OrdersHistoryTotal(); i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
            if (OrderClosePrice() == 0) continue; // If the close price is zero, skip this record.
            csv += StringFormat("%d,%s,%f,%d,%f,%s,%f,%f,%s,%f,%f,%f,%f,%f,%d\n",
                                OrderTicket(),
                                DateTimeToString(OrderOpenTime()),
                                OrderOpenPrice(),
                                OrderType(),
                                OrderLots(),
                                OrderSymbol(),
                                OrderStopLoss(),
                                OrderTakeProfit(),
                                DateTimeToString(OrderCloseTime()),
                                OrderClosePrice(),
                                OrderCommission(),
                                OrderSwap(),
                                OrderProfit(),
                                OrderMagicNumber());
        }
    }
    return csv;
}

// OnInit関数でHTTP POSTを実行
int OnInit() {
    const int batchSize = 1000; // バッチサイズ
    int totalOrders = OrdersHistoryTotal();
    
    for (int i = 0; i < totalOrders; i += batchSize) {
        string csv_data = PrepareCsvData(i, i + batchSize); // CSVデータを作成
        Print("バッチ ", i / batchSize, " のCSVデータを生成しました。");

        // CSVデータをPOST
        Requests requests;
        string server_url = "http://localhost/"; // 送信先URL
        Response response = requests.post(server_url, csv_data); // 'post'メソッドでテキストコンテンツを扱うと仮定

        Print("バッチ ", i / batchSize, " のPOSTレスポンス: ", response.text);
        if (StringFind(response.text, "413 Request Entity Too Large") >= 0) {
            Print("バッチサイズが大きすぎます。バッチサイズをさらに小さくしてください。");
            break;
        }
    }
    

    return(INIT_SUCCEEDED);
}
