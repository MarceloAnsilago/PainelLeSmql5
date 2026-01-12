#property strict
#property version   "1.000"

#include <Controls/Dialog.mqh>
#include <Controls/Panel.mqh>
#include <Controls/Label.mqh>
#include <Controls/Edit.mqh>
#include <Controls/Button.mqh>
#include <Trade/Trade.mqh>

input int    InpDeviationPoints = 5;
input int    InpMagic           = 50101;
input string InpComment         = "LongShort";
input int    InpLotMultiple     = 100;
input int    InpPanelExtraHeight = 30;

CAppDialog g_app;
CTrade g_trade;
CPanel g_card;
CLabel g_title;
CLabel g_subtitle;

CPanel g_sell_card;
CPanel g_buy_card;
CLabel g_sell_card_title;
CLabel g_buy_card_title;
CLabel g_sell_price_label;
CLabel g_buy_price_label;
CLabel g_sell_price_value;
CLabel g_buy_price_value;
CLabel g_sell_qty_label;
CLabel g_buy_qty_label;
CEdit  g_sell_qty_input;
CEdit  g_buy_qty_input;
CButton g_sell_qty_up;
CButton g_sell_qty_down;
CButton g_buy_qty_up;
CButton g_buy_qty_down;
CLabel g_sell_total_label;
CLabel g_buy_total_label;
CLabel g_sell_total_value;
CLabel g_buy_total_value;

CLabel g_sell_label;
CEdit  g_sell_input;
CLabel g_buy_label;
CEdit  g_buy_input;
CPanel g_summary_card;
CLabel g_summary_title;
CLabel g_summary_line1;
CLabel g_summary_line2;
CLabel g_summary_line3;

ulong g_sell_ticket = 0;
ulong g_buy_ticket = 0;
double g_sell_entry_price = 0.0;
double g_buy_entry_price = 0.0;

CButton g_show_charts_btn;
CButton g_submit_btn;
CButton g_clear_btn;

bool g_buy_chart_visible = false;
string g_subwindow_shortname = "BuyWindow";
string g_subwindow_indicator = "BuySubWindow";
int g_subwindow_handle = INVALID_HANDLE;
int g_subwindow_number = -1;
string g_buy_chart_object = "buy_chart_object";
string g_sell_entry_line = "sell_entry_line";
string g_sell_current_line = "sell_current_line";
string g_buy_entry_line = "buy_entry_line";
string g_buy_current_line = "buy_current_line";
string g_sell_entry_badge = "sell_entry_badge";
string g_sell_entry_badge_text = "sell_entry_badge_text";
string g_sell_current_badge = "sell_current_badge";
string g_sell_current_badge_text = "sell_current_badge_text";
string g_buy_entry_badge = "buy_entry_badge";
string g_buy_entry_badge_text = "buy_entry_badge_text";
string g_buy_current_badge = "buy_current_badge";
string g_buy_current_badge_text = "buy_current_badge_text";

bool UpdateSymbolPrice(CEdit &field, CLabel &price_out, const bool is_buy)
{
   string sym = NormalizeSymbol(field.Text());
   field.Text(sym);
   if(sym == "")
     {
      price_out.Text("--");
      return(false);
     }

   if(!SymbolSelect(sym, true))
     {
      price_out.Text("--");
      return(false);
     }

   double price = 0.0;
   if(is_buy)
      price = SymbolInfoDouble(sym, SYMBOL_ASK);
   else
      price = SymbolInfoDouble(sym, SYMBOL_BID);
   int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   price_out.Text(FormatMoney(price, digits));
   return(true);
}

bool TryParseDouble(const string text, double &out)
{
   string t = text;
   StringTrimLeft(t);
   StringTrimRight(t);
   StringReplace(t, "R$", "");
   StringReplace(t, " ", "");
   StringTrimLeft(t);
   StringTrimRight(t);
   if(t == "")
      return(false);
   out = StringToDouble(t);
   return(true);
}

string FormatMoney(const double value, const int digits)
{
   return(StringFormat("R$ %.*f", digits, value));
}

string NormalizeSymbol(const string text)
{
   string s = text;
   StringTrimLeft(s);
   StringTrimRight(s);
   StringToUpper(s);
   return(s);
}

void RemoveBuyChartObject()
{
   ObjectDelete(0, g_buy_chart_object);
}

bool EnsureBuySubwindow()
{
   g_subwindow_number = ChartWindowFind(0, g_subwindow_shortname);
   if(g_subwindow_number >= 0)
      return(true);

   g_subwindow_handle = iCustom(_Symbol, _Period, g_subwindow_indicator);
   if(g_subwindow_handle == INVALID_HANDLE)
     {
      Print("Falha ao criar subjanela.");
      return(false);
     }

   g_subwindow_number = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
   if(!ChartIndicatorAdd(0, g_subwindow_number, g_subwindow_handle))
     {
      Print("Falha ao adicionar subjanela.");
      IndicatorRelease(g_subwindow_handle);
      g_subwindow_handle = INVALID_HANDLE;
      g_subwindow_number = -1;
      return(false);
     }

   g_subwindow_number = ChartWindowFind(0, g_subwindow_shortname);
   return(g_subwindow_number >= 0);
}

void RemoveBuySubwindow()
{
   int win = ChartWindowFind(0, g_subwindow_shortname);
   if(win >= 0)
      ChartIndicatorDelete(0, win, g_subwindow_shortname);
   if(g_subwindow_handle != INVALID_HANDLE)
     {
      IndicatorRelease(g_subwindow_handle);
      g_subwindow_handle = INVALID_HANDLE;
     }
   g_subwindow_number = -1;
   ObjectDelete(0, g_buy_current_line);
   ObjectDelete(0, g_buy_entry_line);
   ObjectDelete(0, g_buy_entry_badge);
   ObjectDelete(0, g_buy_entry_badge_text);
   ObjectDelete(0, g_buy_current_badge);
   ObjectDelete(0, g_buy_current_badge_text);
   long buy_chart_id = 0;
   if(ObjectFind(0, g_buy_chart_object) >= 0)
      buy_chart_id = ObjectGetInteger(0, g_buy_chart_object, OBJPROP_CHART_ID);
   if(buy_chart_id > 0)
     {
      ObjectDelete(buy_chart_id, g_buy_current_line);
      ObjectDelete(buy_chart_id, g_buy_entry_line);
      ObjectDelete(buy_chart_id, g_buy_entry_badge);
      ObjectDelete(buy_chart_id, g_buy_entry_badge_text);
      ObjectDelete(buy_chart_id, g_buy_current_badge);
      ObjectDelete(buy_chart_id, g_buy_current_badge_text);
     }
}

bool CreateBuyChartObject(const string sym)
{
   string buy_sym = NormalizeSymbol(sym);
   if(buy_sym == "")
      return(false);
   if(!SymbolSelect(buy_sym, true))
      return(false);
   if(!EnsureBuySubwindow())
      return(false);

   int win = ChartWindowFind(0, g_subwindow_shortname);
   if(win < 0)
      return(false);

   ObjectDelete(0, g_buy_chart_object);
   int width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, win);
   int height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, win);
   if(!ObjectCreate(0, g_buy_chart_object, OBJ_CHART, win, 0, 0))
      return(false);

   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_XDISTANCE, 0);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_YDISTANCE, 0);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_CHART_SCALE, (int)ChartGetInteger(0, CHART_SCALE, 0));
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_DATE_SCALE, false);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_PRICE_SCALE, true);
   ObjectSetString(0, g_buy_chart_object, OBJPROP_SYMBOL, buy_sym);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_PERIOD, Period());
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_BACK, false);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_COLOR, clrWhite);

   long subchart_id = ObjectGetInteger(0, g_buy_chart_object, OBJPROP_CHART_ID);
   if(subchart_id > 0)
     {
      ChartSetInteger(subchart_id, CHART_SHOW_PRICE_SCALE, true);
      ChartSetInteger(subchart_id, CHART_FOREGROUND, false);
      ChartSetInteger(subchart_id, CHART_SHOW_OHLC, false);
      ChartSetInteger(subchart_id, CHART_SHOW_TRADE_LEVELS, false);
      ChartSetInteger(subchart_id, CHART_SHOW_BID_LINE, false);
      ChartSetInteger(subchart_id, CHART_SHOW_ASK_LINE, false);
      ChartRedraw(subchart_id);
     }

   return(true);
}

void ResizeBuyChartObject()
{
   int win = ChartWindowFind(0, g_subwindow_shortname);
   if(win < 0)
      return;
   if(ObjectFind(0, g_buy_chart_object) < 0)
      return;

   int width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, win);
   int height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, win);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_XDISTANCE, 0);
   ObjectSetInteger(0, g_buy_chart_object, OBJPROP_YDISTANCE, 0);
}

bool ValidateSymbol(const string sym, string &err)
{
   if(sym == "")
     {
      err = "Simbolo vazio.";
      return(false);
     }
   if(!SymbolSelect(sym, true))
     {
      err = "Simbolo nao encontrado: " + sym;
      return(false);
     }
   return(true);
}

bool ValidateVolume(const string sym, const double volume, string &err)
{
   if(volume <= 0.0)
     {
      err = "Quantidade invalida.";
      return(false);
     }
   if(InpLotMultiple > 0)
     {
      int vol_int = (int)MathRound(volume);
      if(vol_int % InpLotMultiple != 0)
        {
         err = "Quantidade deve ser multiplo de " + IntegerToString(InpLotMultiple) + ".";
         return(false);
        }
     }
   double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(volume < vmin || volume > vmax)
     {
      err = "Quantidade fora dos limites do ativo.";
      return(false);
     }
   if(vstep > 0.0)
     {
      double steps = volume / vstep;
      if(MathAbs(steps - MathRound(steps)) > 1e-6)
        {
         err = "Quantidade fora do passo do ativo.";
         return(false);
        }
     }
   return(true);
}



bool IsDemoAccount()
{
   return(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO);
}
bool CheckLiquidity(const string sym, const double volume, const bool is_buy, string &err)
{
   if(!MarketBookAdd(sym))
     {
      if(IsDemoAccount())
         return(true);
      err = "Book indisponivel: " + sym;
      return(false);
     }
   MqlBookInfo book[];
   if(!MarketBookGet(sym, book) || ArraySize(book) == 0)
     {
      if(IsDemoAccount())
         return(true);
      err = "Sem book para: " + sym;
      return(false);
     }
   double available = 0.0;
   for(int i = 0; i < ArraySize(book); i++)
     {
      if(is_buy && book[i].type == BOOK_TYPE_SELL)
         available += (double)book[i].volume;
      else if(!is_buy && book[i].type == BOOK_TYPE_BUY)
         available += (double)book[i].volume;
     }
   if(available < volume)
     {
      err = "Liquidez insuficiente: " + sym;
      return(false);
     }
   return(true);
}

bool IsOrderCheckAccepted(const MqlTradeCheckResult &check)
{
   if(check.retcode == TRADE_RETCODE_DONE ||
      check.retcode == TRADE_RETCODE_PLACED ||
      check.retcode == TRADE_RETCODE_DONE_PARTIAL)
      return(true);

   string comment = check.comment;
   StringTrimLeft(comment);
   StringTrimRight(comment);
   if(check.retcode == 0 && StringCompare(comment, "Done") == 0)
      return(true);

   return(false);
}


bool CheckOrder(const string sym, const double volume, const bool is_buy, string &err)
{
   MqlTradeRequest req;
   MqlTradeCheckResult check;
   ZeroMemory(req);
   ZeroMemory(check);

   double price = is_buy ? SymbolInfoDouble(sym, SYMBOL_ASK) : SymbolInfoDouble(sym, SYMBOL_BID);
   if(price <= 0.0)
     {
      err = "Preco indisponivel: " + sym;
      return(false);
     }

   req.action = TRADE_ACTION_DEAL;
   req.symbol = sym;
   req.volume = volume;
   req.type = is_buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   req.price = price;
   req.deviation = InpDeviationPoints;
   req.type_filling = ORDER_FILLING_FOK;
   req.type_time = ORDER_TIME_GTC;
   req.magic = InpMagic;
   req.comment = InpComment;

   if(!OrderCheck(req, check))
     {
      err = "OrderCheck falhou: " + sym;
      return(false);
     }
   if(!IsOrderCheckAccepted(check))
     {
      err = "OrderCheck rejeitado (" + IntegerToString((int)check.retcode) + "): " + check.comment;
      return(false);
     }
   return(true);
}

bool SendMarketOrder(const string sym, const double volume, const bool is_buy, ulong &ticket, string &err)
{
   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpDeviationPoints);
   g_trade.SetTypeFilling(ORDER_FILLING_FOK);

   bool ok = is_buy ? g_trade.Buy(volume, sym, 0.0, 0.0, 0.0, InpComment)
                    : g_trade.Sell(volume, sym, 0.0, 0.0, 0.0, InpComment);
   if(!ok)
     {
      err = g_trade.ResultRetcodeDescription();
      return(false);
     }
   ticket = g_trade.ResultOrder();
   return(true);
}

void SetPriceLine(const long chart_id, const string name, const int window, const double price, const color clr, const string label)
{
   if(price <= 0.0)
     {
      ObjectDelete(chart_id, name);
      return;
     }
   if(ObjectFind(chart_id, name) < 0)
      ObjectCreate(chart_id, name, OBJ_HLINE, window, 0, price);
   ObjectSetDouble(chart_id, name, OBJPROP_PRICE, price);
   ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(chart_id, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(chart_id, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(chart_id, name, OBJPROP_TEXT, label);
}

string FormatSignedValue(const double value, const int digits)
{
   string sign = value >= 0.0 ? "+" : "-";
   return(sign + DoubleToString(MathAbs(value), digits));
}

string BuildBadgeText(const string prefix, const double price, const double delta, const double pct, const int digits, const bool show_delta)
{
   string text = prefix + " " + DoubleToString(price, digits);
   if(show_delta)
      text += " | " + FormatSignedValue(delta, digits) + " (" + FormatSignedValue(pct, 2) + "%)";
   return(text);
}

void UpdatePriceBadge(const long chart_id,
                      const int window,
                      const double price,
                      const string text,
                      const color bg,
                      const color fg,
                      const string rect_name,
                      const string label_name)
{
   if(price <= 0.0 || text == "")
     {
      ObjectDelete(chart_id, rect_name);
      ObjectDelete(chart_id, label_name);
      return;
     }

   datetime t = iTime(_Symbol, _Period, 0);
   int x = 0;
   int y = 0;
   if(!ChartTimePriceToXY(chart_id, window, t, price, x, y))
     {
      ObjectDelete(chart_id, rect_name);
      ObjectDelete(chart_id, label_name);
      return;
     }

   const int badge_w = 220;
   const int badge_h = 18;
   const int pad = 6;
   int chart_w = (int)ChartGetInteger(chart_id, CHART_WIDTH_IN_PIXELS, window);
   int chart_h = (int)ChartGetInteger(chart_id, CHART_HEIGHT_IN_PIXELS, window);
   int box_x = chart_w - badge_w - pad;
   int box_y = y - (badge_h / 2);
   if(box_x < 0)
      box_x = 0;
   if(box_y < 0)
      box_y = 0;
   if(box_y + badge_h > chart_h)
      box_y = chart_h - badge_h;

   if(ObjectFind(chart_id, rect_name) < 0)
      ObjectCreate(chart_id, rect_name, OBJ_RECTANGLE_LABEL, window, 0, 0);
   ObjectSetInteger(chart_id, rect_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chart_id, rect_name, OBJPROP_XDISTANCE, box_x);
   ObjectSetInteger(chart_id, rect_name, OBJPROP_YDISTANCE, box_y);
   ObjectSetInteger(chart_id, rect_name, OBJPROP_XSIZE, badge_w);
   ObjectSetInteger(chart_id, rect_name, OBJPROP_YSIZE, badge_h);
   ObjectSetInteger(chart_id, rect_name, OBJPROP_COLOR, bg);
   ObjectSetInteger(chart_id, rect_name, OBJPROP_BACK, false);
   ObjectSetInteger(chart_id, rect_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chart_id, rect_name, OBJPROP_BGCOLOR, bg);

   if(ObjectFind(chart_id, label_name) < 0)
      ObjectCreate(chart_id, label_name, OBJ_LABEL, window, 0, 0);
   ObjectSetInteger(chart_id, label_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(chart_id, label_name, OBJPROP_XDISTANCE, box_x + 6);
   ObjectSetInteger(chart_id, label_name, OBJPROP_YDISTANCE, box_y + 2);
   ObjectSetInteger(chart_id, label_name, OBJPROP_COLOR, fg);
   ObjectSetInteger(chart_id, label_name, OBJPROP_FONTSIZE, 8);
   ObjectSetString(chart_id, label_name, OBJPROP_TEXT, text);
   ObjectSetInteger(chart_id, label_name, OBJPROP_SELECTABLE, false);
}

void RemovePriceLines()
{
   ObjectDelete(0, g_sell_entry_line);
   ObjectDelete(0, g_sell_current_line);
   ObjectDelete(0, g_sell_entry_badge);
   ObjectDelete(0, g_sell_entry_badge_text);
   ObjectDelete(0, g_sell_current_badge);
   ObjectDelete(0, g_sell_current_badge_text);
   ObjectDelete(0, g_buy_entry_line);
   ObjectDelete(0, g_buy_current_line);
   ObjectDelete(0, g_buy_entry_badge);
   ObjectDelete(0, g_buy_entry_badge_text);
   ObjectDelete(0, g_buy_current_badge);
   ObjectDelete(0, g_buy_current_badge_text);
   long buy_chart_id = 0;
   if(ObjectFind(0, g_buy_chart_object) >= 0)
      buy_chart_id = ObjectGetInteger(0, g_buy_chart_object, OBJPROP_CHART_ID);
   if(buy_chart_id > 0)
     {
      ObjectDelete(buy_chart_id, g_buy_entry_line);
      ObjectDelete(buy_chart_id, g_buy_current_line);
      ObjectDelete(buy_chart_id, g_buy_entry_badge);
      ObjectDelete(buy_chart_id, g_buy_entry_badge_text);
      ObjectDelete(buy_chart_id, g_buy_current_badge);
      ObjectDelete(buy_chart_id, g_buy_current_badge_text);
     }
}

void UpdatePriceLines()
{
   string sell_sym = NormalizeSymbol(g_sell_input.Text());
   if(sell_sym != "")
     {
      SymbolSelect(sell_sym, true);
      double sell_current = SymbolInfoDouble(sell_sym, SYMBOL_BID);
      int sell_digits = (int)SymbolInfoInteger(sell_sym, SYMBOL_DIGITS);
      bool has_sell_entry = (g_sell_entry_price > 0.0);
      double sell_delta = has_sell_entry ? (sell_current - g_sell_entry_price) : 0.0;
      double sell_pct = has_sell_entry ? (sell_delta / g_sell_entry_price * 100.0) : 0.0;
      color sell_badge_bg = has_sell_entry ? (sell_delta >= 0.0 ? clrGreen : clrRed) : clrSilver;
      SetPriceLine(0, g_sell_current_line, 0, sell_current, clrSilver, "Atual");
      SetPriceLine(0, g_sell_entry_line, 0, g_sell_entry_price, clrRed, "Entrada");
      UpdatePriceBadge(0, 0, sell_current,
                       BuildBadgeText("Atual", sell_current, sell_delta, sell_pct, sell_digits, has_sell_entry),
                       sell_badge_bg, clrWhite, g_sell_current_badge, g_sell_current_badge_text);
      UpdatePriceBadge(0, 0, g_sell_entry_price,
                       has_sell_entry ? BuildBadgeText("Entrada", g_sell_entry_price, sell_delta, sell_pct, sell_digits, true) : "",
                       sell_badge_bg, clrWhite, g_sell_entry_badge, g_sell_entry_badge_text);
     }
   else
     {
      ObjectDelete(0, g_sell_current_line);
      ObjectDelete(0, g_sell_entry_line);
      ObjectDelete(0, g_sell_entry_badge);
      ObjectDelete(0, g_sell_entry_badge_text);
      ObjectDelete(0, g_sell_current_badge);
      ObjectDelete(0, g_sell_current_badge_text);
     }

   int buy_win = ChartWindowFind(0, g_subwindow_shortname);
   long buy_chart_id = 0;
   if(ObjectFind(0, g_buy_chart_object) >= 0)
      buy_chart_id = ObjectGetInteger(0, g_buy_chart_object, OBJPROP_CHART_ID);
   string buy_sym = NormalizeSymbol(g_buy_input.Text());
   if(buy_sym != "" && buy_chart_id > 0)
     {
      SymbolSelect(buy_sym, true);
      double buy_current = SymbolInfoDouble(buy_sym, SYMBOL_ASK);
      int buy_digits = (int)SymbolInfoInteger(buy_sym, SYMBOL_DIGITS);
      bool has_buy_entry = (g_buy_entry_price > 0.0);
      double buy_delta = has_buy_entry ? (buy_current - g_buy_entry_price) : 0.0;
      double buy_pct = has_buy_entry ? (buy_delta / g_buy_entry_price * 100.0) : 0.0;
      color buy_badge_bg = has_buy_entry ? (buy_delta >= 0.0 ? clrGreen : clrRed) : clrSilver;
      SetPriceLine(buy_chart_id, g_buy_current_line, 0, buy_current, clrSilver, "Atual");
      SetPriceLine(buy_chart_id, g_buy_entry_line, 0, g_buy_entry_price, clrGreen, "Entrada");
      UpdatePriceBadge(buy_chart_id, 0, buy_current,
                       BuildBadgeText("Atual", buy_current, buy_delta, buy_pct, buy_digits, has_buy_entry),
                       buy_badge_bg, clrWhite, g_buy_current_badge, g_buy_current_badge_text);
      UpdatePriceBadge(buy_chart_id, 0, g_buy_entry_price,
                       has_buy_entry ? BuildBadgeText("Entrada", g_buy_entry_price, buy_delta, buy_pct, buy_digits, true) : "",
                       buy_badge_bg, clrWhite, g_buy_entry_badge, g_buy_entry_badge_text);
     }
   else
     {
      ObjectDelete(0, g_buy_current_line);
      ObjectDelete(0, g_buy_entry_line);
      ObjectDelete(0, g_buy_entry_badge);
      ObjectDelete(0, g_buy_entry_badge_text);
      ObjectDelete(0, g_buy_current_badge);
      ObjectDelete(0, g_buy_current_badge_text);
      if(buy_chart_id > 0)
        {
         ObjectDelete(buy_chart_id, g_buy_current_line);
         ObjectDelete(buy_chart_id, g_buy_entry_line);
         ObjectDelete(buy_chart_id, g_buy_entry_badge);
         ObjectDelete(buy_chart_id, g_buy_entry_badge_text);
         ObjectDelete(buy_chart_id, g_buy_current_badge);
         ObjectDelete(buy_chart_id, g_buy_current_badge_text);
        }
     }
}

void SubmitOrders()
{
   string sell_sym = NormalizeSymbol(g_sell_input.Text());
   string buy_sym = NormalizeSymbol(g_buy_input.Text());

   double sell_qty = 0.0;
   double buy_qty = 0.0;
   if(!TryParseDouble(g_sell_qty_input.Text(), sell_qty) || !TryParseDouble(g_buy_qty_input.Text(), buy_qty))
     {
      Print("Quantidade invalida.");
      return;
     }

   string err;
   if(!ValidateSymbol(sell_sym, err) || !ValidateSymbol(buy_sym, err))
     {
      Print(err);
      return;
     }
   bool is_demo = IsDemoAccount();
   if(!is_demo)
     {
      if(!ValidateVolume(sell_sym, sell_qty, err) || !ValidateVolume(buy_sym, buy_qty, err))
        {
         Print(err);
         return;
        }
      if(!CheckLiquidity(sell_sym, sell_qty, false, err) || !CheckLiquidity(buy_sym, buy_qty, true, err))
        {
         Print(err);
         return;
        }
      if(!CheckOrder(sell_sym, sell_qty, false, err) || !CheckOrder(buy_sym, buy_qty, true, err))
        {
         Print(err);
         return;
        }
     }

   g_sell_ticket = 0;
   g_buy_ticket = 0;
   if(!SendMarketOrder(sell_sym, sell_qty, false, g_sell_ticket, err))
     {
      Print("Falha venda: " + err);
      return;
     }
   g_sell_entry_price = g_trade.ResultPrice();
   if(!SendMarketOrder(buy_sym, buy_qty, true, g_buy_ticket, err))
     {
      Print("Falha compra: " + err);
      return;
     }
   g_buy_entry_price = g_trade.ResultPrice();
   UpdatePriceLines();
}

void UpdateTotal(CLabel &price_label, CEdit &qty_field, CLabel &total_out)
{
   double price = 0.0;
   double qty = 0.0;
   if(!TryParseDouble(price_label.Text(), price) || !TryParseDouble(qty_field.Text(), qty))
     {
      total_out.Text("--");
      UpdateSummary();
      return;
     }
   total_out.Text(FormatMoney(price * qty, 2));
   UpdateSummary();
}

void UpdateSummary()
{
   double sell_qty = 0.0;
   double buy_qty = 0.0;
   double sell_total = 0.0;
   double buy_total = 0.0;
   bool has_sell = TryParseDouble(g_sell_qty_input.Text(), sell_qty);
   bool has_buy = TryParseDouble(g_buy_qty_input.Text(), buy_qty);
   bool has_sell_total = TryParseDouble(g_sell_total_value.Text(), sell_total);
   bool has_buy_total = TryParseDouble(g_buy_total_value.Text(), buy_total);

   string sell_sym = NormalizeSymbol(g_sell_input.Text());
   if(sell_sym == "")
      sell_sym = "--";

   string buy_sym = NormalizeSymbol(g_buy_input.Text());
   if(buy_sym == "")
      buy_sym = "--";

   if(has_sell)
      g_summary_line1.Text("Vendeu " + sell_sym + ": " + DoubleToString(sell_qty, 0));
   else
      g_summary_line1.Text("Vendeu " + sell_sym + ": --");

   if(has_buy)
      g_summary_line2.Text("Comprou " + buy_sym + ": " + DoubleToString(buy_qty, 0));
   else
      g_summary_line2.Text("Comprou " + buy_sym + ": --");

   if(has_sell_total && has_buy_total)
     {
      double net = sell_total - buy_total;
      if(net >= 0.0)
        {
         g_summary_line3.Text("Recebe: " + FormatMoney(net, 2));
         g_summary_line3.Color(clrBlue);
        }
      else
        {
         g_summary_line3.Text("Paga: " + FormatMoney(MathAbs(net), 2));
         g_summary_line3.Color(clrRed);
        }
     }
   else
     {
      g_summary_line3.Text("Recebe/Paga: --");
      g_summary_line3.Color(clrGray);
     }
}

void UpdateQtyByDelta(CEdit &qty_field, const double delta)
{
   double qty = 0.0;
   if(!TryParseDouble(qty_field.Text(), qty))
      qty = 0.0;
   qty += delta;
   if(qty < 0.0)
      qty = 0.0;
   qty_field.Text(DoubleToString(qty, 0));
}

bool InitBoleta(const int card_w, const int card_h, const int panel_x, const int panel_y, const int chart_w, const int chart_h)
{
   const int ui_x = 0;
   const int ui_y = 0;
   if(!g_card.Create(0, "boleta_card", 0, ui_x, ui_y, ui_x + card_w, ui_y + card_h))
      return(false);
   g_card.ColorBackground(clrWhite);
   g_card.ColorBorder(clrSilver);
   g_app.Add(g_card);
   const int left = ui_x + 16;
   const int right = ui_x + card_w - 16;
   int y = ui_y + 16;

   if(!g_title.Create(0, "boleta_title", 0, left, y, right, y + 22))
      return(false);
   g_title.Text("Boleta Long/Short");
   g_title.FontSize(12);
   g_title.ColorBackground(clrWhite);
   g_title.ColorBorder(clrWhite);
   g_app.Add(g_title);

   y += 22;
   if(!g_subtitle.Create(0, "boleta_subtitle", 0, left, y, right, y + 18))
      return(false);
   g_subtitle.Text("Ativo vendido, ativo comprado e quantidade");
   g_subtitle.Color(clrGray);
   g_subtitle.ColorBackground(clrWhite);
   g_subtitle.ColorBorder(clrWhite);
   g_app.Add(g_subtitle);

   y += 28;
   const int label_w = 140;
   const int input_h = 22;

   const int card_gap = 12;
   const int asset_card_w = (card_w - 32 - card_gap) / 2;
   const int asset_card_h = 200;
   const int sell_card_x1 = left;
   const int sell_card_x2 = left + asset_card_w;
   const int buy_card_x1 = sell_card_x2 + card_gap;
   const int buy_card_x2 = buy_card_x1 + asset_card_w;

   if(!g_sell_card.Create(0, "sell_card", 0, sell_card_x1, y, sell_card_x2, y + asset_card_h))
      return(false);
   g_sell_card.ColorBackground(clrWhite);
   g_sell_card.ColorBorder(clrSilver);
   g_app.Add(g_sell_card);

   if(!g_buy_card.Create(0, "buy_card", 0, buy_card_x1, y, buy_card_x2, y + asset_card_h))
      return(false);
   g_buy_card.ColorBackground(clrWhite);
   g_buy_card.ColorBorder(clrSilver);
   g_app.Add(g_buy_card);

   if(!g_sell_card_title.Create(0, "sell_card_title", 0, sell_card_x1 + 10, y + 8, sell_card_x2 - 10, y + 26))
      return(false);
   g_sell_card_title.Text("Vender");
   g_sell_card_title.Color(clrRed);
   g_sell_card_title.ColorBackground(clrWhite);
   g_sell_card_title.ColorBorder(clrWhite);
   g_app.Add(g_sell_card_title);

   if(!g_buy_card_title.Create(0, "buy_card_title", 0, buy_card_x1 + 10, y + 8, buy_card_x2 - 10, y + 26))
      return(false);
   g_buy_card_title.Text("Comprar");
   g_buy_card_title.Color(clrGreen);
   g_buy_card_title.ColorBackground(clrWhite);
   g_buy_card_title.ColorBorder(clrWhite);
   g_app.Add(g_buy_card_title);

   if(!g_sell_label.Create(0, "sell_label", 0, sell_card_x1 + 10, y + 30, sell_card_x1 + label_w, y + 30 + input_h))
      return(false);
   g_sell_label.Text("Ativo");
   g_sell_label.ColorBackground(clrWhite);
   g_sell_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_label);

   if(!g_sell_input.Create(0, "sell_input", 0, sell_card_x1 + 10, y + 52, sell_card_x2 - 10, y + 52 + input_h))
      return(false);
   g_sell_input.Text("");
   g_app.Add(g_sell_input);

   const int btn_w = 18;
   const int btn_h = 10;
   const int btn_gap = 2;
   const int qty_input_w = asset_card_w - 10 - 10 - btn_w;

   if(!g_sell_qty_label.Create(0, "sell_qty_label", 0, sell_card_x1 + 10, y + 78, sell_card_x1 + label_w, y + 78 + input_h))
      return(false);
   g_sell_qty_label.Text("Quantidade");
   g_sell_qty_label.ColorBackground(clrWhite);
   g_sell_qty_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_qty_label);

   if(!g_sell_qty_input.Create(0, "sell_qty_input", 0, sell_card_x1 + 10, y + 100, sell_card_x1 + 10 + qty_input_w, y + 100 + input_h))
      return(false);
   g_sell_qty_input.Text("");
   g_app.Add(g_sell_qty_input);

   if(!g_sell_qty_up.Create(0, "sell_qty_up", 0, sell_card_x1 + 10 + qty_input_w + 2, y + 100, sell_card_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h))
      return(false);
   g_sell_qty_up.Text("^");
   g_app.Add(g_sell_qty_up);

   if(!g_sell_qty_down.Create(0, "sell_qty_down", 0, sell_card_x1 + 10 + qty_input_w + 2, y + 100 + btn_h + btn_gap, sell_card_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h + btn_gap + btn_h))
      return(false);
   g_sell_qty_down.Text("v");
   g_app.Add(g_sell_qty_down);

   if(!g_sell_price_label.Create(0, "sell_price_label", 0, sell_card_x1 + 10, y + 120, sell_card_x1 + label_w, y + 120 + input_h))
      return(false);
   g_sell_price_label.Text("Preco");
   g_sell_price_label.ColorBackground(clrWhite);
   g_sell_price_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_price_label);

   if(!g_sell_price_value.Create(0, "sell_price_value", 0, sell_card_x1 + 10, y + 142, sell_card_x2 - 10, y + 142 + input_h))
      return(false);
   g_sell_price_value.Text("--");
   g_sell_price_value.ColorBackground(clrWhite);
   g_sell_price_value.ColorBorder(clrWhite);
   g_app.Add(g_sell_price_value);

   if(!g_buy_label.Create(0, "buy_label", 0, buy_card_x1 + 10, y + 30, buy_card_x1 + label_w, y + 30 + input_h))
      return(false);
   g_buy_label.Text("Ativo");
   g_buy_label.ColorBackground(clrWhite);
   g_buy_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_label);

   if(!g_buy_input.Create(0, "buy_input", 0, buy_card_x1 + 10, y + 52, buy_card_x2 - 10, y + 52 + input_h))
      return(false);
   g_buy_input.Text("");
   g_app.Add(g_buy_input);

   if(!g_buy_qty_label.Create(0, "buy_qty_label", 0, buy_card_x1 + 10, y + 78, buy_card_x1 + label_w, y + 78 + input_h))
      return(false);
   g_buy_qty_label.Text("Quantidade");
   g_buy_qty_label.ColorBackground(clrWhite);
   g_buy_qty_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_qty_label);

   if(!g_buy_qty_input.Create(0, "buy_qty_input", 0, buy_card_x1 + 10, y + 100, buy_card_x1 + 10 + qty_input_w, y + 100 + input_h))
      return(false);
   g_buy_qty_input.Text("");
   g_app.Add(g_buy_qty_input);

   if(!g_buy_qty_up.Create(0, "buy_qty_up", 0, buy_card_x1 + 10 + qty_input_w + 2, y + 100, buy_card_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h))
      return(false);
   g_buy_qty_up.Text("^");
   g_app.Add(g_buy_qty_up);

   if(!g_buy_qty_down.Create(0, "buy_qty_down", 0, buy_card_x1 + 10 + qty_input_w + 2, y + 100 + btn_h + btn_gap, buy_card_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h + btn_gap + btn_h))
      return(false);
   g_buy_qty_down.Text("v");
   g_app.Add(g_buy_qty_down);

   if(!g_buy_price_label.Create(0, "buy_price_label", 0, buy_card_x1 + 10, y + 120, buy_card_x1 + label_w, y + 120 + input_h))
      return(false);
   g_buy_price_label.Text("Preco");
   g_buy_price_label.ColorBackground(clrWhite);
   g_buy_price_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_price_label);

   if(!g_buy_price_value.Create(0, "buy_price_value", 0, buy_card_x1 + 10, y + 142, buy_card_x2 - 10, y + 142 + input_h))
      return(false);
   g_buy_price_value.Text("--");
   g_buy_price_value.ColorBackground(clrWhite);
   g_buy_price_value.ColorBorder(clrWhite);
   g_app.Add(g_buy_price_value);

   const int total_row_y = y + 156;
   if(!g_sell_total_label.Create(0, "sell_total_label", 0, sell_card_x1 + 10, total_row_y, sell_card_x1 + label_w, total_row_y + input_h))
      return(false);
   g_sell_total_label.Text("Total venda");
   g_sell_total_label.ColorBackground(clrWhite);
   g_sell_total_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_total_label);

   if(!g_sell_total_value.Create(0, "sell_total_value", 0, sell_card_x1 + 10, total_row_y + input_h, sell_card_x2 - 10, total_row_y + input_h + input_h))
      return(false);
   g_sell_total_value.Text("--");
   g_sell_total_value.ColorBackground(clrWhite);
   g_sell_total_value.ColorBorder(clrWhite);
   g_app.Add(g_sell_total_value);

   if(!g_buy_total_label.Create(0, "buy_total_label", 0, buy_card_x1 + 10, total_row_y, buy_card_x1 + label_w, total_row_y + input_h))
      return(false);
   g_buy_total_label.Text("Total compra");
   g_buy_total_label.ColorBackground(clrWhite);
   g_buy_total_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_total_label);

   if(!g_buy_total_value.Create(0, "buy_total_value", 0, buy_card_x1 + 10, total_row_y + input_h, buy_card_x2 - 10, total_row_y + input_h + input_h))
      return(false);
   g_buy_total_value.Text("--");
   g_buy_total_value.ColorBackground(clrWhite);
   g_buy_total_value.ColorBorder(clrWhite);
   g_app.Add(g_buy_total_value);

   y += asset_card_h + 8;
   const int summary_h = 84;
   const int summary_text_right = right - 10;
   if(!g_summary_card.Create(0, "summary_card", 0, left, y, right, y + summary_h))
      return(false);
   g_summary_card.ColorBackground(clrWhite);
   g_summary_card.ColorBorder(clrSilver);
   g_app.Add(g_summary_card);

   if(!g_summary_title.Create(0, "summary_title", 0, left + 10, y + 6, summary_text_right, y + 24))
      return(false);
   g_summary_title.Text("Resumo Long/Short");
   g_summary_title.ColorBackground(clrWhite);
   g_summary_title.ColorBorder(clrWhite);
   g_app.Add(g_summary_title);

   if(!g_summary_line1.Create(0, "summary_line1", 0, left + 10, y + 26, summary_text_right, y + 44))
      return(false);
   g_summary_line1.Text("Vendeu: --");
   g_summary_line1.ColorBackground(clrWhite);
   g_summary_line1.ColorBorder(clrWhite);
   g_app.Add(g_summary_line1);

   if(!g_summary_line2.Create(0, "summary_line2", 0, left + 10, y + 44, summary_text_right, y + 62))
      return(false);
   g_summary_line2.Text("Comprou: --");
   g_summary_line2.ColorBackground(clrWhite);
   g_summary_line2.ColorBorder(clrWhite);
   g_app.Add(g_summary_line2);

   if(!g_summary_line3.Create(0, "summary_line3", 0, left + 10, y + 62, summary_text_right, y + 80))
      return(false);
   g_summary_line3.Text("Recebe/Paga: --");
   g_summary_line3.Color(clrGray);
   g_summary_line3.ColorBackground(clrWhite);
   g_summary_line3.ColorBorder(clrWhite);
   g_app.Add(g_summary_line3);

   y += summary_h + 14;
   const int btn_action_w = 120;
   if(!g_show_charts_btn.Create(0, "btn_charts", 0, left, y, left + btn_action_w, y + 26))
      return(false);
   g_show_charts_btn.Text("Ver grafico compra");
   g_app.Add(g_show_charts_btn);

   if(!g_submit_btn.Create(0, "btn_submit", 0, right - (btn_action_w * 2 + 8), y, right - btn_action_w - 8, y + 26))
      return(false);
   g_submit_btn.Text("Enviar");
   g_app.Add(g_submit_btn);

   if(!g_clear_btn.Create(0, "btn_clear", 0, right - btn_action_w, y, right, y + 26))
      return(false);
   g_clear_btn.Text("Limpar");
   g_app.Add(g_clear_btn);
   return(true);
}

int OnInit()
{
   const int w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   const int h = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   const int pad = 20;
   int card_w = MathMin(460, w - (pad * 2));
   if(card_w < 320)
      card_w = 320;
   int card_h = h - (pad * 2) + InpPanelExtraHeight;
   int max_h = h - pad;
   if(card_h > max_h)
      card_h = max_h;
   int card_x = pad;
   int card_y = pad;

   ChartSetInteger(0, CHART_SCALEFIX, false);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
   if(!g_app.Create(0, "Painel", 0, card_x, card_y, card_x + card_w, card_y + card_h))
      return(INIT_FAILED);
   if(!InitBoleta(card_w, card_h, card_x, card_y, w, h))
      return(INIT_FAILED);

   g_app.Run();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   RemoveBuyChartObject();
   RemoveBuySubwindow();
   RemovePriceLines();
   g_app.Destroy(reason);
}

void OnTick()
{
   UpdatePriceLines();
}

void OnChartEvent(const int id, const long& l, const double& d, const string& s)
{
   g_app.ChartEvent(id, l, d, s);
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      if(g_buy_chart_visible)
        {
         if(ChartWindowFind(0, g_subwindow_shortname) < 0)
           {
            g_buy_chart_visible = false;
            g_show_charts_btn.Text("Ver grafico compra");
           }
         else
           {
            ResizeBuyChartObject();
           }
        }
      UpdatePriceLines();
      g_app.BringToTop();
     }
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(s == "sell_input")
        {
         if(UpdateSymbolPrice(g_sell_input, g_sell_price_value, false))
           {
            string sell_sym = NormalizeSymbol(g_sell_input.Text());
            if(sell_sym != "")
               ChartSetSymbolPeriod(0, sell_sym, (ENUM_TIMEFRAMES)Period());
            UpdateTotal(g_sell_price_value, g_sell_qty_input, g_sell_total_value);
           }
         UpdateSummary();
         UpdatePriceLines();
        }
      else if(s == "buy_input")
        {
         if(UpdateSymbolPrice(g_buy_input, g_buy_price_value, true))
            UpdateTotal(g_buy_price_value, g_buy_qty_input, g_buy_total_value);
         UpdateSummary();
         if(g_buy_chart_visible)
            CreateBuyChartObject(g_buy_input.Text());
         UpdatePriceLines();
        }
      else if(s == "sell_qty_input")
         UpdateTotal(g_sell_price_value, g_sell_qty_input, g_sell_total_value);
      else if(s == "buy_qty_input")
         UpdateTotal(g_buy_price_value, g_buy_qty_input, g_buy_total_value);
      return;
     }

   if(id != CHARTEVENT_OBJECT_CLICK)
      return;
   if(s == "btn_clear")
     {
      g_sell_input.Text("");
      g_buy_input.Text("");
      g_sell_qty_input.Text("");
      g_buy_qty_input.Text("");
      g_sell_price_value.Text("--");
      g_buy_price_value.Text("--");
      g_sell_total_value.Text("--");
      g_buy_total_value.Text("--");
      g_sell_entry_price = 0.0;
      g_buy_entry_price = 0.0;
      g_buy_chart_visible = false;
      RemoveBuyChartObject();
      RemoveBuySubwindow();
      RemovePriceLines();
      g_show_charts_btn.Text("Ver grafico compra");
      UpdateSummary();
     }
   else if(s == "btn_charts")
     {
      if(!g_buy_chart_visible)
        {
         if(CreateBuyChartObject(g_buy_input.Text()))
           {
            g_buy_chart_visible = true;
            g_show_charts_btn.Text("Ocultar grafico");
            g_app.BringToTop();
            UpdatePriceLines();
           }
         else
           {
            g_buy_chart_visible = false;
            g_show_charts_btn.Text("Ver grafico compra");
           }
        }
      else
        {
         g_buy_chart_visible = false;
         RemoveBuyChartObject();
         RemoveBuySubwindow();
         g_show_charts_btn.Text("Ver grafico compra");
        }
     }
   else if(s == "sell_qty_up")
     {
      UpdateQtyByDelta(g_sell_qty_input, 100.0);
      UpdateTotal(g_sell_price_value, g_sell_qty_input, g_sell_total_value);
     }
   else if(s == "sell_qty_down")
     {
      UpdateQtyByDelta(g_sell_qty_input, -100.0);
      UpdateTotal(g_sell_price_value, g_sell_qty_input, g_sell_total_value);
     }
   else if(s == "buy_qty_up")
     {
      UpdateQtyByDelta(g_buy_qty_input, 100.0);
      UpdateTotal(g_buy_price_value, g_buy_qty_input, g_buy_total_value);
     }
   else if(s == "buy_qty_down")
     {
      UpdateQtyByDelta(g_buy_qty_input, -100.0);
      UpdateTotal(g_buy_price_value, g_buy_qty_input, g_buy_total_value);
     }
   else if(s == "btn_submit")
     {
      SubmitOrders();
     }
}








