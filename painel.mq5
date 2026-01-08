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

CButton g_submit_btn;
CButton g_clear_btn;

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

bool CheckLiquidity(const string sym, const double volume, const bool is_buy, string &err)
{
   if(!MarketBookAdd(sym))
     {
      err = "Book indisponivel: " + sym;
      return(false);
     }
   MqlBookInfo book[];
   if(!MarketBookGet(sym, book) || ArraySize(book) == 0)
     {
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
   if(check.retcode != TRADE_RETCODE_DONE && check.retcode != TRADE_RETCODE_PLACED)
     {
      err = "OrderCheck rejeitado: " + check.comment;
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

   g_sell_ticket = 0;
   g_buy_ticket = 0;
   if(!SendMarketOrder(sell_sym, sell_qty, false, g_sell_ticket, err))
     {
      Print("Falha venda: " + err);
      return;
     }
   if(!SendMarketOrder(buy_sym, buy_qty, true, g_buy_ticket, err))
     {
      Print("Falha compra: " + err);
      return;
     }
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

bool InitBoleta(const int w, const int h)
{
   const int pad = 20;
   const int card_w = MathMin(w - (pad * 2), 520);
   const int card_h = 440;
   int card_x = (w - card_w) / 2;
   int card_y = (h - card_h) / 2;
   if(card_x < pad)
      card_x = pad;
   if(card_y < pad)
      card_y = pad;

   if(!g_card.Create(0, "boleta_card", 0, card_x, card_y, card_x + card_w, card_y + card_h))
      return(false);
   g_card.ColorBackground(clrWhite);
   g_card.ColorBorder(clrSilver);
   g_app.Add(g_card);

   const int left = card_x + 16;
   const int right = card_x + card_w - 16;
   int y = card_y + 16;

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
   const int asset_card_h = 180;
   const int sell_x1 = left;
   const int sell_x2 = left + asset_card_w;
   const int buy_x1 = sell_x2 + card_gap;
   const int buy_x2 = buy_x1 + asset_card_w;

   if(!g_sell_card.Create(0, "sell_card", 0, sell_x1, y, sell_x2, y + asset_card_h))
      return(false);
   g_sell_card.ColorBackground(clrWhite);
   g_sell_card.ColorBorder(clrSilver);
   g_app.Add(g_sell_card);

   if(!g_buy_card.Create(0, "buy_card", 0, buy_x1, y, buy_x2, y + asset_card_h))
      return(false);
   g_buy_card.ColorBackground(clrWhite);
   g_buy_card.ColorBorder(clrSilver);
   g_app.Add(g_buy_card);

   if(!g_sell_card_title.Create(0, "sell_card_title", 0, sell_x1 + 10, y + 8, sell_x2 - 10, y + 26))
      return(false);
   g_sell_card_title.Text("Vender");
   g_sell_card_title.Color(clrRed);
   g_sell_card_title.ColorBackground(clrWhite);
   g_sell_card_title.ColorBorder(clrWhite);
   g_app.Add(g_sell_card_title);

   if(!g_buy_card_title.Create(0, "buy_card_title", 0, buy_x1 + 10, y + 8, buy_x2 - 10, y + 26))
      return(false);
   g_buy_card_title.Text("Comprar");
   g_buy_card_title.Color(clrGreen);
   g_buy_card_title.ColorBackground(clrWhite);
   g_buy_card_title.ColorBorder(clrWhite);
   g_app.Add(g_buy_card_title);

   if(!g_sell_label.Create(0, "sell_label", 0, sell_x1 + 10, y + 30, sell_x1 + label_w, y + 30 + input_h))
      return(false);
   g_sell_label.Text("Ativo");
   g_sell_label.ColorBackground(clrWhite);
   g_sell_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_label);

   if(!g_sell_input.Create(0, "sell_input", 0, sell_x1 + 10, y + 52, sell_x2 - 10, y + 52 + input_h))
      return(false);
   g_sell_input.Text("");
   g_app.Add(g_sell_input);

   const int btn_w = 18;
   const int btn_h = 10;
   const int btn_gap = 2;
   const int qty_input_w = asset_card_w - 10 - 10 - btn_w;

   if(!g_sell_qty_label.Create(0, "sell_qty_label", 0, sell_x1 + 10, y + 78, sell_x1 + label_w, y + 78 + input_h))
      return(false);
   g_sell_qty_label.Text("Quantidade");
   g_sell_qty_label.ColorBackground(clrWhite);
   g_sell_qty_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_qty_label);

   if(!g_sell_qty_input.Create(0, "sell_qty_input", 0, sell_x1 + 10, y + 100, sell_x1 + 10 + qty_input_w, y + 100 + input_h))
      return(false);
   g_sell_qty_input.Text("");
   g_app.Add(g_sell_qty_input);

   if(!g_sell_qty_up.Create(0, "sell_qty_up", 0, sell_x1 + 10 + qty_input_w + 2, y + 100, sell_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h))
      return(false);
   g_sell_qty_up.Text("^");
   g_app.Add(g_sell_qty_up);

   if(!g_sell_qty_down.Create(0, "sell_qty_down", 0, sell_x1 + 10 + qty_input_w + 2, y + 100 + btn_h + btn_gap, sell_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h + btn_gap + btn_h))
      return(false);
   g_sell_qty_down.Text("v");
   g_app.Add(g_sell_qty_down);

   if(!g_sell_price_label.Create(0, "sell_price_label", 0, sell_x1 + 10, y + 126, sell_x1 + label_w, y + 126 + input_h))
      return(false);
   g_sell_price_label.Text("Preco");
   g_sell_price_label.ColorBackground(clrWhite);
   g_sell_price_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_price_label);

   if(!g_sell_price_value.Create(0, "sell_price_value", 0, sell_x1 + 70, y + 126, sell_x2 - 10, y + 126 + input_h))
      return(false);
   g_sell_price_value.Text("--");
   g_sell_price_value.ColorBackground(clrWhite);
   g_sell_price_value.ColorBorder(clrWhite);
   g_app.Add(g_sell_price_value);

   if(!g_buy_label.Create(0, "buy_label", 0, buy_x1 + 10, y + 30, buy_x1 + label_w, y + 30 + input_h))
      return(false);
   g_buy_label.Text("Ativo");
   g_buy_label.ColorBackground(clrWhite);
   g_buy_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_label);

   if(!g_buy_input.Create(0, "buy_input", 0, buy_x1 + 10, y + 52, buy_x2 - 10, y + 52 + input_h))
      return(false);
   g_buy_input.Text("");
   g_app.Add(g_buy_input);

   if(!g_buy_qty_label.Create(0, "buy_qty_label", 0, buy_x1 + 10, y + 78, buy_x1 + label_w, y + 78 + input_h))
      return(false);
   g_buy_qty_label.Text("Quantidade");
   g_buy_qty_label.ColorBackground(clrWhite);
   g_buy_qty_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_qty_label);

   if(!g_buy_qty_input.Create(0, "buy_qty_input", 0, buy_x1 + 10, y + 100, buy_x1 + 10 + qty_input_w, y + 100 + input_h))
      return(false);
   g_buy_qty_input.Text("");
   g_app.Add(g_buy_qty_input);

   if(!g_buy_qty_up.Create(0, "buy_qty_up", 0, buy_x1 + 10 + qty_input_w + 2, y + 100, buy_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h))
      return(false);
   g_buy_qty_up.Text("^");
   g_app.Add(g_buy_qty_up);

   if(!g_buy_qty_down.Create(0, "buy_qty_down", 0, buy_x1 + 10 + qty_input_w + 2, y + 100 + btn_h + btn_gap, buy_x1 + 10 + qty_input_w + 2 + btn_w, y + 100 + btn_h + btn_gap + btn_h))
      return(false);
   g_buy_qty_down.Text("v");
   g_app.Add(g_buy_qty_down);

   if(!g_buy_price_label.Create(0, "buy_price_label", 0, buy_x1 + 10, y + 126, buy_x1 + label_w, y + 126 + input_h))
      return(false);
   g_buy_price_label.Text("Preco");
   g_buy_price_label.ColorBackground(clrWhite);
   g_buy_price_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_price_label);

   if(!g_buy_price_value.Create(0, "buy_price_value", 0, buy_x1 + 70, y + 126, buy_x2 - 10, y + 126 + input_h))
      return(false);
   g_buy_price_value.Text("--");
   g_buy_price_value.ColorBackground(clrWhite);
   g_buy_price_value.ColorBorder(clrWhite);
   g_app.Add(g_buy_price_value);

   const int total_row_y = y + 150;
   if(!g_sell_total_label.Create(0, "sell_total_label", 0, sell_x1 + 10, total_row_y, sell_x1 + label_w, total_row_y + input_h))
      return(false);
   g_sell_total_label.Text("Total venda");
   g_sell_total_label.ColorBackground(clrWhite);
   g_sell_total_label.ColorBorder(clrWhite);
   g_app.Add(g_sell_total_label);

   if(!g_sell_total_value.Create(0, "sell_total_value", 0, sell_x1 + 100, total_row_y, sell_x2 - 10, total_row_y + input_h))
      return(false);
   g_sell_total_value.Text("--");
   g_sell_total_value.ColorBackground(clrWhite);
   g_sell_total_value.ColorBorder(clrWhite);
   g_app.Add(g_sell_total_value);

   if(!g_buy_total_label.Create(0, "buy_total_label", 0, buy_x1 + 10, total_row_y, buy_x1 + label_w, total_row_y + input_h))
      return(false);
   g_buy_total_label.Text("Total compra");
   g_buy_total_label.ColorBackground(clrWhite);
   g_buy_total_label.ColorBorder(clrWhite);
   g_app.Add(g_buy_total_label);

   if(!g_buy_total_value.Create(0, "buy_total_value", 0, buy_x1 + 100, total_row_y, buy_x2 - 10, total_row_y + input_h))
      return(false);
   g_buy_total_value.Text("--");
   g_buy_total_value.ColorBackground(clrWhite);
   g_buy_total_value.ColorBorder(clrWhite);
   g_app.Add(g_buy_total_value);

   y += asset_card_h + 8;
   const int summary_h = 84;
   if(!g_summary_card.Create(0, "summary_card", 0, left, y, right, y + summary_h))
      return(false);
   g_summary_card.ColorBackground(clrWhite);
   g_summary_card.ColorBorder(clrSilver);
   g_app.Add(g_summary_card);

   if(!g_summary_title.Create(0, "summary_title", 0, left + 10, y + 6, right - 10, y + 24))
      return(false);
   g_summary_title.Text("Resumo Long/Short");
   g_summary_title.ColorBackground(clrWhite);
   g_summary_title.ColorBorder(clrWhite);
   g_app.Add(g_summary_title);

   if(!g_summary_line1.Create(0, "summary_line1", 0, left + 10, y + 26, right - 10, y + 44))
      return(false);
   g_summary_line1.Text("Vendeu: --");
   g_summary_line1.ColorBackground(clrWhite);
   g_summary_line1.ColorBorder(clrWhite);
   g_app.Add(g_summary_line1);

   if(!g_summary_line2.Create(0, "summary_line2", 0, left + 10, y + 44, right - 10, y + 62))
      return(false);
   g_summary_line2.Text("Comprou: --");
   g_summary_line2.ColorBackground(clrWhite);
   g_summary_line2.ColorBorder(clrWhite);
   g_app.Add(g_summary_line2);

   if(!g_summary_line3.Create(0, "summary_line3", 0, left + 10, y + 62, right - 10, y + 80))
      return(false);
   g_summary_line3.Text("Recebe/Paga: --");
   g_summary_line3.Color(clrGray);
   g_summary_line3.ColorBackground(clrWhite);
   g_summary_line3.ColorBorder(clrWhite);
   g_app.Add(g_summary_line3);

   y += summary_h + 14;
   const int btn_action_w = 120;
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

   ChartSetInteger(0, CHART_SCALEFIX, false);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, false);

   if(!g_app.Create(0, "Painel", 0, 0, 0, w, h))
      return(INIT_FAILED);
   if(!InitBoleta(w, h))
      return(INIT_FAILED);

   g_app.Run();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   g_app.Destroy(reason);
}

void OnChartEvent(const int id, const long& l, const double& d, const string& s)
{
   g_app.ChartEvent(id, l, d, s);
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(s == "sell_input")
        {
         if(UpdateSymbolPrice(g_sell_input, g_sell_price_value, false))
            UpdateTotal(g_sell_price_value, g_sell_qty_input, g_sell_total_value);
         UpdateSummary();
        }
      else if(s == "buy_input")
        {
         if(UpdateSymbolPrice(g_buy_input, g_buy_price_value, true))
            UpdateTotal(g_buy_price_value, g_buy_qty_input, g_buy_total_value);
         UpdateSummary();
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
      UpdateSummary();
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




